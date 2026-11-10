use anyhow::{Result, ensure};
use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
pub struct Rect {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

impl Rect {
    fn validate(self) -> Result<()> {
        ensure!(
            [self.x, self.y, self.width, self.height]
                .iter()
                .all(|v| v.is_finite())
                && self.width > 0.0
                && self.height > 0.0,
            "invalid rectangle"
        );
        Ok(())
    }

    fn contains(self, other: Self) -> bool {
        other.x >= self.x - 1.0
            && other.y >= self.y - 1.0
            && other.x + other.width <= self.x + self.width + 1.0
            && other.y + other.height <= self.y + self.height + 1.0
    }
}

/// Coordinates are logical desktop units, except video/inner_* which are CSS pixels.
/// A future Linux browser/compositor adapter can emit exactly this format.
#[derive(Clone, Copy, Debug, Default, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "kebab-case")]
pub enum Selection {
    #[default]
    Video,
    FocusedIframe,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Target {
    pub window: Rect,
    pub viewport: Rect,
    pub video: Rect,
    pub inner_width: f64,
    pub inner_height: f64,
    pub capture: Option<Capture>,
    #[serde(default)]
    pub selection: Selection,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Capture {
    pub input_kind: String,
    pub settings: Value,
}

#[derive(Debug, PartialEq)]
pub struct Crop {
    pub left: u32,
    pub top: u32,
    pub right: u32,
    pub bottom: u32,
}

impl Target {
    pub fn validate(&self) -> Result<()> {
        self.window.validate()?;
        self.viewport.validate()?;
        self.video.validate()?;
        ensure!(
            self.window.contains(self.viewport),
            "browser viewport lies outside its window"
        );
        let css = Rect {
            x: 0.0,
            y: 0.0,
            width: self.inner_width,
            height: self.inner_height,
        };
        css.validate()?;
        ensure!(
            css.contains(self.video),
            "video is partly offscreen; scroll it fully into view"
        );
        let sx = self.viewport.width / self.inner_width;
        let sy = self.viewport.height / self.inner_height;
        ensure!(
            (sx / sy - 1.0).abs() < 0.025,
            "viewport geometry is inconsistent; refusing an uncertain crop"
        );
        Ok(())
    }

    pub fn crop(&self, width: f64, height: f64) -> Result<Crop> {
        self.validate()?;
        ensure!(
            width.is_finite() && height.is_finite() && width > 0.0 && height > 0.0,
            "OBS capture is not ready"
        );
        let sx = width / self.window.width;
        let sy = height / self.window.height;
        ensure!(
            (sx / sy - 1.0).abs() < 0.025,
            "OBS source does not match the browser window aspect ratio"
        );
        let x = (self.viewport.x - self.window.x
            + self.video.x * self.viewport.width / self.inner_width)
            * sx;
        let y = (self.viewport.y - self.window.y
            + self.video.y * self.viewport.height / self.inner_height)
            * sy;
        let w = self.video.width * self.viewport.width / self.inner_width * sx;
        let h = self.video.height * self.viewport.height / self.inner_height * sy;
        // Round inward: do not leak adjacent page pixels at fractional boundaries.
        let left = x.max(0.0).ceil();
        let top = y.max(0.0).ceil();
        let end_x = (x + w).min(width).floor();
        let end_y = (y + h).min(height).floor();
        ensure!(end_x > left && end_y > top, "video crop is empty");
        Ok(Crop {
            left: left as u32,
            top: top as u32,
            right: (width - end_x).max(0.0).ceil() as u32,
            bottom: (height - end_y).max(0.0).ceil() as u32,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn target() -> Target {
        Target {
            window: Rect {
                x: -1200.0,
                y: 50.0,
                width: 1000.0,
                height: 800.0,
            },
            viewport: Rect {
                x: -1000.0,
                y: 150.0,
                width: 800.0,
                height: 700.0,
            },
            video: Rect {
                x: 100.0,
                y: 50.0,
                width: 600.0,
                height: 400.0,
            },
            inner_width: 800.0,
            inner_height: 700.0,
            capture: None,
            selection: Selection::Video,
        }
    }

    #[test]
    fn retina_sidebar_and_negative_monitor_coordinates() {
        assert_eq!(
            target().crop(2000.0, 1600.0).unwrap(),
            Crop {
                left: 600,
                top: 300,
                right: 200,
                bottom: 500
            }
        );
    }

    #[test]
    fn browser_zoom() {
        let mut t = target();
        t.inner_width /= 1.5;
        t.inner_height /= 1.5;
        t.video.x /= 1.5;
        t.video.y /= 1.5;
        t.video.width /= 1.5;
        t.video.height /= 1.5;
        assert_eq!(
            t.crop(2000.0, 1600.0).unwrap(),
            target().crop(2000.0, 1600.0).unwrap()
        );
    }

    #[test]
    fn rejects_partial_invalid_and_mismatched_geometry() {
        let mut t = target();
        t.video.x = -30.0;
        assert!(t.validate().is_err());
        t = target();
        t.video.width = f64::NAN;
        assert!(t.validate().is_err());
        assert!(target().crop(1000.0, 1000.0).is_err());
        t = target();
        t.viewport.height -= 200.0;
        assert!(t.validate().is_err());
    }

    #[test]
    fn selection_round_trip_and_legacy_adapter_compatibility() {
        let mut value = serde_json::to_value(target()).unwrap();
        value.as_object_mut().unwrap().remove("selection");
        let legacy: Target = serde_json::from_value(value.clone()).unwrap();
        assert_eq!(legacy.selection, Selection::Video);
        value["selection"] = "focused-iframe".into();
        let frame: Target = serde_json::from_value(value.clone()).unwrap();
        assert_eq!(frame.selection, Selection::FocusedIframe);
        assert_eq!(
            frame.crop(2000.0, 1600.0).unwrap(),
            legacy.crop(2000.0, 1600.0).unwrap()
        );
        assert_eq!(
            serde_json::to_value(frame).unwrap()["selection"],
            "focused-iframe"
        );
        value["selection"] = "arbitrary-selection".into();
        assert!(serde_json::from_value::<Target>(value).is_err());
    }

    #[test]
    fn rounds_inward() {
        let mut t = target();
        t.video.x = 100.25;
        t.video.width = 599.5;
        let c = t.crop(2000.0, 1600.0).unwrap();
        assert_eq!((c.left, c.right), (601, 201));
    }
}
