use serde_json::{Value, json};
use std::{
    fs,
    net::TcpListener,
    path::PathBuf,
    process::Command,
    thread,
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tungstenite::Message;

struct TempHome(PathBuf);
impl TempHome {
    fn new() -> Self {
        let unique = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let path = std::env::temp_dir().join(format!(
            "obs-video-crop-cli-{}-{unique}",
            std::process::id()
        ));
        fs::create_dir_all(path.join("config/obs-video-crop")).unwrap();
        Self(path)
    }
}
impl Drop for TempHome {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

#[test]
fn stopping_from_cli_does_not_read_a_missing_target_or_probe_the_browser() {
    let home = TempHome::new();
    let listener = TcpListener::bind("127.0.0.1:0").unwrap();
    let port = listener.local_addr().unwrap().port();
    fs::write(
        home.0.join("config/obs-video-crop/config.json"),
        json!({ "port": port }).to_string(),
    )
    .unwrap();

    let server = thread::spawn(move || {
        let (stream, _) = listener.accept().unwrap();
        stream
            .set_read_timeout(Some(Duration::from_secs(5)))
            .unwrap();
        let mut socket = tungstenite::accept(stream).unwrap();
        socket
            .send(Message::Text(
                json!({
                    "op": 0, "d": { "rpcVersion": 1 }
                })
                .to_string()
                .into(),
            ))
            .unwrap();
        let identify: Value =
            serde_json::from_str(socket.read().unwrap().to_text().unwrap()).unwrap();
        assert_eq!(identify["op"], 1);
        socket
            .send(Message::Text(
                json!({
                    "op": 2, "d": { "negotiatedRpcVersion": 1 }
                })
                .to_string()
                .into(),
            ))
            .unwrap();
        for (kind, data) in [
            ("GetRecordStatus", json!({ "outputActive": true })),
            (
                "StopRecord",
                json!({ "outputPath": "/Users/test/Movies/saved.mkv" }),
            ),
            // Real OBS acknowledges StopRecord before the output is inactive.
            // No source cleanup may run until the later confirmation.
            ("GetRecordStatus", json!({ "outputActive": true })),
            ("GetRecordStatus", json!({ "outputActive": false })),
            (
                "GetSceneList",
                json!({ "scenes": [{ "sceneName": "Video Capture" }] }),
            ),
            (
                "GetSceneItemList",
                json!({ "sceneItems": [{ "sourceName": "Browser Video", "sceneItemId": 1 }] }),
            ),
            (
                "GetInputList",
                json!({ "inputs": [{ "inputName": "Browser Video", "inputKind": "screen_capture" }] }),
            ),
            ("GetOutputList", json!({ "outputs": [] })),
            ("RemoveInput", json!({})),
        ] {
            let request: Value =
                serde_json::from_str(socket.read().unwrap().to_text().unwrap()).unwrap();
            assert_eq!(request["d"]["requestType"], kind);
            if kind == "RemoveInput" {
                assert_eq!(request["d"]["requestData"]["inputName"], "Browser Video");
            }
            socket
                .send(Message::Text(
                    json!({
                        "op": 7, "d": {
                            "requestId": request["d"]["requestId"],
                            "requestStatus": { "result": true, "code": 100 },
                            "responseData": data
                        }
                    })
                    .to_string()
                    .into(),
                ))
                .unwrap();
        }
    });

    let output = Command::new(env!("CARGO_BIN_EXE_obs-video-crop"))
        .args(["--target", "/definitely-missing/target.json"])
        .env("HOME", &home.0)
        .env("XDG_CONFIG_HOME", home.0.join("config"))
        .output()
        .unwrap();
    server.join().unwrap();
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        String::from_utf8_lossy(&output.stdout)
            .contains("Recording saved: /Users/test/Movies/saved.mkv")
    );
    assert!(String::from_utf8_lossy(&output.stdout).contains("Screen capture stopped."));
}

#[test]
fn starting_from_cli_unmutes_an_existing_macos_capture_before_recording() {
    let home = TempHome::new();
    let listener = TcpListener::bind("127.0.0.1:0").unwrap();
    let port = listener.local_addr().unwrap().port();
    fs::write(
        home.0.join("config/obs-video-crop/config.json"),
        json!({ "port": port }).to_string(),
    )
    .unwrap();
    let target = home.0.join("target.json");
    fs::write(
        &target,
        json!({
            "window": { "x": 0, "y": 0, "width": 1000, "height": 800 },
            "viewport": { "x": 0, "y": 100, "width": 1000, "height": 700 },
            "video": { "x": 100, "y": 50, "width": 600, "height": 400 },
            "inner_width": 1000, "inner_height": 700,
            "capture": { "input_kind": "screen_capture", "settings": { "type": 1, "window": 42 } }
        })
        .to_string(),
    )
    .unwrap();

    let server = thread::spawn(move || {
        let (stream, _) = listener.accept().unwrap();
        stream
            .set_read_timeout(Some(Duration::from_secs(5)))
            .unwrap();
        let mut socket = tungstenite::accept(stream).unwrap();
        socket
            .send(Message::Text(
                json!({ "op": 0, "d": { "rpcVersion": 1 } })
                    .to_string()
                    .into(),
            ))
            .unwrap();
        let identify: Value =
            serde_json::from_str(socket.read().unwrap().to_text().unwrap()).unwrap();
        assert_eq!(identify["op"], 1);
        socket
            .send(Message::Text(
                json!({ "op": 2, "d": { "negotiatedRpcVersion": 1 } })
                    .to_string()
                    .into(),
            ))
            .unwrap();
        let mut cropped = false;
        let mut unmuted = false;
        let mut active = false;
        for _ in 0..30 {
            let request: Value =
                serde_json::from_str(socket.read().unwrap().to_text().unwrap()).unwrap();
            let kind = request["d"]["requestType"].as_str().unwrap();
            let data = &request["d"]["requestData"];
            let response = match kind {
                "GetRecordStatus" => json!({ "outputActive": active }),
                "GetSceneList" => json!({ "scenes": [{ "sceneName": "Video Capture" }] }),
                "GetSceneItemList" => {
                    json!({ "sceneItems": [{ "sourceName": "Browser Video", "sceneItemId": 1 }] })
                }
                "GetInputList" => {
                    json!({ "inputs": [{ "inputName": "Browser Video", "inputKind": "screen_capture" }] })
                }
                "GetSceneItemTransform" => {
                    json!({ "sceneItemTransform": { "sourceWidth": 1000, "sourceHeight": 800 } })
                }
                "GetVideoSettings" => json!({ "baseWidth": 1920, "baseHeight": 1080 }),
                "SetSceneItemTransform" => {
                    cropped = true;
                    json!({})
                }
                "SetInputMute" => {
                    assert!(cropped);
                    assert_eq!(data["inputName"], "Browser Video");
                    assert_eq!(data["inputMuted"], false);
                    unmuted = true;
                    json!({})
                }
                "StartRecord" => {
                    assert!(
                        cropped && unmuted,
                        "capture must be cropped and audible before StartRecord"
                    );
                    active = true;
                    json!({})
                }
                "SetInputSettings" | "SetSceneItemEnabled" | "SetCurrentProgramScene" => json!({}),
                _ => panic!("unexpected request: {kind}"),
            };
            socket.send(Message::Text(json!({
                "op": 7, "d": {
                    "requestId": request["d"]["requestId"],
                    "requestStatus": { "result": true, "code": 100 }, "responseData": response
                }
            }).to_string().into())).unwrap();
            if active && kind == "GetRecordStatus" {
                return;
            }
        }
        panic!("recording startup was not confirmed");
    });
    let output = Command::new(env!("CARGO_BIN_EXE_obs-video-crop"))
        .arg("--target")
        .arg(&target)
        .env("HOME", &home.0)
        .env("XDG_CONFIG_HOME", home.0.join("config"))
        .output()
        .unwrap();
    server.join().unwrap();
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(String::from_utf8_lossy(&output.stdout).contains("Recording started: video"));
}
