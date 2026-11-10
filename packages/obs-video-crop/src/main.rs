mod apply;
mod capture;
mod geometry;
mod obs;
mod platform;
#[cfg(any(target_os = "macos", test))]
mod probe;
mod recording;

use anyhow::{Context, Result, bail, ensure};
use obs::Api;
use serde::Deserialize;
use std::{
    fs,
    path::{Path, PathBuf},
};

#[derive(Debug, Deserialize)]
#[serde(default, deny_unknown_fields)]
struct Config {
    port: u16,
    password_file: Option<PathBuf>,
    scene: String,
    source: String,
}
impl Default for Config {
    fn default() -> Self {
        Self {
            port: 4455,
            password_file: None,
            scene: "Video Capture".into(),
            source: "Browser Video".into(),
        }
    }
}

fn load_config(path: &Path) -> Result<Config> {
    match fs::read(path) {
        Ok(bytes) => serde_json::from_slice(&bytes).context("invalid obs-video-crop config"),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(Config::default()),
        Err(e) => Err(e).context("reading obs-video-crop config"),
    }
}

fn password(config: &Config, home: &Path) -> Result<Option<String>> {
    if let Some(path) = &config.password_file {
        ensure!(path.is_absolute(), "password_file must be an absolute path");
        return Ok(Some(
            fs::read_to_string(path)
                .context("reading OBS password file")?
                .trim_end_matches(['\r', '\n'])
                .to_owned(),
        ));
    }
    // Reuse OBS's locally saved secret rather than duplicating it in Nix/the store.
    let paths = [
        home.join("Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json"),
        home.join(".config/obs-studio/plugin_config/obs-websocket/config.json"),
        home.join(".var/app/com.obsproject.Studio/config/obs-studio/plugin_config/obs-websocket/config.json"),
    ];
    for path in paths {
        if path.exists() {
            let data: serde_json::Value = serde_json::from_slice(&fs::read(path)?)?;
            if let Some(secret) = data["server_password"].as_str() {
                return Ok(Some(secret.to_owned()));
            }
        }
    }
    Ok(None)
}

fn run() -> Result<Option<String>> {
    let mut target_file = None;
    let mut probe = false;
    let mut crop_only = false;
    let mut notify = false;
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--target" => {
                target_file = Some(PathBuf::from(
                    args.next().context("--target needs a JSON file path")?,
                ))
            }
            "--probe" => probe = true,
            "--crop-only" => crop_only = true,
            "--notify" => notify = true,
            "--help" | "-h" => {
                println!(
                    "obs-video-crop [--probe | --crop-only] [--target FILE] [--notify]\n\nToggle OBS recording: stop/save if recording; otherwise crop the focused browser video and start.\nIf no video is accessible, click a fully visible cross-origin player to capture its whole iframe.\nStopping never probes the browser. Files use OBS's configured Recording Path.\nOn macOS, OBS is opened in the background if its server is not reachable.\n--probe prints geometry without contacting OBS.\n--crop-only selects/crops without changing recording state.\n--target accepts geometry from an external adapter (including Linux)."
                );
                return Ok(None);
            }
            _ => bail!("unknown argument: {arg}"),
        }
    }
    ensure!(
        !(probe && crop_only),
        "--probe and --crop-only cannot be combined"
    );
    let home = PathBuf::from(std::env::var_os("HOME").context("HOME is not set")?);
    let config_dir = std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home.join(".config"))
        .join("obs-video-crop");
    fs::create_dir_all(&config_dir)?;
    let lock = fs::OpenOptions::new()
        .create(true)
        .truncate(false)
        .write(true)
        .open(config_dir.join("crop.lock"))?;
    lock.try_lock()
        .context("another obs-video-crop invocation is running")?;
    let detect_target = || -> Result<geometry::Target> {
        let target = match target_file.as_deref() {
            Some(path) => platform::from_file(path)?,
            None => platform::detect()?,
        };
        target.validate()?;
        Ok(target)
    };
    if probe {
        println!("{}", serde_json::to_string_pretty(&detect_target()?)?);
        return Ok(None);
    }
    let config = load_config(&config_dir.join("config.json"))?;
    let secret = password(&config, &home)?;
    let (mut client, focus_before_launch) = obs::connect_or_launch(config.port, secret.as_deref())?;
    let message = if crop_only {
        platform::restore_browser(focus_before_launch.as_ref())?;
        let target = detect_target()?;
        apply::apply(&mut client, &target, &config.scene, &config.source)?;
        let selection = match target.selection {
            geometry::Selection::Video => "video",
            geometry::Selection::FocusedIframe => {
                "whole focused iframe, including controls and other embedded content"
            }
        };
        format!(
            "Cropped {:?} to the {selection}; recording state unchanged.",
            config.scene
        )
    } else {
        let outcome = recording::toggle(&mut client, |obs| {
            // Never restore focus or inspect the browser on the stop path.
            platform::restore_browser(focus_before_launch.as_ref())?;
            let target = detect_target()?;
            apply::apply(obs, &target, &config.scene, &config.source)?;
            if target
                .capture
                .as_ref()
                .is_some_and(|capture| capture.input_kind == "screen_capture")
            {
                // Preview sources start muted. A recording explicitly requests
                // macOS capture audio; this also fixes previously created inputs.
                obs.request(
                    "SetInputMute",
                    serde_json::json!({
                        "inputName": config.source, "inputMuted": false
                    }),
                )?;
            }
            Ok(target.selection)
        })?;
        let mut message = outcome.message();
        if matches!(&outcome, recording::Outcome::Stopped(_)) {
            match capture::release(&mut client, &config.scene, &config.source) {
                Ok(true) => message.push_str("\nScreen capture stopped."),
                Ok(false) => (),
                // The file was saved successfully. Do not turn a teardown
                // problem into a misleading recording-stop failure.
                Err(error) => {
                    message.push_str(&format!("\nCould not release managed capture: {error:#}"))
                }
            }
        }
        message
    };
    println!("{message}");
    // Return before notifying: all OBS state changes are complete, and the
    // invocation lock/client must be dropped even if notifications need approval.
    Ok(notify.then_some(message))
}

fn main() {
    let notify = std::env::args().any(|a| a == "--notify");
    match run() {
        Ok(Some(message)) => platform::notify(&message),
        Ok(None) => (),
        Err(error) => {
            eprintln!("obs-video-crop: {error:#}");
            if notify {
                platform::notify(&format!("{error:#}"));
            }
            std::process::exit(1);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn config_defaults_and_unknown_options() {
        let config: Config = serde_json::from_str("{}").unwrap();
        assert_eq!(config.port, 4455);
        assert_eq!(config.scene, "Video Capture");
        assert!(serde_json::from_str::<Config>(r#"{"pasword_file":"typo"}"#).is_err());
    }
}
