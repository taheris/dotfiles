//! Terminal-aware consume/expel for niri and OmniWM. Never kills GUI windows.

use serde_json::Value;
use std::collections::{HashMap, HashSet};
use std::env;
use std::fs::{self, File, OpenOptions};
use std::os::fd::AsRawFd;
use std::os::unix::fs::{DirBuilderExt, MetadataExt, OpenOptionsExt};
use std::os::unix::process::CommandExt;
use std::path::PathBuf;
use std::process::{Child, Command, Stdio};
use std::thread;
use std::time::{Duration, Instant};

type Result<T> = std::result::Result<T, String>;

fn output(program: &str, args: &[&str]) -> Result<String> {
    let result = Command::new(program)
        .args(args)
        .output()
        .map_err(|e| format!("{program}: {e}"))?;
    if !result.status.success() {
        return Err(format!(
            "{program}: {}",
            String::from_utf8_lossy(&result.stderr).trim()
        ));
    }
    String::from_utf8(result.stdout)
        .map(|s| s.trim_end_matches('\n').to_owned())
        .map_err(|e| e.to_string())
}

#[derive(Clone, Debug, PartialEq, Eq)]
struct Window {
    id: String,
    pid: Option<u32>,
    app: String,
    workspace: Option<String>,
    column: Option<u64>,
    focused: bool,
    fullscreen: bool,
}

impl Window {
    fn terminal(&self) -> bool {
        matches!(
            self.app.as_str(),
            "Alacritty" | "alacritty" | "org.alacritty"
        )
    }
}

fn scalar(value: &Value) -> Option<String> {
    value
        .as_str()
        .map(str::to_owned)
        .or_else(|| value.as_u64().map(|v| v.to_string()))
}

fn parse_windows(json: &str, kind: WmKind) -> Result<Vec<Window>> {
    let raw: Value = serde_json::from_str(json).map_err(|e| e.to_string())?;
    let list = match kind {
        WmKind::Niri => raw.as_array(),
        WmKind::Omniwm => raw["result"]["payload"]["windows"].as_array(),
    }
    .ok_or("invalid window query response")?;
    list.iter()
        .map(|w| {
            let (app, workspace, column, focused, fullscreen) = match kind {
                WmKind::Niri => (
                    &w["app_id"],
                    &w["workspace_id"],
                    &w["layout"]["pos_in_scrolling_layout"][0],
                    &w["is_focused"],
                    &w["is_fullscreen"],
                ),
                WmKind::Omniwm => (
                    &w["app"]["bundleId"],
                    &w["workspace"]["id"],
                    &w["columnIndex"],
                    &w["isFocused"],
                    &w["isFullscreen"],
                ),
            };
            Ok(Window {
                id: scalar(&w["id"]).ok_or("window has no ID")?,
                pid: w["pid"].as_u64().and_then(|n| n.try_into().ok()),
                app: app.as_str().unwrap_or_default().to_owned(),
                workspace: scalar(workspace),
                column: column.as_u64(),
                focused: focused.as_bool().unwrap_or(false),
                fullscreen: fullscreen.as_bool().unwrap_or(false),
            })
        })
        .collect()
}

#[derive(Clone, Copy)]
enum WmKind {
    Niri,
    Omniwm,
}

trait WindowManager {
    fn windows(&self) -> Result<Vec<Window>>;
    fn focus(&self, window: &Window) -> Result<()>;
    fn fallback(&self, action: &str) -> Result<()>;
}

struct Wm(WmKind);
const OMNI_CTL: &str = "/Applications/OmniWM.app/Contents/MacOS/omniwmctl";

impl WindowManager for Wm {
    fn windows(&self) -> Result<Vec<Window>> {
        let json = match self.0 {
            WmKind::Niri => output("niri", &["msg", "-j", "windows"]),
            WmKind::Omniwm => output(OMNI_CTL, &["query", "windows", "--format", "json"]),
        }?;
        parse_windows(&json, self.0)
    }

    fn focus(&self, window: &Window) -> Result<()> {
        match self.0 {
            WmKind::Niri => output(
                "niri",
                &["msg", "action", "focus-window", "--id", &window.id],
            ),
            WmKind::Omniwm => output(OMNI_CTL, &["window", "focus", &window.id]),
        }
        .map(|_| ())
    }

    fn fallback(&self, action: &str) -> Result<()> {
        let command = match action {
            "slurp" => "consume-window-into-column",
            _ => "expel-window-from-column",
        };
        match self.0 {
            WmKind::Niri => output("niri", &["msg", "action", command]),
            WmKind::Omniwm => output(OMNI_CTL, &["command", command]),
        }
        .map(|_| ())
    }
}

fn singleton_column(window: &Window, windows: &[Window]) -> bool {
    window.workspace.is_some()
        && window.column.is_some()
        && !window.fullscreen
        && windows
            .iter()
            .filter(|w| w.workspace == window.workspace && w.column == window.column)
            .count()
            == 1
}

fn slurp_pair(windows: &[Window]) -> Option<(&Window, &Window)> {
    let focused: Vec<_> = windows.iter().filter(|w| w.focused).collect();
    let [dst] = focused.as_slice() else {
        return None;
    };
    if !dst.terminal() || !singleton_column(dst, windows) {
        return None;
    }
    // Match native consume: never skip another app or cross a workspace boundary.
    let next = windows
        .iter()
        .filter(|w| w.workspace == dst.workspace && w.column > dst.column)
        .filter_map(|w| w.column)
        .min()?;
    let source: Vec<_> = windows
        .iter()
        .filter(|w| w.workspace == dst.workspace && w.column == Some(next))
        .collect();
    let [src] = source.as_slice() else {
        return None;
    };
    (src.terminal() && !src.fullscreen).then_some((dst, src))
}

fn parents() -> Result<HashMap<u32, u32>> {
    let ps = if cfg!(target_os = "macos") {
        "/bin/ps"
    } else {
        "ps"
    };
    output(ps, &["-axo", "pid=,ppid="])?
        .lines()
        .map(|line| {
            let fields: Vec<_> = line.split_whitespace().collect();
            match fields.as_slice() {
                [pid, ppid] => Ok((
                    pid.parse().map_err(|_| "invalid PID")?,
                    ppid.parse().map_err(|_| "invalid parent PID")?,
                )),
                _ => Err("invalid ps output".to_owned()),
            }
        })
        .collect()
}

fn descendant(mut pid: u32, ancestor: u32, tree: &HashMap<u32, u32>) -> bool {
    let mut seen = HashSet::new();
    while pid > 1 && seen.insert(pid) {
        if pid == ancestor {
            return true;
        }
        pid = *tree.get(&pid).unwrap_or(&0);
    }
    false
}

#[derive(Clone, Debug, PartialEq, Eq)]
struct Endpoint {
    session: String,
    client: u32,
    pane: String,
    panes: Vec<String>,
}

struct Tmux {
    socket: String,
}

impl Default for Tmux {
    fn default() -> Self {
        Self {
            // Explicitly select the ordinary server even if invoked inside tmux.
            socket: "default".to_owned(),
        }
    }
}

impl Tmux {
    fn call(&self, args: &[&str]) -> Result<String> {
        let mut argv = vec!["-L", self.socket.as_str()];
        argv.extend_from_slice(args);
        output("tmux", &argv)
    }

    fn endpoint(&self, window: &Window, windows: &[Window]) -> Option<Endpoint> {
        let pid = window.pid?;
        // Alacritty IPC can put multiple GUI windows in one process. Never guess.
        if pid <= 1 || windows.iter().filter(|w| w.pid == Some(pid)).count() != 1 {
            return None;
        }
        // Use printable delimiters: tmux sanitizes control characters in C locales.
        let clients = self
            .call(&["list-clients", "-F", "#{client_pid}|#{session_id}"])
            .ok()?;
        let tree = parents().ok()?;
        let matches: Vec<_> = clients
            .lines()
            .filter_map(|line| {
                let (client, session) = line.split_once('|')?;
                let client = client.parse().ok()?;
                descendant(client, pid, &tree).then_some((client, session))
            })
            .collect();
        let [(client, session)] = matches.as_slice() else {
            return None;
        };
        let panes = self.call(&[
            "list-panes", "-a", "-F",
            "#{session_id}|#{session_windows}|#{session_attached}|#{session_grouped}|#{window_linked}|#{pane_id}|#{pane_active}|#{pane_dead}",
        ]).ok()?;
        let rows: Vec<Vec<_>> = panes
            .lines()
            .map(|line| line.split('|').collect::<Vec<_>>())
            .filter(|r| r.first() == Some(session))
            .collect();
        if rows.is_empty()
            || rows
                .iter()
                .any(|r| r.len() != 8 || r[1..5] != ["1", "1", "0", "0"] || r[7] != "0")
            || self
                .call(&["show-options", "-Av", "-t", session, "detach-on-destroy"])
                .ok()?
                != "on"
        {
            return None;
        }
        let active: Vec<_> = rows.iter().filter(|r| r[6] == "1").collect();
        let [active] = active.as_slice() else {
            return None;
        };
        Some(Endpoint {
            session: session.to_string(),
            client: *client,
            pane: active[5].to_owned(),
            panes: rows.iter().map(|r| r[5].to_owned()).collect(),
        })
    }

    fn join(&self, source: &str, destination: &str) -> Result<()> {
        self.call(&["join-pane", "-v", "-s", source, "-t", destination])
            .map(|_| ())
    }
}

fn alacritty() -> &'static str {
    if cfg!(target_os = "macos") {
        "/Applications/Alacritty.app/Contents/MacOS/alacritty"
    } else {
        "alacritty"
    }
}

fn last_directory() -> PathBuf {
    let root = env::var_os("XDG_RUNTIME_DIR")
        .or_else(|| env::var_os("TMPDIR"))
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/tmp"));
    if let Ok(directory) = fs::read_to_string(root.join("last-dir")) {
        let path = PathBuf::from(directory);
        if path.is_dir() {
            return path;
        }
    }
    env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/"))
}

fn terminal_command() -> Command {
    let mut command = Command::new(alacritty());
    command.env_remove("TMUX").env_remove("TMUX_PANE");
    command
}

fn launch_command() -> Command {
    // Ordinary tmux startup: no special socket, session name, or registration.
    let mut command = terminal_command();
    command
        .arg("--working-directory")
        .arg(last_directory())
        .args(["-e", "tmux"]);
    command
}

fn launch() -> Result<()> {
    Err(format!("Alacritty: {}", launch_command().exec()))
}

fn slurp(wm: &impl WindowManager, tmux: &Tmux) -> Result<bool> {
    let windows = wm.windows()?;
    let Some((dst, src)) = slurp_pair(&windows) else {
        return Ok(false);
    };
    let (Some(destination), Some(source)) =
        (tmux.endpoint(dst, &windows), tmux.endpoint(src, &windows))
    else {
        return Ok(false);
    };
    if destination.session == source.session
        || destination.panes.len() != 1
        || source.panes.len() != 1
    {
        return Ok(false);
    }
    let current = wm.windows()?;
    if slurp_pair(&current) != Some((dst, src))
        || tmux.endpoint(dst, &current).as_ref() != Some(&destination)
        || tmux.endpoint(src, &current).as_ref() != Some(&source)
    {
        return Err("windows changed during slurp; try again".to_owned());
    }
    tmux.join(&source.pane, &destination.pane)?;
    // The emptied session detaches naturally. Never send a GUI close request.
    wm.focus(dst)?;
    Ok(true)
}

fn spawn_attached(socket: &str, session: &str, cwd: &str) -> Result<Child> {
    terminal_command()
        .args([
            "--working-directory",
            cwd,
            "-e",
            "tmux",
            "-L",
            socket,
            "attach-session",
            "-t",
            session,
        ])
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .process_group(0)
        .spawn()
        .map_err(|e| format!("Alacritty: {e}"))
}

fn expel(
    wm: &impl WindowManager,
    tmux: &Tmux,
    timeout: Duration,
    spawn: impl FnOnce(&str, &str, &str) -> Result<Child>,
) -> Result<bool> {
    let windows = wm.windows()?;
    let focused: Vec<_> = windows.iter().filter(|w| w.focused).collect();
    let [src] = focused.as_slice() else {
        return Ok(false);
    };
    if !src.terminal() || !singleton_column(src, &windows) {
        return Ok(false);
    }
    let Some(source) = tmux.endpoint(src, &windows) else {
        return Ok(false);
    };
    if source.panes.len() < 2 {
        return Ok(false);
    }
    let cwd = tmux.call(&[
        "display-message",
        "-p",
        "-t",
        &source.pane,
        "#{pane_current_path}",
    ])?;
    // Let tmux assign an ordinary session name. Track its stable ID, not its name.
    let created = tmux.call(&[
        "new-session",
        "-d",
        "-P",
        "-F",
        "#{session_id}|#{pane_id}|#{pane_pid}|#{pane_start_command}",
        "-c",
        &cwd,
        "sleep 86400",
    ])?;
    let fields: Vec<_> = created.splitn(3, '|').collect();
    let [session, placeholder, identity] = fields.as_slice() else {
        return Err("invalid tmux session creation response".to_owned());
    };
    let mut moved = false;
    let result = (|| {
        tmux.call(&["set-option", "-t", session, "detach-on-destroy", "on"])?;
        let mut process = spawn(&tmux.socket, session, &cwd)?;
        let deadline = Instant::now() + timeout;
        while Instant::now() < deadline {
            if process.try_wait().map_err(|e| e.to_string())?.is_some() {
                return Err("new Alacritty exited before attaching".to_owned());
            }
            let current = wm.windows()?;
            for dst in current.iter().filter(|w| {
                w.id != src.id
                    && w.terminal()
                    && w.workspace == src.workspace
                    && singleton_column(w, &current)
            }) {
                let Some(destination) = tmux.endpoint(dst, &current) else {
                    continue;
                };
                if destination.session != *session {
                    continue;
                }
                if destination.panes != [*placeholder] {
                    return Err("new terminal was modified before transfer".to_owned());
                }
                let original = current.iter().find(|w| w.id == src.id);
                if original.is_none_or(|w| {
                    w.workspace != src.workspace
                        || !singleton_column(w, &current)
                        || tmux.endpoint(w, &current).as_ref() != Some(&source)
                }) || !current
                    .iter()
                    .any(|w| w.focused && (w.id == src.id || w.id == dst.id))
                {
                    return Err("source terminal or focus changed during expel".to_owned());
                }
                tmux.join(&source.pane, placeholder)?;
                moved = true;
                tmux.call(&["kill-pane", "-t", placeholder])?;
                wm.focus(dst)?;
                return Ok(true);
            }
            thread::sleep(Duration::from_millis(50));
        }
        Err("timed out waiting for the new terminal; source pane unchanged".to_owned())
    })();
    if !moved {
        // Only delete our unchanged placeholder, never a user-supplied pane.
        if tmux
            .call(&[
                "display-message",
                "-p",
                "-t",
                placeholder,
                "#{pane_pid}|#{pane_start_command}",
            ])
            .as_deref()
            == Ok(identity)
        {
            let _ = tmux.call(&["kill-pane", "-t", placeholder]);
        }
    }
    result
}

fn lock_file() -> Result<Option<File>> {
    // SAFETY: getuid has no preconditions.
    let uid = unsafe { libc::getuid() };
    let root = env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(env::temp_dir);
    let directory = root.join(format!("terminal-bridge-{uid}"));
    match fs::DirBuilder::new().mode(0o700).create(&directory) {
        Ok(()) => (),
        Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => (),
        Err(e) => return Err(e.to_string()),
    }
    let metadata = fs::symlink_metadata(&directory).map_err(|e| e.to_string())?;
    if !metadata.is_dir() || metadata.uid() != uid || metadata.mode() & 0o077 != 0 {
        return Err(format!("unsafe lock directory: {}", directory.display()));
    }
    let file = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false)
        .mode(0o600)
        .custom_flags(libc::O_NOFOLLOW)
        .open(directory.join("lock"))
        .map_err(|e| e.to_string())?;
    // SAFETY: file owns a valid descriptor for the duration of this call.
    if unsafe { libc::flock(file.as_raw_fd(), libc::LOCK_EX | libc::LOCK_NB) } != 0 {
        let error = std::io::Error::last_os_error();
        if error.kind() == std::io::ErrorKind::WouldBlock {
            return Ok(None);
        }
        return Err(error.to_string());
    }
    Ok(Some(file))
}

fn dispatch(action: &str, wm: &impl WindowManager, tmux: &Tmux) -> Result<()> {
    // Native fallback is only for unsupported cases, never operational failures
    // after a possible partial transfer.
    let handled = match action {
        "slurp" => slurp(wm, tmux)?,
        _ => expel(wm, tmux, Duration::from_secs(8), spawn_attached)?,
    };
    if !handled {
        wm.fallback(action)?;
    }
    Ok(())
}

const USAGE: &str = "Usage: terminal-bridge launch | <slurp|expel> --wm <niri|omniwm>";

fn main_result() -> Result<()> {
    let args: Vec<_> = env::args().skip(1).collect();
    let args: Vec<_> = args.iter().map(String::as_str).collect();
    match args.as_slice() {
        ["--help" | "-h"] => {
            println!("{USAGE}");
            Ok(())
        }
        ["--version"] => {
            println!("terminal-bridge {}", env!("CARGO_PKG_VERSION"));
            Ok(())
        }
        ["launch"] => launch(),
        [
            action @ ("slurp" | "expel"),
            "--wm",
            kind @ ("niri" | "omniwm"),
        ] => {
            let Some(_lock) = lock_file()? else {
                return Ok(());
            };
            let wm = Wm(if *kind == "niri" {
                WmKind::Niri
            } else {
                WmKind::Omniwm
            });
            dispatch(action, &wm, &Tmux::default())
        }
        _ => Err(USAGE.to_owned()),
    }
}

fn main() {
    if let Err(error) = main_result() {
        eprintln!("terminal-bridge: {error}");
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests;
