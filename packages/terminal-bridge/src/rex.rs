//! Rex launching is separate from the Alacritty/tmux pane-transfer backend.

use super::*;
use std::ffi::OsStr;

fn command(cli: &Path, args: &[&OsStr]) -> Command {
    let mut command = Command::new(cli);
    command.args(["--timeout", "1s"]).args(args);
    // A launcher should use the local server, not an inherited agent context.
    for key in ["REX_SERVER", "REX_CLIENT", "REX_SESSION", "REX_BLOCK"] {
        command.env_remove(key);
    }
    command
}

pub(super) fn launch(cwd: &Path) -> Result<()> {
    if !cfg!(target_os = "macos") {
        return Err("Rex launching requires the macOS desktop client".to_owned());
    }
    let home = env::var_os("HOME").ok_or("HOME is not set")?;
    let cli = PathBuf::from(home).join(
        "Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex",
    );
    if !cli.is_file() {
        return Err(format!("Rex CLI not found at {}", cli.display()));
    }
    output("/usr/bin/open", &["-b", "com.superlogical.rex"])?;
    launch_session(
        cwd,
        |args| {
            let result = command(&cli, args)
                .output()
                .map_err(|e| format!("Rex: {e}"))?;
            if !result.status.success() {
                return Err(String::from_utf8_lossy(&result.stderr).trim().to_owned());
            }
            String::from_utf8(result.stdout).map_err(|e| format!("Rex: {e}"))
        },
        || thread::sleep(Duration::from_millis(200)),
    )
}

fn wait_for_app(
    call: &mut impl FnMut(&[&OsStr]) -> Result<String>,
    wait: &mut impl FnMut(),
) -> Result<()> {
    // Read-only readiness checks: retrying New Window could create duplicates
    // if a request succeeds but its response is lost.
    for attempt in 0..50 {
        let clients = call(&["client".as_ref(), "ls".as_ref(), "--json".as_ref()])?;
        let clients: Value =
            serde_json::from_str(&clients).map_err(|e| format!("Rex client response: {e}"))?;
        let apps = clients["clients"]
            .as_array()
            .ok_or("Rex response has no clients list")?
            .iter()
            .filter(|c| c["info"]["kind"] == "app" && c["connection_state"] == "connected")
            .count();
        match apps {
            1 => return Ok(()),
            0 if attempt < 49 => wait(),
            0 => return Err("Rex app did not connect".to_owned()),
            _ => {
                return Err(
                    "multiple Rex app clients connected; refusing to choose a window".to_owned(),
                );
            }
        }
    }
    unreachable!()
}

fn launch_session(
    cwd: &Path,
    mut call: impl FnMut(&[&OsStr]) -> Result<String>,
    mut wait: impl FnMut(),
) -> Result<()> {
    wait_for_app(&mut call, &mut wait)?;
    let created = call(&[
        "new".as_ref(),
        "-c".as_ref(),
        cwd.as_os_str(),
        "--json".as_ref(),
    ])?;
    let created: Value =
        serde_json::from_str(&created).map_err(|e| format!("Rex response: {e}"))?;
    let session = created["session_id"]
        .as_str()
        .filter(|id| !id.is_empty())
        .ok_or("Rex response has no session_id")?;
    call(&["do".as_ref(), "client.window.new".as_ref()]).map_err(|error| {
        format!("could not open a new window for Rex session {session}: {error}")
    })?;
    let argument = format!("session_id={session}");
    // The new app window is now active. Selection is idempotent, so retry it
    // while the new window becomes ready; never retry creating sessions/windows.
    for attempt in 0..50 {
        match call(&["do".as_ref(), "session.select".as_ref(), argument.as_ref()]) {
            Ok(_) => return Ok(()),
            Err(error) if attempt == 49 => {
                return Err(format!("could not display Rex session {session}: {error}"));
            }
            Err(_) => wait(),
        }
    }
    unreachable!()
}

#[cfg(test)]
mod tests {
    use super::*;

    const READY: &str = r#"{"clients":[{"info":{"kind":"app"},"connection_state":"connected"}]}"#;

    #[test]
    fn command_clears_inherited_context_and_bounds_calls() {
        let command = command(Path::new("/rex"), &["new".as_ref()]);
        assert_eq!(
            command.get_args().collect::<Vec<_>>(),
            ["--timeout", "1s", "new"]
        );
        for key in ["REX_SERVER", "REX_CLIENT", "REX_SESSION", "REX_BLOCK"] {
            assert!(command.get_envs().any(|(k, v)| k == key && v.is_none()));
        }
    }

    #[test]
    fn launch_retries_selection_without_creating_duplicate_sessions_or_windows() {
        let mut calls = Vec::new();
        let mut waits = 0;
        let mut windows = 0;
        launch_session(
            Path::new("/directory with spaces"),
            |args| {
                let args: Vec<_> = args
                    .iter()
                    .map(|v| v.to_string_lossy().into_owned())
                    .collect();
                if args[0] == "client" {
                    return Ok(READY.to_owned());
                }
                if args == ["do", "client.window.new"] {
                    assert_eq!(
                        calls.len(),
                        1,
                        "create the window after the session, before selecting it"
                    );
                    windows += 1;
                    return Ok(String::new());
                }
                calls.push(args.clone());
                if args[0] == "new" {
                    assert_eq!(args, ["new", "-c", "/directory with spaces", "--json"]);
                    Ok(r#"{"session_id":"session:test"}"#.to_owned())
                } else {
                    assert_eq!(args, ["do", "session.select", "session_id=session:test"]);
                    if calls.len() < 4 {
                        Err("app starting".to_owned())
                    } else {
                        Ok(String::new())
                    }
                }
            },
            || waits += 1,
        )
        .unwrap();
        assert_eq!(waits, 2);
        assert_eq!(calls.len(), 4);
        assert_eq!(windows, 1);
    }

    #[test]
    fn persistent_selection_failure_reports_recoverable_session() {
        let mut creations = 0;
        let mut selections = 0;
        let mut waits = 0;
        let error = launch_session(
            Path::new("/home"),
            |args| {
                if args[0] == "client" {
                    return Ok(READY.to_owned());
                }
                if args[1] == "client.window.new" {
                    return Ok(String::new());
                }
                if args[0] == "new" {
                    creations += 1;
                    Ok(r#"{"session_id":"session:recover"}"#.to_owned())
                } else {
                    selections += 1;
                    Err("ambiguous client or Remote Control disabled".to_owned())
                }
            },
            || waits += 1,
        )
        .unwrap_err();
        assert_eq!((creations, selections, waits), (1, 50, 49));
        assert!(error.contains("session:recover"));
        assert!(error.contains("Remote Control disabled"));
    }

    #[test]
    fn cold_app_readiness_is_checked_before_creating_anything() {
        let mut queries = 0;
        let mut waits = 0;
        wait_for_app(
            &mut |args| {
                assert_eq!(args, ["client", "ls", "--json"]);
                queries += 1;
                Ok(if queries < 3 {
                    r#"{"clients":[]}"#
                } else {
                    READY
                }
                .to_owned())
            },
            &mut || waits += 1,
        )
        .unwrap();
        assert_eq!((queries, waits), (3, 2));
    }

    #[test]
    fn ambiguous_or_missing_app_never_creates_sessions_or_windows() {
        let mut queries = 0;
        let error = launch_session(Path::new("/home"), |args| {
            assert_eq!(args, ["client", "ls", "--json"]);
            queries += 1;
            Ok(r#"{"clients":[{"info":{"kind":"app"},"connection_state":"connected"},{"info":{"kind":"app"},"connection_state":"connected"}]}"#.to_owned())
        }, || panic!("ambiguity must fail immediately")).unwrap_err();
        assert_eq!(queries, 1);
        assert!(error.contains("multiple Rex app clients"));

        queries = 0;
        let error = launch_session(
            Path::new("/home"),
            |args| {
                assert_eq!(args, ["client", "ls", "--json"]);
                queries += 1;
                Ok(r#"{"clients":[]}"#.to_owned())
            },
            || {},
        )
        .unwrap_err();
        assert_eq!(queries, 50);
        assert!(error.contains("did not connect"));
    }

    #[test]
    fn failed_window_creation_is_never_retried() {
        let mut windows = 0;
        let error = launch_session(
            Path::new("/home"),
            |args| {
                if args[0] == "client" {
                    return Ok(READY.to_owned());
                }
                if args[0] == "new" {
                    return Ok(r#"{"session_id":"session:recover"}"#.to_owned());
                }
                assert_eq!(args, ["do", "client.window.new"]);
                windows += 1;
                Err("request timed out".to_owned())
            },
            || panic!("must not retry window creation"),
        )
        .unwrap_err();
        assert_eq!(windows, 1);
        assert!(error.contains("session:recover"));
        assert!(error.contains("timed out"));
    }

    #[test]
    fn invalid_creation_responses_never_attempt_selection() {
        for response in ["not json", "{}", r#"{"session_id":""}"#] {
            let mut calls = 0;
            assert!(
                launch_session(
                    Path::new("/home"),
                    |args| {
                        if args[0] == "client" {
                            return Ok(READY.to_owned());
                        }
                        calls += 1;
                        Ok(response.to_owned())
                    },
                    || panic!("must not wait")
                )
                .is_err()
            );
            assert_eq!(calls, 1);
        }
        assert_eq!(
            launch_session(
                Path::new("/home"),
                |args| if args[0] == "client" {
                    Ok(READY.to_owned())
                } else {
                    Err("creation failed".to_owned())
                },
                || panic!("must not wait")
            )
            .unwrap_err(),
            "creation failed"
        );
    }
}
