use crate::obs::Api;
use anyhow::{Context, Result, ensure};
use serde_json::json;

fn is_referenced(
    obs: &mut impl Api,
    scene: &str,
    source: &str,
    group: bool,
    depth: usize,
) -> Result<bool> {
    ensure!(
        depth <= 8,
        "cannot safely inspect deeply nested capture references"
    );
    let response = obs.request(
        if group {
            "GetGroupSceneItemList"
        } else {
            "GetSceneItemList"
        },
        json!({ "sceneName": scene }),
    )?;
    let items = response["sceneItems"]
        .as_array()
        .context("missing OBS scene items")?;
    for item in items {
        let name = item["sourceName"]
            .as_str()
            .context("missing OBS source name")?;
        if name == source {
            return Ok(true);
        }
        if item["isGroup"] == true && is_referenced(obs, name, source, true, depth + 1)? {
            return Ok(true);
        }
    }
    Ok(false)
}

/// ScreenCaptureKit keeps streaming even when a scene item is hidden. Destroy
/// only our dedicated macOS capture input after the recording has finalized.
pub fn release(obs: &mut impl Api, scene: &str, source: &str) -> Result<bool> {
    let response = obs.request("GetSceneList", json!({}))?;
    let scenes = response["scenes"]
        .as_array()
        .context("missing OBS scenes")?;
    if !scenes.iter().any(|item| item["sceneName"] == scene) {
        return Ok(false);
    }
    let response = obs.request("GetSceneItemList", json!({ "sceneName": scene }))?;
    let items = response["sceneItems"]
        .as_array()
        .context("missing OBS scene items")?;
    if !items.iter().any(|item| item["sourceName"] == source) {
        return Ok(false);
    }
    ensure!(
        items.len() == 1 && items[0]["isGroup"] != true,
        "managed scene contains other sources; not removing its capture automatically"
    );

    let response = obs.request("GetInputList", json!({}))?;
    let inputs = response["inputs"]
        .as_array()
        .context("missing OBS inputs")?;
    let Some(input) = inputs.iter().find(|item| item["inputName"] == source) else {
        return Ok(false);
    };
    if input["inputKind"] != "screen_capture" && input["unversionedInputKind"] != "screen_capture" {
        // Preserve externally configured portal/video inputs that this helper
        // cannot recreate from a fresh macOS browser probe.
        return Ok(false);
    }

    // Enumerate existing outputs: GetReplayBufferStatus can fail when the
    // replay buffer is disabled/unavailable. This also protects virtual cameras
    // and plugin outputs without changing any other output's state.
    let response = obs.request("GetOutputList", json!({}))?;
    for output in response["outputs"]
        .as_array()
        .context("missing OBS output list")?
    {
        let active = output["outputActive"]
            .as_bool()
            .context("missing OBS output status")?;
        ensure!(
            !active,
            "capture kept active because output {:?} is running",
            output["outputName"].as_str().unwrap_or("unknown")
        );
    }
    for item in scenes {
        let name = item["sceneName"]
            .as_str()
            .context("missing OBS scene name")?;
        if name != scene {
            ensure!(
                !is_referenced(obs, name, source, false, 0)?,
                "capture is referenced by another scene; not removing a shared source"
            );
        }
    }
    obs.request("RemoveInput", json!({ "inputName": source }))?;
    Ok(true)
}

#[cfg(test)]
mod tests {
    use super::*;
    use anyhow::bail;
    use serde_json::Value;

    #[derive(Default)]
    struct Mock {
        calls: Vec<(String, Value)>,
        no_scene: bool,
        no_source: bool,
        mixed_scene: bool,
        external_kind: bool,
        recording: bool,
        streaming: bool,
        replay: bool,
        other_scene: bool,
        shared: bool,
        shared_group: bool,
        fail_remove: bool,
        no_outputs: bool,
        invalid_output: bool,
    }
    impl Api for Mock {
        fn request(&mut self, kind: &str, data: Value) -> Result<Value> {
            self.calls.push((kind.into(), data.clone()));
            Ok(match kind {
                "GetSceneList" if self.no_scene => json!({ "scenes": [] }),
                "GetSceneList" if self.other_scene || self.shared || self.shared_group => json!({
                    "scenes": [{ "sceneName": "Video Capture" }, { "sceneName": "Other" }]
                }),
                "GetSceneList" => json!({ "scenes": [{ "sceneName": "Video Capture" }] }),
                "GetSceneItemList" if data["sceneName"] == "Other" => {
                    if self.shared {
                        json!({ "sceneItems": [{ "sourceName": "Browser Video" }] })
                    } else if self.shared_group {
                        json!({ "sceneItems": [{ "sourceName": "Group", "isGroup": true }] })
                    } else {
                        json!({ "sceneItems": [{ "sourceName": "Unrelated Capture" }] })
                    }
                }
                "GetGroupSceneItemList" => {
                    json!({ "sceneItems": [{ "sourceName": "Browser Video" }] })
                }
                "GetSceneItemList" if self.no_source => json!({ "sceneItems": [] }),
                "GetSceneItemList" if self.mixed_scene => json!({
                    "sceneItems": [{ "sourceName": "Browser Video" }, { "sourceName": "Unrelated Capture" }]
                }),
                "GetSceneItemList" => json!({ "sceneItems": [{ "sourceName": "Browser Video" }] }),
                "GetInputList" => json!({ "inputs": [{
                    "inputName": "Browser Video",
                    "inputKind": if self.external_kind { "pipewire-window-capture-source" } else { "screen_capture" }
                }] }),
                "GetOutputList" if self.no_outputs => json!({ "outputs": [] }),
                "GetOutputList" if self.invalid_output => {
                    json!({ "outputs": [{ "outputName": "unknown" }] })
                }
                "GetOutputList" => json!({ "outputs": [
                    { "outputName": "recording", "outputActive": self.recording },
                    { "outputName": "streaming", "outputActive": self.streaming },
                    { "outputName": "replay", "outputActive": self.replay }
                ] }),
                "RemoveInput" if self.fail_remove => bail!("remove failed"),
                "RemoveInput" => json!({}),
                _ => panic!("unexpected cleanup request: {kind}"),
            })
        }
    }

    fn removed(obs: &Mock) -> bool {
        obs.calls.iter().any(|(kind, _)| kind == "RemoveInput")
    }

    #[test]
    fn releases_only_the_owned_capture_input() {
        let mut obs = Mock {
            other_scene: true,
            ..Mock::default()
        };
        assert!(release(&mut obs, "Video Capture", "Browser Video").unwrap());
        assert_eq!(obs.calls.last().unwrap().0, "RemoveInput");
        assert_eq!(obs.calls.last().unwrap().1["inputName"], "Browser Video");
        assert!(
            !obs.calls
                .iter()
                .any(|(kind, _)| kind == "StopStream" || kind == "StopReplayBuffer")
        );
    }

    #[test]
    fn absent_or_externally_configured_sources_are_left_alone() {
        for mut obs in [
            Mock {
                no_scene: true,
                ..Mock::default()
            },
            Mock {
                no_source: true,
                ..Mock::default()
            },
            Mock {
                external_kind: true,
                ..Mock::default()
            },
        ] {
            assert!(!release(&mut obs, "Video Capture", "Browser Video").unwrap());
            assert!(!removed(&obs));
        }
    }

    #[test]
    fn active_outputs_preserve_capture() {
        for mut obs in [
            Mock {
                recording: true,
                ..Mock::default()
            },
            Mock {
                streaming: true,
                ..Mock::default()
            },
            Mock {
                replay: true,
                ..Mock::default()
            },
        ] {
            assert!(release(&mut obs, "Video Capture", "Browser Video").is_err());
            assert!(!removed(&obs));
        }
    }

    #[test]
    fn shared_grouped_or_modified_scene_capture_is_not_deleted() {
        for mut obs in [
            Mock {
                mixed_scene: true,
                ..Mock::default()
            },
            Mock {
                shared: true,
                ..Mock::default()
            },
            Mock {
                shared_group: true,
                ..Mock::default()
            },
        ] {
            assert!(release(&mut obs, "Video Capture", "Browser Video").is_err());
            assert!(!removed(&obs));
        }
    }

    #[test]
    fn unavailable_replay_buffer_does_not_block_releasing_capture() {
        let mut obs = Mock {
            no_outputs: true,
            ..Mock::default()
        };
        assert!(release(&mut obs, "Video Capture", "Browser Video").unwrap());
        assert!(
            !obs.calls
                .iter()
                .any(|(kind, _)| kind == "GetReplayBufferStatus")
        );
    }

    #[test]
    fn uncertain_output_state_preserves_capture() {
        let mut obs = Mock {
            invalid_output: true,
            ..Mock::default()
        };
        assert!(release(&mut obs, "Video Capture", "Browser Video").is_err());
        assert!(!removed(&obs));
    }

    #[test]
    fn removal_errors_are_propagated_for_a_saved_recording_warning() {
        let mut obs = Mock {
            fail_remove: true,
            ..Mock::default()
        };
        assert!(
            release(&mut obs, "Video Capture", "Browser Video")
                .unwrap_err()
                .to_string()
                .contains("remove failed")
        );
    }
}
