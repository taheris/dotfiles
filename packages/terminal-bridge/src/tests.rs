use super::*;
use serde_json::json;
use std::cell::{Cell, RefCell};
use std::collections::VecDeque;
use std::io::Read;
use std::os::fd::{AsRawFd, FromRawFd};
use std::rc::Rc;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};

fn window(id: &str, pid: u32, column: u64, focused: bool) -> Window {
    Window {
        id: id.to_owned(),
        pid: Some(pid),
        app: "Alacritty".to_owned(),
        workspace: Some("1".to_owned()),
        column: Some(column),
        focused,
        fullscreen: false,
    }
}

#[derive(Default)]
struct FakeWm {
    items: RefCell<Vec<Window>>,
    snapshots: RefCell<VecDeque<Vec<Window>>>,
    focused: RefCell<Vec<String>>,
    fallbacks: RefCell<Vec<String>>,
    fail_focus: Cell<bool>,
    fail_query: Cell<bool>,
}

impl WindowManager for FakeWm {
    fn windows(&self) -> Result<Vec<Window>> {
        if self.fail_query.get() {
            return Err("query failed".to_owned());
        }
        Ok(self
            .snapshots
            .borrow_mut()
            .pop_front()
            .unwrap_or_else(|| self.items.borrow().clone()))
    }
    fn focus(&self, w: &Window) -> Result<()> {
        if self.fail_focus.get() {
            return Err("focus failed".to_owned());
        }
        self.focused.borrow_mut().push(w.id.clone());
        Ok(())
    }
    fn fallback(&self, action: &str) -> Result<()> {
        self.fallbacks.borrow_mut().push(action.to_owned());
        Ok(())
    }
}

#[test]
fn default_server_is_ordinary_tmux() {
    assert_eq!(Tmux::default().socket, "default");
}

#[test]
fn launcher_uses_plain_tmux_without_session_registration() {
    let command = launch_command();
    let args: Vec<_> = command.get_args().collect();
    assert_eq!(args.len(), 4);
    assert_eq!(args[0], "--working-directory");
    assert_eq!(args[2], "-e");
    assert_eq!(args[3], "tmux");
    assert!(
        command
            .get_envs()
            .any(|(key, value)| key == "TMUX" && value.is_none())
    );
}

#[test]
fn slurp_matches_next_column_without_skipping_apps() {
    let left = window("left", 100, 1, true);
    let right = window("right", 200, 2, false);
    assert_eq!(
        slurp_pair(&[left.clone(), right.clone()]),
        Some((&left, &right))
    );
    let mut browser = right.clone();
    browser.app = "firefox".to_owned();
    let far = window("far", 300, 3, false);
    assert!(slurp_pair(&[left, browser, far]).is_none());
}

#[test]
fn slurp_does_not_cross_workspaces() {
    let left = window("left", 100, 1, true);
    let mut right = window("right", 200, 2, false);
    right.workspace = Some("other".to_owned());
    assert!(slurp_pair(&[left, right]).is_none());
}

#[test]
fn slurp_requires_focus_and_singleton_columns() {
    let left = window("left", 100, 1, true);
    let right = window("right", 200, 2, false);
    assert!(slurp_pair(std::slice::from_ref(&right)).is_none());
    for col in [1, 2] {
        assert!(
            slurp_pair(&[
                left.clone(),
                right.clone(),
                window("extra", 300, col, false)
            ])
            .is_none()
        );
    }
}

#[test]
fn floating_unknown_workspace_and_fullscreen_fall_back() {
    let mut left = window("left", 100, 1, true);
    left.column = None;
    assert!(!singleton_column(&left, std::slice::from_ref(&left)));
    left.column = Some(1);
    left.workspace = None;
    assert!(!singleton_column(&left, std::slice::from_ref(&left)));
    left.workspace = Some("1".to_owned());
    left.fullscreen = true;
    assert!(!singleton_column(&left, std::slice::from_ref(&left)));
}

#[test]
fn niri_query_payload() {
    let mut raw = json!([{"id":7,"pid":100,"app_id":"Alacritty","workspace_id":1,
        "is_focused":true,"layout":{"pos_in_scrolling_layout":[3,1]}}]);
    assert_eq!(
        parse_windows(&raw.to_string(), WmKind::Niri).unwrap(),
        [window("7", 100, 3, true)]
    );
    raw[0]["layout"]["pos_in_scrolling_layout"] = Value::Null;
    assert_eq!(
        parse_windows(&raw.to_string(), WmKind::Niri).unwrap()[0].column,
        None
    );
}

#[test]
fn omni_query_payload_and_missing_capabilities() {
    let mut raw = json!({"result":{"payload":{"windows":[{
        "id":"ow_example","pid":100,"app":{"bundleId":"org.alacritty"},
        "workspace":{"id":"main"},"columnIndex":1,"isFocused":true
    }]}}});
    let parsed = parse_windows(&raw.to_string(), WmKind::Omniwm).unwrap();
    assert_eq!(parsed[0].id, "ow_example");
    assert_eq!(parsed[0].workspace.as_deref(), Some("main"));
    assert!(parsed[0].terminal());
    raw["result"]["payload"]["windows"][0]["columnIndex"] = Value::Null;
    assert_eq!(
        parse_windows(&raw.to_string(), WmKind::Omniwm).unwrap()[0].column,
        None
    );
}

#[test]
fn invalid_query_is_an_error_not_an_empty_layout() {
    assert!(parse_windows("{}", WmKind::Omniwm).is_err());
    assert!(parse_windows("[{\"pid\":100}]", WmKind::Niri).is_err());
}

#[test]
fn ancestry_handles_cycles() {
    let tree = HashMap::from([(20, 21), (21, 20)]);
    assert!(!descendant(20, 99, &tree));
    assert!(descendant(20, 21, &tree));
}

#[test]
fn native_fallback_only_for_unsupported_cases() {
    let wm = FakeWm::default();
    dispatch("slurp", &wm, &Tmux::default()).unwrap();
    assert_eq!(*wm.fallbacks.borrow(), ["slurp"]);
    wm.fail_query.set(true);
    assert!(dispatch("expel", &wm, &Tmux::default()).is_err());
    assert_eq!(*wm.fallbacks.borrow(), ["slurp"]);
}

static NEXT_SOCKET: AtomicUsize = AtomicUsize::new(0);

// Act like a terminal emulator: consume client output so a full PTY buffer
// cannot block tmux during attachment, detachment, or server shutdown.
struct PtyReader {
    stop: Arc<AtomicBool>,
    thread: Option<thread::JoinHandle<Vec<u8>>>,
}

impl PtyReader {
    fn new(mut master: File) -> Self {
        // SAFETY: master is an owned, valid descriptor. No other code uses it.
        assert_ne!(
            unsafe { libc::fcntl(master.as_raw_fd(), libc::F_SETFL, libc::O_NONBLOCK) },
            -1
        );
        let stop = Arc::new(AtomicBool::new(false));
        let stopped = Arc::clone(&stop);
        let thread = thread::spawn(move || {
            let mut output = Vec::new();
            let mut buffer = [0; 4096];
            while !stopped.load(Ordering::Relaxed) {
                match master.read(&mut buffer) {
                    Ok(0) => break,
                    Ok(n) => output.extend_from_slice(&buffer[..n]),
                    Err(e) if e.kind() == std::io::ErrorKind::Interrupted => continue,
                    Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                        thread::sleep(Duration::from_millis(5));
                    }
                    // Linux reports EIO when the last slave closes.
                    Err(_) => break,
                }
            }
            output
        });
        Self {
            stop,
            thread: Some(thread),
        }
    }

    fn finish(&mut self) -> Vec<u8> {
        self.stop.store(true, Ordering::Relaxed);
        self.thread
            .take()
            .and_then(|t| t.join().ok())
            .unwrap_or_default()
    }
}

impl Drop for PtyReader {
    fn drop(&mut self) {
        self.finish();
    }
}

#[test]
fn pty_reader_drains_more_than_a_terminal_buffer() {
    use std::io::Write;
    use std::os::fd::OwnedFd;
    use std::os::unix::net::UnixStream;

    let (input, mut output) = UnixStream::pair().unwrap();
    output
        .set_write_timeout(Some(Duration::from_secs(3)))
        .unwrap();
    let mut reader = PtyReader::new(File::from(OwnedFd::from(input)));
    output.write_all(&vec![b'x'; 1024 * 1024]).unwrap();
    assert!(!reader.finish().is_empty());
}

struct Harness {
    tmux: Tmux,
    wm: FakeWm,
    masters: RefCell<Vec<PtyReader>>,
    pids: Rc<RefCell<Vec<u32>>>,
    children: RefCell<Vec<Child>>,
}

impl Harness {
    fn new() -> Self {
        let pids = Rc::new(RefCell::new(Vec::<u32>::new()));
        let child_pids = Rc::clone(&pids);
        let h = Self {
            tmux: Tmux {
                socket: format!(
                    "test-bridge-{}-{}",
                    std::process::id(),
                    NEXT_SOCKET.fetch_add(1, Ordering::Relaxed)
                ),
                // Test clients are direct children of this process. Supply
                // that known tree: Darwin's Nix sandbox restricts global ps.
                process_tree: Box::new(move || {
                    Ok(child_pids
                        .borrow()
                        .iter()
                        .map(|pid| (*pid, std::process::id()))
                        .collect())
                }),
            },
            wm: FakeWm::default(),
            masters: RefCell::new(vec![]),
            pids,
            children: RefCell::new(vec![]),
        };
        output(
            "tmux",
            &[
                "-L",
                &h.tmux.socket,
                "-f",
                "/dev/null",
                "new-session",
                "-d",
                "-s",
                "left",
                "sleep 600",
            ],
        )
        .unwrap();
        let child = h.attach("left");
        h.wm.items
            .borrow_mut()
            .push(window("left", child.id(), 1, true));
        h.children.borrow_mut().push(child);
        h
    }

    fn attach(&self, session: &str) -> Child {
        let mut master = -1;
        let mut slave = -1;
        let mut size = libc::winsize {
            ws_row: 30,
            ws_col: 100,
            ws_xpixel: 0,
            ws_ypixel: 0,
        };
        // SAFETY: openpty receives valid output pointers and a valid window size.
        assert_eq!(
            unsafe {
                libc::openpty(
                    &mut master,
                    &mut slave,
                    std::ptr::null_mut(),
                    std::ptr::null_mut(),
                    &mut size,
                )
            },
            0
        );
        // SAFETY: successful openpty gave us unique ownership of these descriptors.
        let (master, slave) = unsafe { (File::from_raw_fd(master), File::from_raw_fd(slave)) };
        // openpty does not set close-on-exec. Do not leak PTYs into other
        // clients or tmux servers, which would keep them alive during cleanup.
        for fd in [master.as_raw_fd(), slave.as_raw_fd()] {
            // SAFETY: both descriptors are owned and valid.
            assert_ne!(
                unsafe { libc::fcntl(fd, libc::F_SETFD, libc::FD_CLOEXEC) },
                -1
            );
        }
        let mut reader = PtyReader::new(master);
        let mut command = Command::new("tmux");
        command
            .args(["-L", &self.tmux.socket, "attach-session", "-t", session])
            .stdin(slave.try_clone().unwrap())
            .stdout(slave.try_clone().unwrap())
            .stderr(slave)
            .env("TERM", "xterm-256color")
            .env_remove("TMUX")
            .env_remove("TMUX_PANE");
        // SAFETY: the child hook calls only the async-signal-safe setsid syscall.
        unsafe {
            command.pre_exec(|| {
                if libc::setsid() == -1 {
                    return Err(std::io::Error::last_os_error());
                }
                Ok(())
            });
        }
        let mut child = command.spawn().unwrap();
        self.pids.borrow_mut().push(child.id());
        let deadline = Instant::now() + Duration::from_secs(3);
        loop {
            let clients = self
                .tmux
                .call(&["list-clients", "-F", "#{client_pid}"])
                .unwrap();
            if clients.lines().any(|line| line == child.id().to_string()) {
                break;
            }
            if let Some(status) = child.try_wait().unwrap() {
                let output = reader.finish();
                panic!(
                    "tmux client exited ({status}): {}",
                    String::from_utf8_lossy(&output)
                );
            }
            if Instant::now() >= deadline {
                let _ = child.kill();
                let _ = child.wait();
                let output = reader.finish();
                panic!(
                    "tmux client failed to attach: {}",
                    String::from_utf8_lossy(&output)
                );
            }
            thread::sleep(Duration::from_millis(10));
        }
        self.masters.borrow_mut().push(reader);
        child
    }

    fn right(&self, command: &str) -> u32 {
        self.tmux
            .call(&["new-session", "-d", "-s", "right", command])
            .unwrap();
        let child = self.attach("right");
        let pid = child.id();
        self.wm
            .items
            .borrow_mut()
            .push(window("right", pid, 2, false));
        self.children.borrow_mut().push(child);
        pid
    }

    fn endpoint(&self, index: usize) -> Endpoint {
        let windows = self.wm.items.borrow();
        self.tmux
            .endpoint(&windows[index], &windows)
            .expect("eligible endpoint")
    }

    fn split(&self) {
        self.tmux
            .call(&["split-window", "-d", "-t", "left:", "sleep 600"])
            .unwrap();
    }

    fn spawn(&self, _socket: &str, session: &str, _cwd: &str) -> Result<Child> {
        let child = self.attach(session);
        let pid = self.wm.items.borrow()[0].pid.unwrap();
        *self.wm.items.borrow_mut() = vec![
            window("left", pid, 1, false),
            window("new", child.id(), 2, true),
        ];
        Ok(child)
    }

    fn count_sessions(&self) -> usize {
        self.tmux.call(&["list-sessions"]).unwrap().lines().count()
    }

    fn pane_pid(&self, pane: &str) -> String {
        self.tmux
            .call(&["display-message", "-p", "-t", pane, "#{pane_pid}"])
            .unwrap()
    }
}

fn wait_for_exit(pid: u32) {
    let deadline = Instant::now() + Duration::from_secs(3);
    loop {
        // SAFETY: waitpid with a null status pointer is valid for any child PID.
        let result = unsafe { libc::waitpid(pid as i32, std::ptr::null_mut(), libc::WNOHANG) };
        if result != 0 {
            return;
        }
        assert!(Instant::now() < deadline, "client did not detach");
        thread::sleep(Duration::from_millis(10));
    }
}

impl Drop for Harness {
    fn drop(&mut self) {
        let _ = self.tmux.call(&["kill-server"]);
        // Closing the masters also hangs up clients if server shutdown failed.
        self.masters.get_mut().clear();
        for pid in self.pids.borrow().iter() {
            // Cleanup must never panic: that would abort the entire test binary
            // during unwinding and obscure the original assertion failure.
            // SAFETY: only kill a PID if waitpid confirms it is our unreaped child.
            unsafe {
                if libc::waitpid(*pid as i32, std::ptr::null_mut(), libc::WNOHANG) == 0 {
                    libc::kill(*pid as i32, libc::SIGKILL);
                    libc::waitpid(*pid as i32, std::ptr::null_mut(), 0);
                }
            }
        }
    }
}

#[test]
fn cleanup_survives_failed_shutdown_during_unwinding() {
    let h = Harness::new();
    let socket = h.tmux.socket.clone();
    let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(move || {
        let mut h = h;
        // Simulate an unavailable server control socket while a client lives.
        h.tmux.socket.push_str("-unavailable");
        panic!("original test failure");
    }));
    let _ = output("tmux", &["-L", &socket, "kill-server"]);
    let panic = result.expect_err("the original panic must not be swallowed");
    assert_eq!(panic.downcast_ref::<&str>(), Some(&"original test failure"));
}

#[test]
fn endpoint_matches_client_and_ancestor() {
    let h = Harness::new();
    let client = h.wm.items.borrow()[0].pid.unwrap();
    assert_eq!(h.endpoint(0).client, client);
    let direct = window("direct", client, 1, true);
    assert!(
        h.tmux
            .endpoint_with_parents(&direct, std::slice::from_ref(&direct), || {
                panic!("an exact sole-client match must not query ps")
            })
            .is_some()
    );
    let ancestor = window("ancestor", std::process::id(), 1, true);
    let windows = std::slice::from_ref(&ancestor);
    // Supply the known child relationship instead of querying system processes
    // from inside the Darwin build sandbox.
    assert!(
        h.tmux
            .endpoint_with_parents(&ancestor, windows, || {
                Ok(HashMap::from([(client, std::process::id())]))
            })
            .is_some()
    );
    assert!(
        h.tmux
            .endpoint_with_parents(&ancestor, windows, || Err("ps denied".to_owned()))
            .is_none()
    );
}

#[test]
fn arbitrary_session_names_are_eligible() {
    let h = Harness::new();
    let original = h.endpoint(0);
    h.tmux
        .call(&["rename-session", "-t", "left", "personal-work"])
        .unwrap();
    assert_eq!(h.endpoint(0), original);
}

#[test]
fn ambiguous_gui_pid_is_not_eligible() {
    let h = Harness::new();
    let mut windows = h.wm.items.borrow().clone();
    let mut other = windows[0].clone();
    other.id = "other".to_owned();
    windows.push(other);
    assert!(h.tmux.endpoint(&windows[0], &windows).is_none());
}

#[test]
fn extra_tabs_or_clients_are_not_eligible() {
    let h = Harness::new();
    h.tmux
        .call(&["new-window", "-d", "-t", "left", "sleep 600"])
        .unwrap();
    let windows = h.wm.items.borrow().clone();
    assert!(h.tmux.endpoint(&windows[0], &windows).is_none());
    h.tmux.call(&["kill-window", "-t", "left:1"]).unwrap();
    let child = h.attach("left");
    h.children.borrow_mut().push(child);
    assert!(h.tmux.endpoint(&windows[0], &windows).is_none());
}

#[test]
fn linked_windows_are_not_eligible() {
    let h = Harness::new();
    h.tmux
        .call(&["new-session", "-d", "-s", "other", "sleep 600"])
        .unwrap();
    h.tmux
        .call(&["link-window", "-s", "left:0", "-t", "other:1"])
        .unwrap();
    let windows = h.wm.items.borrow();
    assert!(h.tmux.endpoint(&windows[0], &windows).is_none());
}

#[test]
fn slurp_preserves_process_history_and_detaches_source() {
    let h = Harness::new();
    let client = h.right("printf 'bridge-history-marker\\n'; sleep 600");
    let source = h.endpoint(1);
    let pid = h.pane_pid(&source.pane);
    assert!(slurp(&h.wm, &h.tmux).unwrap());
    assert_eq!(h.pane_pid(&source.pane), pid);
    assert!(
        h.tmux
            .call(&["capture-pane", "-p", "-t", &source.pane, "-S", "-"])
            .unwrap()
            .contains("bridge-history-marker")
    );
    assert_eq!(h.endpoint(0).panes.len(), 2);
    wait_for_exit(client);
    assert_eq!(*h.wm.focused.borrow(), ["left"]);
}

#[test]
fn multi_pane_slurp_falls_back() {
    let h = Harness::new();
    h.right("sleep 600");
    h.split();
    dispatch("slurp", &h.wm, &h.tmux).unwrap();
    assert_eq!(*h.wm.fallbacks.borrow(), ["slurp"]);
    assert_eq!(h.count_sessions(), 2);
}

#[test]
fn layout_race_aborts_without_native_fallback() {
    let h = Harness::new();
    h.right("sleep 600");
    h.wm.snapshots
        .borrow_mut()
        .extend([h.wm.items.borrow().clone(), vec![]]);
    assert!(dispatch("slurp", &h.wm, &h.tmux).is_err());
    assert!(h.wm.fallbacks.borrow().is_empty());
    assert_eq!(h.endpoint(0).panes.len(), 1);
}

#[test]
fn expel_preserves_process_and_uses_ordinary_unnamed_session() {
    let h = Harness::new();
    h.split();
    let source = h.endpoint(0);
    let pid = h.pane_pid(&source.pane);
    assert!(
        expel(&h.wm, &h.tmux, Duration::from_secs(3), |s, n, c| h
            .spawn(s, n, c))
        .unwrap()
    );
    assert_eq!(h.pane_pid(&source.pane), pid);
    assert_eq!(h.endpoint(0).panes.len(), 1);
    assert_eq!(
        h.endpoint(1).panes.as_slice(),
        std::slice::from_ref(&source.pane)
    );
    let name = h
        .tmux
        .call(&[
            "display-message",
            "-p",
            "-t",
            &source.pane,
            "#{session_name}",
        ])
        .unwrap();
    assert!(
        name.parse::<u64>().is_ok(),
        "tmux should assign its normal numeric name"
    );
    assert_eq!(*h.wm.focused.borrow(), ["new"]);
}

#[test]
fn single_pane_expel_falls_back() {
    let h = Harness::new();
    dispatch("expel", &h.wm, &h.tmux).unwrap();
    assert_eq!(*h.wm.fallbacks.borrow(), ["expel"]);
}

#[test]
fn failed_launch_cleans_only_placeholder() {
    let h = Harness::new();
    h.split();
    let source = h.endpoint(0);
    assert!(
        expel(&h.wm, &h.tmux, Duration::from_secs(3), |_, _, _| Err(
            "launch failed".to_owned()
        ))
        .is_err()
    );
    assert_eq!(h.endpoint(0), source);
    assert_eq!(h.count_sessions(), 1);
}

#[test]
fn timeout_leaves_source_unchanged() {
    let h = Harness::new();
    h.split();
    let source = h.endpoint(0);
    assert!(expel(&h.wm, &h.tmux, Duration::ZERO, |s, n, c| h.spawn(s, n, c)).is_err());
    assert_eq!(h.endpoint(0), source);
    assert_eq!(h.count_sessions(), 1);
}

#[test]
fn source_changes_during_expel_abort_transfer() {
    let h = Harness::new();
    h.split();
    let source = h.endpoint(0);
    assert!(
        expel(&h.wm, &h.tmux, Duration::from_secs(3), |s, n, c| {
            let child = h.spawn(s, n, c)?;
            h.split();
            Ok(child)
        })
        .is_err()
    );
    assert!(h.endpoint(0).panes.contains(&source.pane));
    assert_eq!(h.endpoint(0).panes.len(), 3);
    assert_eq!(h.count_sessions(), 1);
}

#[test]
fn cleanup_does_not_kill_replaced_placeholder() {
    let h = Harness::new();
    h.split();
    let source = h.endpoint(0);
    assert!(
        expel(&h.wm, &h.tmux, Duration::from_secs(3), |_, session, _| {
            h.tmux.call(&[
                "respawn-pane",
                "-k",
                "-t",
                &format!("{session}:"),
                "sleep 600",
            ])?;
            Err("placeholder replaced".to_owned())
        })
        .is_err()
    );
    assert_eq!(h.endpoint(0), source);
    assert_eq!(h.count_sessions(), 2);
}

#[test]
fn post_transfer_failure_preserves_destination() {
    let h = Harness::new();
    h.split();
    let source = h.endpoint(0);
    h.wm.fail_focus.set(true);
    assert!(
        expel(&h.wm, &h.tmux, Duration::from_secs(3), |s, n, c| h
            .spawn(s, n, c))
        .is_err()
    );
    assert_eq!(h.endpoint(1).panes, [source.pane]);
}
