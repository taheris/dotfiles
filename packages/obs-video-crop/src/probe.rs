use anyhow::{Context, Result, anyhow, bail};
use std::{
    io::{BufRead, BufReader, Read},
    process::{Command, Stdio},
    thread,
    time::Duration,
};
use wait_timeout::ChildExt;

pub struct Output {
    pub success: bool,
    pub stdout: Vec<u8>,
    pub stderr: String,
    pub last_phase: Option<String>,
}

/// Drain both pipes while waiting. In particular, native Accessibility errors
/// and progress output must never block the child on a full stderr pipe.
pub fn run(mut command: Command, timeout: Duration) -> Result<Output> {
    let mut child = command
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .context("starting browser probe")?;
    let mut stdout = child
        .stdout
        .take()
        .context("missing browser-probe stdout")?;
    let stderr = child
        .stderr
        .take()
        .context("missing browser-probe stderr")?;
    let stdout_reader = thread::spawn(move || -> std::io::Result<Vec<u8>> {
        let mut data = Vec::new();
        stdout.read_to_end(&mut data)?;
        Ok(data)
    });
    let stderr_reader = thread::spawn(move || -> std::io::Result<(String, Option<String>)> {
        let mut errors = String::new();
        let mut phase = None;
        for line in BufReader::new(stderr).lines() {
            let line = line?;
            if let Some((_, value)) = line.split_once("obs-video-crop probe phase: ") {
                phase = Some(value.to_owned());
                eprintln!("obs-video-crop probe phase: {value}");
            } else {
                errors.push_str(&line);
                errors.push('\n');
            }
        }
        Ok((errors, phase))
    });
    let status = child.wait_timeout(timeout);
    let timed_out = matches!(&status, Ok(None));
    if !matches!(&status, Ok(Some(_))) {
        let _ = child.kill();
    }
    let reaped = child.wait();
    let stdout = stdout_reader
        .join()
        .map_err(|_| anyhow!("browser stdout reader panicked"))??;
    let (stderr, last_phase) = stderr_reader
        .join()
        .map_err(|_| anyhow!("browser stderr reader panicked"))??;
    status.context("waiting for browser probe")?;
    let status = reaped.context("reaping browser probe")?;
    if timed_out {
        bail!(
            "Browser probe timed out after {} seconds. Last phase: {}. The browser or Accessibility service may be slow/unresponsive; this is not necessarily a permissions error.",
            timeout.as_secs_f64(),
            last_phase
                .as_deref()
                .unwrap_or("before progress was reported")
        );
    }
    Ok(Output {
        success: status.success(),
        stdout,
        stderr,
        last_phase,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    fn shell(script: &str) -> Command {
        let mut command = Command::new("sh");
        command.args(["-c", script]);
        command
    }

    #[test]
    fn progress_and_native_errors_are_kept_separate() {
        let output = run(shell("printf 'obs-video-crop probe phase: reading native windows\n' >&2; printf 'execution error: Invalid index. (-1719)\n' >&2; exit 1"), Duration::from_secs(3)).unwrap();
        assert!(!output.success);
        assert_eq!(output.last_phase.as_deref(), Some("reading native windows"));
        assert!(output.stderr.contains("Invalid index"));
        assert!(!output.stderr.contains("probe phase"));
    }

    #[test]
    fn timeout_reports_the_last_phase_and_reaps_the_child() {
        let error = run(shell("printf 'obs-video-crop probe phase: waiting for Accessibility\n' >&2; exec sleep 5"), Duration::from_millis(300)).err().unwrap();
        assert!(error.to_string().contains("waiting for Accessibility"));
        assert!(
            error
                .to_string()
                .contains("not necessarily a permissions error")
        );
    }

    #[test]
    fn large_stdout_and_stderr_do_not_deadlock() {
        let output = run(shell("printf '%0100000d' 0; printf '%0100000d\n' 0 >&2; printf 'obs-video-crop probe phase: complete\n' >&2"), Duration::from_secs(3)).unwrap();
        assert!(output.success);
        assert_eq!(output.stdout.len(), 100000);
        assert_eq!(output.stderr.len(), 100001);
        assert_eq!(output.last_phase.as_deref(), Some("complete"));
    }
}
