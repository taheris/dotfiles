use crate::{geometry::Target, obs::Api};
use anyhow::{Context, Result, ensure};
use serde_json::{Value, json};

fn items(obs: &mut impl Api, scene: &str) -> Result<Vec<Value>> {
    let result = obs.request("GetSceneItemList", json!({ "sceneName": scene }))?;
    Ok(result["sceneItems"]
        .as_array()
        .context("missing OBS scene items")?
        .clone())
}

/// Own one isolated scene/source. Never reconfigure arbitrary user captures.
pub fn apply(obs: &mut impl Api, target: &Target, scene: &str, source: &str) -> Result<()> {
    target.validate()?;
    ensure!(scene != source, "scene and source names must differ");
    let scenes = obs.request("GetSceneList", json!({}))?;
    let scenes = scenes["scenes"].as_array().context("missing OBS scenes")?;
    if !scenes.iter().any(|s| s["sceneName"] == scene) {
        obs.request("CreateScene", json!({ "sceneName": scene }))?;
    }
    let scene_items = items(obs, scene)?;
    ensure!(
        scene_items.len() <= 1
            && scene_items
                .iter()
                .all(|i| i["sourceName"] == source && i["isGroup"] != true),
        "managed scene {scene:?} contains other sources; use an empty, dedicated scene"
    );
    let input_list = obs.request("GetInputList", json!({}))?;
    let inputs = input_list["inputs"]
        .as_array()
        .context("missing OBS inputs")?;
    let existing = inputs.iter().find(|i| i["inputName"] == source);
    let item_id;
    if scene_items.is_empty() {
        ensure!(
            existing.is_none(),
            "source {source:?} already exists outside the managed scene; choose a unique source name"
        );
        let capture = target.capture.as_ref().context("external adapter must supply capture settings to create a source; otherwise preconfigure the managed scene/source")?;
        let created = obs.request(
            "CreateInput",
            json!({
                "sceneName": scene, "inputName": source, "inputKind": capture.input_kind,
                "inputSettings": capture.settings, "sceneItemEnabled": false
            }),
        )?;
        item_id = created["sceneItemId"]
            .as_u64()
            .context("missing scene item ID")?;
        // Do not accidentally mix all browser audio into a user's existing recording.
        obs.request(
            "SetInputMute",
            json!({ "inputName": source, "inputMuted": true }),
        )?;
    } else {
        item_id = scene_items[0]["sceneItemId"]
            .as_u64()
            .context("missing scene item ID")?;
        let input = existing.context("managed source is not a capture input")?;
        if let Some(capture) = &target.capture {
            ensure!(
                input["inputKind"] == capture.input_kind
                    || input["unversionedInputKind"] == capture.input_kind,
                "managed source has the wrong capture type"
            );
        }
        // Fail closed: source stays hidden if retargeting or geometry validation fails.
        obs.request(
            "SetSceneItemEnabled",
            json!({
                "sceneName": scene, "sceneItemId": item_id, "sceneItemEnabled": false
            }),
        )?;
        if let Some(capture) = &target.capture {
            obs.request(
                "SetInputSettings",
                json!({
                    "inputName": source, "inputSettings": capture.settings, "overlay": true
                }),
            )?;
        }
    }

    let mut crop = None;
    // ScreenCaptureKit initializes asynchronously. Wait for valid source dimensions.
    for attempt in 0..20 {
        if attempt > 0 {
            std::thread::sleep(std::time::Duration::from_millis(100));
        }
        let transform = obs.request(
            "GetSceneItemTransform",
            json!({
                "sceneName": scene, "sceneItemId": item_id
            }),
        )?;
        let t = &transform["sceneItemTransform"];
        if let (Some(w), Some(h)) = (t["sourceWidth"].as_f64(), t["sourceHeight"].as_f64())
            && w > 0.0
            && h > 0.0
        {
            crop = Some(target.crop(w, h)?);
            break;
        }
    }
    let crop =
        crop.context("capture has no frames; grant OBS Screen Recording permission and retry")?;
    let video = obs.request("GetVideoSettings", json!({}))?;
    let width = video["baseWidth"]
        .as_u64()
        .context("missing OBS canvas width")?;
    let height = video["baseHeight"]
        .as_u64()
        .context("missing OBS canvas height")?;
    obs.request(
        "SetSceneItemTransform",
        json!({
            "sceneName": scene, "sceneItemId": item_id,
            "sceneItemTransform": {
                "cropLeft": crop.left, "cropTop": crop.top,
                "cropRight": crop.right, "cropBottom": crop.bottom,
                "positionX": 0.0, "positionY": 0.0, "rotation": 0.0,
                "scaleX": 1.0, "scaleY": 1.0, "alignment": 5,
                "boundsType": "OBS_BOUNDS_SCALE_INNER", "boundsAlignment": 0,
                "boundsWidth": width, "boundsHeight": height
            }
        }),
    )?;
    obs.request(
        "SetSceneItemEnabled",
        json!({
            "sceneName": scene, "sceneItemId": item_id, "sceneItemEnabled": true
        }),
    )?;
    // Do not start/stop recording, streaming or the replay buffer.
    obs.request("SetCurrentProgramScene", json!({ "sceneName": scene }))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[derive(Default)]
    struct Mock {
        fresh: bool,
        calls: Vec<(String, Value)>,
        extra_source: bool,
        bad_size: bool,
    }
    impl Api for Mock {
        fn request(&mut self, kind: &str, data: Value) -> Result<Value> {
            self.calls.push((kind.to_owned(), data));
            Ok(match kind {
                "GetSceneList" if self.fresh => json!({ "scenes": [] }),
                "GetSceneList" => json!({ "scenes": [{ "sceneName": "Video Capture" }] }),
                "GetSceneItemList" if self.fresh => json!({ "sceneItems": [] }),
                "GetInputList" if self.fresh => json!({ "inputs": [] }),
                "CreateInput" => json!({ "sceneItemId": 1 }),
                "GetSceneItemList" => {
                    if self.extra_source {
                        json!({ "sceneItems": [{ "sourceName": "Private Desktop", "sceneItemId": 1 }] })
                    } else {
                        json!({ "sceneItems": [{ "sourceName": "Browser Video", "sceneItemId": 1 }] })
                    }
                }
                "GetInputList" => {
                    json!({ "inputs": [{ "inputName": "Browser Video", "inputKind": "screen_capture" }] })
                }
                "GetSceneItemTransform" => json!({ "sceneItemTransform": {
                    "sourceWidth": 2000, "sourceHeight": if self.bad_size { 1000 } else { 1600 }
                }}),
                "GetVideoSettings" => json!({ "baseWidth": 1920, "baseHeight": 1080 }),
                _ => json!({}),
            })
        }
    }
    fn target() -> Target {
        serde_json::from_value(json!({
            "window": { "x": 0, "y": 0, "width": 1000, "height": 800 },
            "viewport": { "x": 0, "y": 100, "width": 1000, "height": 700 },
            "video": { "x": 100, "y": 50, "width": 600, "height": 400 },
            "inner_width": 1000, "inner_height": 700,
            "capture": { "input_kind": "screen_capture", "settings": { "type": 1, "window": 42 } }
        }))
        .unwrap()
    }

    #[test]
    fn crops_before_revealing_and_never_records() {
        let mut mock = Mock {
            calls: vec![],
            ..Mock::default()
        };
        apply(&mut mock, &target(), "Video Capture", "Browser Video").unwrap();
        let crop_index = mock
            .calls
            .iter()
            .position(|(k, _)| k == "SetSceneItemTransform")
            .unwrap();
        let reveal_index = mock
            .calls
            .iter()
            .position(|(k, d)| k == "SetSceneItemEnabled" && d["sceneItemEnabled"] == true)
            .unwrap();
        assert!(crop_index < reveal_index);
        let t = &mock.calls[crop_index].1["sceneItemTransform"];
        assert_eq!(
            (t["cropLeft"].as_u64(), t["cropTop"].as_u64()),
            (Some(200), Some(300))
        );
        assert_eq!(mock.calls.last().unwrap().0, "SetCurrentProgramScene");
        assert!(
            !mock
                .calls
                .iter()
                .any(|(k, _)| k.contains("Record") || k.contains("Stream"))
        );
    }

    #[test]
    fn creates_hidden_muted_source_on_first_use() {
        let mut mock = Mock {
            fresh: true,
            ..Mock::default()
        };
        apply(&mut mock, &target(), "Video Capture", "Browser Video").unwrap();
        let created = mock.calls.iter().find(|(k, _)| k == "CreateInput").unwrap();
        assert_eq!(created.1["sceneItemEnabled"], false);
        assert_eq!(created.1["inputSettings"]["window"], 42);
        assert!(
            mock.calls
                .iter()
                .any(|(k, d)| k == "SetInputMute" && d["inputMuted"] == true)
        );
    }

    #[test]
    fn external_adapter_can_use_preconfigured_capture() {
        let mut mock = Mock::default();
        let mut target = target();
        target.capture = None;
        apply(&mut mock, &target, "Video Capture", "Browser Video").unwrap();
        assert!(
            !mock
                .calls
                .iter()
                .any(|(k, _)| k == "SetInputSettings" || k == "CreateInput")
        );
    }

    #[test]
    fn missing_external_capture_never_reveals_an_uncropped_source() {
        let mut mock = Mock {
            fresh: true,
            ..Mock::default()
        };
        let mut target = target();
        target.capture = None;
        assert!(apply(&mut mock, &target, "Video Capture", "Browser Video").is_err());
        assert!(
            !mock
                .calls
                .iter()
                .any(|(k, _)| k == "CreateInput" || k == "SetSceneItemEnabled")
        );
    }

    #[test]
    fn refuses_other_scene_contents_without_mutation() {
        let mut mock = Mock {
            calls: vec![],
            extra_source: true,
            ..Mock::default()
        };
        assert!(apply(&mut mock, &target(), "Video Capture", "Browser Video").is_err());
        assert!(mock.calls.iter().all(|(k, _)| k.starts_with("Get")));
    }

    #[test]
    fn failed_crop_keeps_source_hidden() {
        let mut mock = Mock {
            calls: vec![],
            bad_size: true,
            ..Mock::default()
        };
        assert!(apply(&mut mock, &target(), "Video Capture", "Browser Video").is_err());
        assert!(
            !mock
                .calls
                .iter()
                .any(|(k, d)| k == "SetSceneItemEnabled" && d["sceneItemEnabled"] == true)
        );
        assert!(
            !mock
                .calls
                .iter()
                .any(|(k, _)| k == "SetCurrentProgramScene")
        );
    }
}
