use crate::{geometry::Selection, obs::Api};
use anyhow::{Context, Result, ensure};
use serde_json::json;

#[derive(Debug, PartialEq)]
pub enum Outcome {
    Started(Selection),
    Stopped(Option<String>),
}

impl Outcome {
    pub fn message(&self) -> String {
        match self {
            Self::Started(selection) => {
                let region = match selection {
                    Selection::Video => "video",
                    Selection::FocusedIframe => {
                        "whole focused iframe, including controls and other embedded content"
                    }
                };
                format!("Recording started: {region}. Press Option+Fn again to stop and save.")
            }
            Self::Stopped(Some(path)) => format!("Recording saved: {path}"),
            Self::Stopped(None) => {
                "Recording stopped. Find the file in OBS: File > Show Recordings.".into()
            }
        }
    }
}

fn is_active(obs: &mut impl Api) -> Result<bool> {
    obs.request("GetRecordStatus", json!({}))?["outputActive"]
        .as_bool()
        .context("OBS returned no recording status; refusing to guess")
}

fn wait_until_stopped(
    obs: &mut impl Api,
    timeout: std::time::Duration,
    interval: std::time::Duration,
) -> Result<()> {
    let deadline = std::time::Instant::now() + timeout;
    loop {
        // GetRecordStatus reads obs_output_active(recordOutput), the same flag
        // used by GetOutputList. StopRecord only queues the frontend stop.
        if !is_active(obs)? {
            return Ok(());
        }
        ensure!(
            std::time::Instant::now() < deadline,
            "OBS has not confirmed that recording finished stopping; capture has not been released"
        );
        std::thread::sleep(interval);
    }
}

/// Check output state before calling prepare: stopping must not require a
/// focused browser, working capture stream, readable target file, or a probe.
pub fn toggle<O: Api>(
    obs: &mut O,
    prepare: impl FnOnce(&mut O) -> Result<Selection>,
) -> Result<Outcome> {
    if is_active(obs)? {
        eprintln!("obs-video-crop: stopping recording; waiting for OBS to finalize the file");
        let response = obs.request("StopRecord", json!({}))?;
        let path = response["outputPath"]
            .as_str()
            .filter(|path| !path.is_empty())
            .map(str::to_owned);
        // StopRecord returns before finalization completes:
        // obs-websocket/src/requesthandler/RequestHandler_Record.cpp.
        // Wait before claiming a saved file or releasing ScreenCaptureKit.
        wait_until_stopped(
            obs,
            std::time::Duration::from_secs(120),
            std::time::Duration::from_millis(100),
        ).with_context(|| format!(
            "OBS accepted the stop request, but completion is unconfirmed. Reported output path: {}",
            path.as_deref().unwrap_or("not provided")
        ))?;
        return Ok(Outcome::Stopped(path));
    }

    eprintln!("obs-video-crop: selecting capture region before recording");
    let selection = prepare(obs)?;
    ensure!(
        !is_active(obs)?,
        "OBS recording started while preparing the crop; leaving it running unchanged"
    );
    eprintln!("obs-video-crop: requesting OBS recording start");
    obs.request("StartRecord", json!({}))?;

    // StartRecord acknowledges a request; do not claim success until OBS reports
    // an active output. Never stop a possibly active recording on a timeout.
    for attempt in 0..20 {
        if attempt > 0 {
            std::thread::sleep(std::time::Duration::from_millis(100));
        }
        if is_active(obs)? {
            return Ok(Outcome::Started(selection));
        }
    }
    anyhow::bail!(
        "OBS has not confirmed recording startup; check its recording indicator before retrying"
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use anyhow::bail;
    use serde_json::Value;

    #[derive(Default)]
    struct Mock {
        calls: Vec<String>,
        active: bool,
        paused: bool,
        bad_status: bool,
        fail_start: bool,
        fail_stop: bool,
        startup_delay: usize,
        pending: usize,
        path_missing: bool,
        stopping: bool,
        shutdown_delay: usize,
        pending_stop: usize,
        bad_stop_status: bool,
    }

    impl Api for Mock {
        fn request(&mut self, kind: &str, _data: Value) -> Result<Value> {
            self.calls.push(kind.to_owned());
            Ok(match kind {
                "GetRecordStatus" if self.bad_status || (self.stopping && self.bad_stop_status) => {
                    json!({})
                }
                "GetRecordStatus" => {
                    if self.pending > 0 {
                        self.pending -= 1;
                        json!({ "outputActive": false })
                    } else if self.stopping {
                        if self.pending_stop > 0 {
                            self.pending_stop -= 1;
                            json!({ "outputActive": true })
                        } else {
                            self.active = false;
                            self.stopping = false;
                            json!({ "outputActive": false })
                        }
                    } else {
                        json!({ "outputActive": self.active, "outputPaused": self.paused })
                    }
                }
                "StartRecord" => {
                    if self.fail_start {
                        bail!("start failed");
                    }
                    self.active = true;
                    self.pending = self.startup_delay;
                    json!({})
                }
                "StopRecord" => {
                    if self.fail_stop {
                        bail!("stop failed");
                    }
                    self.stopping = true;
                    self.pending_stop = self.shutdown_delay;
                    if self.path_missing {
                        json!({})
                    } else {
                        json!({ "outputPath": "/Users/test/Movies/clip.mkv" })
                    }
                }
                _ => json!({}),
            })
        }
    }

    #[test]
    fn active_recording_stops_without_probing_or_configuring_capture() {
        let mut obs = Mock {
            active: true,
            ..Mock::default()
        };
        let outcome = toggle(&mut obs, |_| panic!("must not inspect the browser on stop")).unwrap();
        assert_eq!(
            outcome,
            Outcome::Stopped(Some("/Users/test/Movies/clip.mkv".into()))
        );
        assert_eq!(
            obs.calls,
            ["GetRecordStatus", "StopRecord", "GetRecordStatus"]
        );
        assert!(outcome.message().contains("/Users/test/Movies/clip.mkv"));
    }

    #[test]
    fn paused_recording_is_stopped_not_resumed_or_retargeted() {
        let mut obs = Mock {
            active: true,
            paused: true,
            ..Mock::default()
        };
        toggle(&mut obs, |_| panic!("must not probe paused recording")).unwrap();
        assert_eq!(
            obs.calls,
            ["GetRecordStatus", "StopRecord", "GetRecordStatus"]
        );
    }

    #[test]
    fn stop_acknowledgment_is_not_treated_as_completed_finalization() {
        let mut obs = Mock {
            active: true,
            shutdown_delay: 2,
            ..Mock::default()
        };
        let outcome = toggle(&mut obs, |_| panic!("stopping must not probe")).unwrap();
        assert!(matches!(outcome, Outcome::Stopped(Some(_))));
        assert!(!obs.active);
        assert_eq!(
            obs.calls,
            [
                "GetRecordStatus",
                "StopRecord",
                "GetRecordStatus",
                "GetRecordStatus",
                "GetRecordStatus"
            ]
        );
    }

    #[test]
    fn unconfirmed_stop_preserves_reported_path_without_claiming_success() {
        let mut obs = Mock {
            active: true,
            bad_stop_status: true,
            ..Mock::default()
        };
        let result = toggle(&mut obs, |_| panic!("must not probe"));
        assert!(
            result
                .unwrap_err()
                .to_string()
                .contains("/Users/test/Movies/clip.mkv")
        );
        assert_eq!(
            obs.calls,
            ["GetRecordStatus", "StopRecord", "GetRecordStatus"]
        );
    }

    #[test]
    fn stop_confirmation_timeout_does_not_issue_more_output_actions() {
        let mut obs = Mock {
            active: true,
            ..Mock::default()
        };
        assert!(
            wait_until_stopped(
                &mut obs,
                std::time::Duration::ZERO,
                std::time::Duration::ZERO
            )
            .is_err()
        );
        assert_eq!(obs.calls, ["GetRecordStatus"]);
    }

    #[test]
    fn idle_output_starts_only_after_crop_and_scene_preparation_succeed() {
        let mut obs = Mock::default();
        let outcome = toggle(&mut obs, |obs| {
            obs.request("SetSceneItemTransform", json!({}))?;
            obs.request("SetCurrentProgramScene", json!({}))?;
            Ok(Selection::FocusedIframe)
        })
        .unwrap();
        assert_eq!(outcome, Outcome::Started(Selection::FocusedIframe));
        assert_eq!(
            obs.calls,
            [
                "GetRecordStatus",
                "SetSceneItemTransform",
                "SetCurrentProgramScene",
                "GetRecordStatus",
                "StartRecord",
                "GetRecordStatus"
            ]
        );
        assert!(outcome.message().contains("whole focused iframe"));
    }

    #[test]
    fn probe_or_crop_failure_never_starts_recording() {
        let mut obs = Mock::default();
        assert!(toggle(&mut obs, |_| bail!("crop failed")).is_err());
        assert_eq!(obs.calls, ["GetRecordStatus"]);
    }

    #[test]
    fn unknown_status_never_probes_or_starts() {
        let mut obs = Mock {
            bad_status: true,
            ..Mock::default()
        };
        assert!(toggle(&mut obs, |_| panic!("invalid status")).is_err());
        assert_eq!(obs.calls, ["GetRecordStatus"]);
    }

    #[test]
    fn concurrent_manual_start_is_not_toggled_off_or_started_again() {
        let mut obs = Mock::default();
        let result = toggle(&mut obs, |obs| {
            obs.active = true;
            Ok(Selection::Video)
        });
        assert!(result.is_err());
        assert!(obs.active);
        assert_eq!(obs.calls, ["GetRecordStatus", "GetRecordStatus"]);
    }

    #[test]
    fn start_and_stop_failures_are_not_reported_as_success() {
        let mut obs = Mock {
            fail_start: true,
            ..Mock::default()
        };
        assert!(toggle(&mut obs, |_| Ok(Selection::Video)).is_err());
        assert!(!obs.active);
        let mut obs = Mock {
            active: true,
            fail_stop: true,
            ..Mock::default()
        };
        assert!(toggle(&mut obs, |_| panic!("must not prepare")).is_err());
        assert!(obs.active);
    }

    #[test]
    fn delayed_startup_is_confirmed() {
        let mut obs = Mock {
            startup_delay: 2,
            ..Mock::default()
        };
        assert_eq!(
            toggle(&mut obs, |_| Ok(Selection::Video)).unwrap(),
            Outcome::Started(Selection::Video)
        );
    }

    #[test]
    fn startup_timeout_does_not_attempt_to_stop_an_uncertain_output() {
        let mut obs = Mock {
            startup_delay: 100,
            ..Mock::default()
        };
        assert!(toggle(&mut obs, |_| Ok(Selection::Video)).is_err());
        assert!(!obs.calls.iter().any(|kind| kind == "StopRecord"));
    }

    #[test]
    fn missing_saved_path_does_not_hide_a_successful_stop() {
        let mut obs = Mock {
            active: true,
            path_missing: true,
            ..Mock::default()
        };
        let outcome = toggle(&mut obs, |_| panic!("must not prepare")).unwrap();
        assert_eq!(outcome, Outcome::Stopped(None));
        assert!(outcome.message().contains("Show Recordings"));
    }
}
