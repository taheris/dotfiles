use anyhow::{Context, Result, bail, ensure};
use base64::{Engine, engine::general_purpose::STANDARD};
use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use std::{
    net::{Ipv4Addr, SocketAddr, TcpStream},
    time::Duration,
};
use tungstenite::{Message, WebSocket};

pub trait Api {
    fn request(&mut self, kind: &str, data: Value) -> Result<Value>;
}

pub struct Client {
    socket: WebSocket<TcpStream>,
    sequence: u64,
}

pub fn connect_or_launch(
    port: u16,
    password: Option<&str>,
) -> Result<(Client, Option<crate::platform::BrowserFocus>)> {
    let mut focus = None;
    let client = connect_with_launch(
        || Client::connect(port, password),
        || {
            focus = crate::platform::remember_browser()?;
            crate::platform::launch_obs()
        },
        Duration::from_secs(20),
        Duration::from_millis(200),
    )?;
    Ok((client, focus))
}

fn connection_refused(error: &anyhow::Error) -> bool {
    error
        .downcast_ref::<std::io::Error>()
        .is_some_and(|error| error.kind() == std::io::ErrorKind::ConnectionRefused)
}

fn connect_with_launch<T>(
    mut connect: impl FnMut() -> Result<T>,
    launch: impl FnOnce() -> Result<()>,
    timeout: Duration,
    interval: Duration,
) -> Result<T> {
    match connect() {
        Ok(client) => return Ok(client),
        Err(error) if connection_refused(&error) => (),
        // Authentication/protocol failures must not repeatedly launch OBS or
        // retry a bad password. Only absence of a listener triggers startup.
        Err(error) => return Err(error),
    }
    eprintln!("obs-video-crop: opening OBS; waiting for its WebSocket server");
    launch()?;
    let deadline = std::time::Instant::now() + timeout;
    loop {
        std::thread::sleep(interval);
        match connect() {
            Ok(client) => return Ok(client),
            Err(error) if connection_refused(&error) => {
                if std::time::Instant::now() >= deadline {
                    return Err(error).context("OBS did not become reachable after launch; finish any first-run dialogs and enable Tools > WebSocket Server Settings");
                }
            }
            Err(error) => return Err(error),
        }
    }
}

fn authentication(password: &str, salt: &str, challenge: &str) -> String {
    let secret = STANDARD.encode(Sha256::digest(format!("{password}{salt}")));
    STANDARD.encode(Sha256::digest(format!("{secret}{challenge}")))
}

impl Client {
    pub fn connect(port: u16, password: Option<&str>) -> Result<Self> {
        // Never send OBS credentials to a remote host.
        let address = SocketAddr::from((Ipv4Addr::LOCALHOST, port));
        let stream = TcpStream::connect_timeout(&address, Duration::from_secs(3))
            .context("cannot connect to OBS; enable Tools > WebSocket Server Settings")?;
        stream.set_read_timeout(Some(Duration::from_secs(5)))?;
        stream.set_write_timeout(Some(Duration::from_secs(5)))?;
        let (socket, _) = tungstenite::client(format!("ws://{address}"), stream)
            .context("OBS WebSocket handshake failed")?;
        let mut client = Self {
            socket,
            sequence: 0,
        };
        let hello = client.receive()?;
        ensure!(hello["op"] == 0, "expected OBS Hello");
        ensure!(
            hello["d"]["rpcVersion"].as_u64().unwrap_or(0) >= 1,
            "OBS WebSocket v5 is required"
        );
        let mut identify = json!({ "rpcVersion": 1, "eventSubscriptions": 0 });
        if let Some(auth) = hello["d"].get("authentication") {
            let password = password.context(
                "OBS requires a password; configure password_file or save OBS's WebSocket settings",
            )?;
            let salt = auth["salt"].as_str().context("missing OBS salt")?;
            let challenge = auth["challenge"]
                .as_str()
                .context("missing OBS challenge")?;
            identify["authentication"] = authentication(password, salt, challenge).into();
        }
        client.send(json!({ "op": 1, "d": identify }))?;
        ensure!(
            client.receive().context("OBS authentication failed")?["op"] == 2,
            "OBS authentication was not accepted"
        );
        Ok(client)
    }

    fn send(&mut self, data: Value) -> Result<()> {
        self.socket.send(Message::Text(data.to_string().into()))?;
        Ok(())
    }

    fn receive(&mut self) -> Result<Value> {
        // eventSubscriptions=0; bound control-frame processing as well as socket IO.
        for _ in 0..100 {
            match self.socket.read()? {
                Message::Text(text) => {
                    return serde_json::from_str(text.as_str()).context("invalid OBS response");
                }
                Message::Ping(_) => self.socket.flush()?,
                Message::Pong(_) => (),
                Message::Close(_) => bail!("OBS closed the connection (check WebSocket password)"),
                _ => bail!("unexpected OBS WebSocket message"),
            }
        }
        bail!("too many OBS control frames")
    }
}

impl Api for Client {
    fn request(&mut self, kind: &str, data: Value) -> Result<Value> {
        // Finalizing/muxing a recording can take longer than a normal RPC.
        self.socket
            .get_mut()
            .set_read_timeout(Some(Duration::from_secs(if kind == "StopRecord" {
                120
            } else {
                5
            })))?;
        self.sequence += 1;
        let id = self.sequence.to_string();
        self.send(json!({
            "op": 6, "d": { "requestType": kind, "requestId": id, "requestData": data }
        }))?;
        let response = self.receive()?;
        ensure!(
            response["op"] == 7 && response["d"]["requestId"] == id,
            "unexpected OBS response to {kind}"
        );
        let data = &response["d"];
        ensure!(
            data["requestStatus"]["result"] == true,
            "OBS {kind} failed ({}): {}",
            data["requestStatus"]["code"],
            data["requestStatus"]["comment"]
                .as_str()
                .unwrap_or("no details")
        );
        Ok(data
            .get("responseData")
            .cloned()
            .unwrap_or_else(|| json!({})))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::{net::TcpListener, thread};

    #[test]
    fn authenticated_round_trip_and_request_failure() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let port = listener.local_addr().unwrap().port();
        let server = thread::spawn(move || {
            let (stream, _) = listener.accept().unwrap();
            stream
                .set_read_timeout(Some(Duration::from_secs(3)))
                .unwrap();
            let mut socket = tungstenite::accept(stream).unwrap();
            socket
                .send(Message::Text(
                    json!({
                        "op": 0, "d": { "rpcVersion": 1,
                            "authentication": { "salt": "salt", "challenge": "challenge" } }
                    })
                    .to_string()
                    .into(),
                ))
                .unwrap();
            let identify: Value =
                serde_json::from_str(socket.read().unwrap().to_text().unwrap()).unwrap();
            assert_eq!(
                identify["d"]["authentication"],
                authentication("secret", "salt", "challenge")
            );
            assert_eq!(identify["d"]["eventSubscriptions"], 0);
            socket
                .send(Message::Text(
                    json!({"op":2,"d":{"negotiatedRpcVersion":1}})
                        .to_string()
                        .into(),
                ))
                .unwrap();
            for success in [true, false] {
                let request: Value =
                    serde_json::from_str(socket.read().unwrap().to_text().unwrap()).unwrap();
                assert_eq!(request["d"]["requestType"], "GetVersion");
                socket.send(Message::Text(json!({
                    "op": 7, "d": {
                        "requestId": request["d"]["requestId"],
                        "requestStatus": { "result": success, "code": if success {100} else {600}, "comment": "test" },
                        "responseData": { "obsVersion": "test" }
                    }
                }).to_string().into())).unwrap();
            }
        });
        let mut client = Client::connect(port, Some("secret")).unwrap();
        assert_eq!(
            client.request("GetVersion", json!({})).unwrap()["obsVersion"],
            "test"
        );
        assert!(
            client
                .request("GetVersion", json!({}))
                .unwrap_err()
                .to_string()
                .contains("600")
        );
        server.join().unwrap();
    }

    fn refused() -> anyhow::Error {
        anyhow::Error::new(std::io::Error::from(std::io::ErrorKind::ConnectionRefused))
            .context("cannot connect")
    }

    #[test]
    fn running_server_is_used_without_launch() {
        let result = connect_with_launch(
            || Ok(42),
            || panic!("must not launch"),
            Duration::ZERO,
            Duration::ZERO,
        )
        .unwrap();
        assert_eq!(result, 42);
    }

    #[test]
    fn refused_connection_launches_once_and_waits_for_server() {
        use std::cell::Cell;
        let calls = Cell::new(0);
        let launches = Cell::new(0);
        let result = connect_with_launch(
            || {
                calls.set(calls.get() + 1);
                if calls.get() < 3 {
                    Err(refused())
                } else {
                    Ok(42)
                }
            },
            || {
                launches.set(launches.get() + 1);
                Ok(())
            },
            Duration::from_secs(1),
            Duration::ZERO,
        )
        .unwrap();
        assert_eq!(result, 42);
        assert_eq!(launches.get(), 1);
        assert_eq!(calls.get(), 3);
    }

    #[test]
    fn authentication_failure_never_launches() {
        let result = connect_with_launch::<()>(
            || anyhow::bail!("bad password"),
            || panic!("must not launch for authentication failure"),
            Duration::ZERO,
            Duration::ZERO,
        );
        assert!(result.unwrap_err().to_string().contains("bad password"));
    }

    #[test]
    fn server_startup_timeout_explains_websocket_setup() {
        let result =
            connect_with_launch::<()>(|| Err(refused()), || Ok(()), Duration::ZERO, Duration::ZERO);
        assert!(
            result
                .unwrap_err()
                .to_string()
                .contains("WebSocket Server Settings")
        );
    }

    #[test]
    fn launch_failures_do_not_enter_retry_loop() {
        let result = connect_with_launch::<()>(
            || Err(refused()),
            || anyhow::bail!("OBS not installed"),
            Duration::ZERO,
            Duration::ZERO,
        );
        assert_eq!(result.unwrap_err().to_string(), "OBS not installed");
    }

    #[test]
    fn authentication_error_after_startup_is_not_retried() {
        let mut first = true;
        let result = connect_with_launch::<()>(
            || {
                if first {
                    first = false;
                    Err(refused())
                } else {
                    anyhow::bail!("bad password after launch")
                }
            },
            || Ok(()),
            Duration::from_secs(1),
            Duration::ZERO,
        );
        assert_eq!(result.unwrap_err().to_string(), "bad password after launch");
    }

    #[test]
    fn authentication_matches_independent_vector() {
        // SHA256/base64 calculated independently with Python hashlib.
        assert_eq!(
            authentication("secret", "salt", "challenge"),
            "39cfhx7et2iyoMZvoQ6o3OPLNSKgtMmy48GQ7jnvsdE="
        );
    }
}
