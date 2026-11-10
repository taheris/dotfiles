use crate::geometry::Target;
use anyhow::{Context, Result, bail};

#[cfg(any(target_os = "macos", test))]
fn permission_hint(error: &str) -> &'static str {
    if error.contains("-25211") || error.contains("not allowed assistive access") {
        "\nGrant Accessibility access to the invoking Terminal/Karabiner process in System Settings > Privacy & Security > Accessibility."
    } else if error.contains("-1743") || error.contains("not authorized to send Apple events") {
        "\nGrant the invoking Terminal/Karabiner process Automation access to the browser and System Events."
    } else {
        ""
    }
}

pub fn detect() -> Result<Target> {
    #[cfg(target_os = "macos")]
    {
        use std::{process::Command, time::Duration};
        let mut command = Command::new("/usr/bin/osascript");
        command.args([
            "-l",
            "JavaScript",
            "-e",
            include_str!("browser.js"),
            include_str!("detect.js"),
        ]);
        let output = crate::probe::run(command, Duration::from_secs(20))?;
        if !output.success {
            bail!(
                "Browser probe failed: {}{}\nLast probe phase: {}",
                output.stderr.trim(),
                permission_hint(&output.stderr),
                output.last_phase.as_deref().unwrap_or("unknown")
            );
        }
        serde_json::from_slice(&output.stdout).context("invalid browser geometry")
    }
    #[cfg(not(target_os = "macos"))]
    {
        bail!(
            "automatic browser detection is currently macOS-only (Safari, Chromium, Google Chrome); use --target FILE for an external Linux browser/compositor adapter"
        )
    }
}

#[derive(Debug, serde::Deserialize, serde::Serialize)]
pub struct BrowserFocus {
    pid: u32,
    bundle: String,
}

pub fn remember_browser() -> Result<Option<BrowserFocus>> {
    #[cfg(target_os = "macos")]
    {
        let output = std::process::Command::new("/usr/bin/osascript")
            .args([
                "-l",
                "JavaScript",
                "-e",
                include_str!("focus.js"),
                "remember",
            ])
            .output()
            .context("remembering browser focus before launching OBS")?;
        anyhow::ensure!(
            output.status.success(),
            "cannot remember browser focus: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        );
        serde_json::from_slice(&output.stdout).context("invalid browser-focus snapshot")
    }
    #[cfg(not(target_os = "macos"))]
    {
        Ok(None)
    }
}

pub fn restore_browser(focus: Option<&BrowserFocus>) -> Result<()> {
    #[cfg(target_os = "macos")]
    if let Some(focus) = focus {
        let snapshot = serde_json::to_string(focus)?;
        let output = std::process::Command::new("/usr/bin/osascript")
            .args([
                "-l",
                "JavaScript",
                "-e",
                include_str!("focus.js"),
                "restore",
                &snapshot,
            ])
            .output()
            .context("restoring browser focus after launching OBS")?;
        anyhow::ensure!(
            output.status.success(),
            "cannot restore browser focus: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        );
    }
    #[cfg(not(target_os = "macos"))]
    let _ = focus;
    Ok(())
}

#[cfg(any(target_os = "macos", test))]
fn obs_launch_args() -> [&'static str; 3] {
    ["-g", "-b", "com.obsproject.obs-studio"]
}

pub fn launch_obs() -> Result<()> {
    #[cfg(target_os = "macos")]
    {
        // Background, idempotent launch: do not steal the selected browser's
        // focus, and never use -n (which would open another OBS instance).
        let status = std::process::Command::new("/usr/bin/open")
            .args(obs_launch_args())
            .status()
            .context("launching OBS Studio")?;
        anyhow::ensure!(
            status.success(),
            "could not launch OBS Studio; install/open OBS and enable its WebSocket server"
        );
        Ok(())
    }
    #[cfg(not(target_os = "macos"))]
    {
        bail!(
            "automatic OBS launch is currently macOS-only; start OBS manually and enable its WebSocket server"
        )
    }
}

pub fn from_file(path: &std::path::Path) -> Result<Target> {
    serde_json::from_slice(&std::fs::read(path).context("reading target geometry")?)
        .context("invalid target geometry JSON")
}

#[cfg(test)]
mod tests {
    use super::{dispatch_notification, notification_args, obs_launch_args, permission_hint};

    #[test]
    fn notification_delivery_does_not_wait_for_the_sender_to_exit() {
        let mut command = std::process::Command::new("sh");
        command.args(["-c", "exec sleep 5"]);
        let start = std::time::Instant::now();
        let mut child = dispatch_notification(command).unwrap();
        let running = child.try_wait().unwrap().is_none();
        let elapsed = start.elapsed();
        let _ = child.kill();
        child.wait().unwrap();
        assert!(running, "notification sender was waited for");
        assert!(elapsed < std::time::Duration::from_secs(1));
    }

    #[test]
    fn obs_launch_is_background_and_does_not_create_duplicate_instances() {
        assert_eq!(obs_launch_args(), ["-g", "-b", "com.obsproject.obs-studio"]);
        assert!(!obs_launch_args().contains(&"-n"));
    }

    #[test]
    fn notifications_have_no_script_or_click_action() {
        let message = "Failed: \"quoted\"; $(not-a-command)";
        assert_eq!(
            notification_args(message),
            ["-title", "OBS video crop", "-message", message]
        );
    }

    #[test]
    fn permission_errors_receive_specific_guidance() {
        assert!(
            permission_hint("osascript is not allowed assistive access. (-25211)")
                .contains("Privacy & Security > Accessibility")
        );
        assert!(permission_hint("Not authorized. (-1743)").contains("Automation"));
    }

    #[test]
    fn runtime_errors_do_not_receive_misleading_permission_guidance() {
        assert_eq!(
            permission_hint("TypeError: windows.filter is not a function (-2700)"),
            ""
        );
        assert_eq!(
            permission_hint("Unsupported focused application (-2700)"),
            ""
        );
    }
}

#[cfg(any(target_os = "macos", test))]
fn notification_args(message: &str) -> [&str; 4] {
    ["-title", "OBS video crop", "-message", message]
}

#[cfg(any(target_os = "macos", test))]
fn dispatch_notification(
    mut command: std::process::Command,
) -> std::io::Result<std::process::Child> {
    command
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn()
}

pub fn notify(message: &str) {
    #[cfg(target_os = "macos")]
    {
        // Nix supplies the signed notification app on PATH. No click action is
        // configured, so notifications never activate Script Editor.
        // Do not wait for notification authorization/delivery: Karabiner may
        // wait for its shell command to exit before accepting another toggle.
        let mut command = std::process::Command::new("terminal-notifier");
        command.args(notification_args(message));
        if let Err(error) = dispatch_notification(command) {
            eprintln!("obs-video-crop: could not send notification: {error}");
        }
    }
    #[cfg(not(target_os = "macos"))]
    let _ = message;
}
