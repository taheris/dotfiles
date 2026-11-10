# OBS video crop

**Option+Fn** detects the largest playing, fully visible video in the frontmost
tab of the focused **Safari, Chromium (including ungoogled Chromium), or Google
Chrome** window, captures that
window, crops to the video, fits it into OBS's existing canvas, selects the
dedicated **Video Capture** scene, and **starts recording**. Press **Option+Fn
again to stop and save**, regardless of which app is focused. If no video is
playing when starting, it chooses the largest
loaded, fully visible video. Browser selection is automatic; it never falls back
to a browser running in the background.

If no video is accessible because the player is inside a cross-origin iframe,
**click inside that player, make the entire embed visible, then press Option+Fn**.
The fallback crops to that focused iframe's outer rectangle, not the video
inside it. Controls, borders, ads, and any other content inside the embed can be
included. It never guesses among unfocused frames. Accessible videos take
priority over this fallback. A successful fallback is reported in the log and,
when invoked by the shortcut, in a notification; `--probe` reports
`"selection": "focused-iframe"`.

OBS is opened in the background on macOS if its server is unreachable, with up
to 20 seconds allowed for startup. If OBS's first window still takes focus, the
helper restores the browser selected before launch, but only if OBS took the
foreground; it never overrides a switch to some other app. Restoration happens
only on the start/crop path, not when stopping an existing recording.
WebSocket authentication must be configured
once in OBS; the helper does not alter security settings or retry bad passwords.
It does not start/stop streaming, the replay buffer, or Hex. Plain Fn and
Shift+Fn keep their Hex bindings. Website playback is not started automatically:
press Play in the browser before recording.

Selection is one-shot, not continuous tracking. Stop before scrolling, resizing,
changing tabs or videos; select the new region on the next recording. Moving
the captured window without changing its layout does not need a recrop.
`obs-video-crop --crop-only` preserves the old select/crop-only behavior without
changing recording state. `--probe` prints geometry without contacting or
launching OBS. These flags are mutually exclusive.

## Recording and saving

The default command checks OBS recording status **before probing the browser**.
Any active recording, including one started manually or currently paused, is
stopped and saved without probing or retargeting the browser. After saving, the
helper removes its dedicated macOS capture input to end ScreenCaptureKit sharing;
the next start creates a fresh input. It does not remove unrelated sources,
sources shared into other scenes, or captures needed by an active output
(stream, replay buffer, virtual camera, etc.). Those cases produce a warning
while preserving the successful save. Other OBS/Hex captures may independently
keep macOS's capture indicator visible.

When idle, recording starts only after selecting and configuring the crop
successfully. Starts/stops and capture-release status are reported in
notifications and the log.

Files use **OBS → Settings → Output → Recording → Recording Path**, format,
and quality settings; use **File → Show Recordings** to open that folder.
The stop notification/log reports the output path returned by OBS.
[OBS acknowledges StopRecord before the output actually stops](https://github.com/obsproject/obs-websocket/blob/master/src/requesthandler/RequestHandler_Record.cpp).
The helper polls the actual recording output state for up to two minutes before
reporting a saved file and removing the capture source. If confirmation fails,
it reports the output path without claiming completion or tearing down a
possibly active capture. Wait for finalization before pressing the shortcut
again.
MOV is fine for Mac workflows; for portable clips prefer Hybrid MP4 if offered,
or MKV with OBS's automatic remux to MP4. The helper leaves the recording format,
encoder, and quality settings unchanged.

Use **Option+Fn** to stop/save and release the helper's capture together.
**Stop Recording in OBS** finalizes the file but does not run the helper's
source cleanup; remove Browser Video manually if sharing should end afterward.
The macOS menu-bar capture Stop button instead terminates capture but can leave
OBS recording a frozen/black source. Option+Fn can still stop/save that recording
without a working browser probe, release its source, and recreate it next time.

## First use on macOS

The Darwin aspect installs OBS through Homebrew and the Rust helper through Home
Manager.

1. Open OBS. In **Tools → WebSocket Server Settings**, enable the server with
   authentication on the default port **4455**. Apply/save the settings. The
   helper reads the saved password from OBS's local configuration; no secret
   belongs in Nix or the repository.
2. Enable scripting in each browser you want to use:
   - **Safari:** enable the Develop menu (Settings → Advanced → Show features for
     web developers), then **Develop → Allow JavaScript from Apple Events**.
   - **Chromium / Google Chrome:** **View → Developer → Allow JavaScript from
     Apple Events**.
3. For setup, run `sleep 3; obs-video-crop --probe` and switch to the browser
   within three seconds. Grant the invoking Terminal/Karabiner process
   Automation access to the browser and System Events, plus Accessibility.
   Each browser and invoking app needs its own permissions.
4. To inspect the preview without recording, use
   `sleep 3; obs-video-crop --crop-only` and switch to the browser. Grant OBS
   Screen Recording permission if requested, then retry.
5. Play the video, make it fully visible, and press **Option+Fn** to start.
   Press it again to stop/save; verify the reported recording in a video player.

The helper owns scene **Video Capture** and source **Browser Video**. It creates
them when missing and refuses a managed scene containing unrelated sources
before starting a recording.
Do not reuse that source elsewhere or add crop/transform filters to it. The
macOS source is temporary: per-source volume/filter edits do not persist after
it is removed on stop. OBS's output settings and the dedicated scene remain.
Retargeting hides the source before updating its capture and crop. A failure
after that point leaves it hidden rather than revealing an uncropped window.

New preview sources start muted, but **starting a recording automatically
unmutes the managed macOS capture source**, including one created by an older
version. `--crop-only` leaves an existing source's mute state unchanged.
Window cropping does not isolate the video element's audio: other tabs in the
same browser may be audible too, so mute them if needed. The helper does not
enable microphones or change global OBS audio inputs; disable any already
enabled Mic/Aux input yourself if it should not be recorded. External Linux
adapters retain their manually configured audio routing.

OBS canvas/output dimensions are not changed: a different aspect ratio produces
letterboxing, not webpage pixels. Player controls, subtitles, popups and other
page content drawn over the selected rectangle can still appear.

The shortcut logs to `~/Library/Logs/obs-video-crop/crop.log` and displays start,
saved-path, and error notifications through `terminal-notifier`, without click actions or Script Editor
launches. Allow its notifications in macOS settings if prompted. `--probe`
prints only geometry and capture identity, without
contacting OBS. Invocation locking prevents overlapping crop operations.
The lock and OBS connection are released before dispatching notifications
asynchronously. The helper does not wait for notification authorization or
delivery, so a prompt cannot hold the shortcut process open and block the next
recording toggle.

Browser probes write `obs-video-crop probe phase: ...` progress lines to the log
as they run. The 20-second timeout reports the last stage instead of assuming a
permissions problem, and kills/reaps the probe. Both output pipes are drained
concurrently so diagnostics cannot fill a pipe and stall the helper. Browser
windows are pinned by scripting ID; Accessibility windows are re-resolved after
waits, and transient invalid-index elements get a bounded retry. Native toolbar,
bookmark/sidebar, and leaf controls are not recursively inspected; groups and
tab groups containing the page remain eligible. If it still stalls, include the
last phase and latest error from the log rather than repeatedly granting broader
permissions.

Browser identity comes from macOS's native `NSWorkspace.frontmostApplication`,
then Accessibility lookup uses that exact process ID. Unsupported-app and
Accessibility errors include the detected app name, bundle ID, and PID so a
focus problem is distinguishable from a permissions problem. Viewport-selection
errors also include a bounded `Viewport diagnostics` JSON object: CSS dimensions,
native candidate rectangles, role counts, and traversal-limit status. This uses
the shortcut's existing permissions and collects no page text, titles, or URLs.
If detection still fails, include the latest full error from `crop.log`; do not
run `--probe` from a focused terminal and expect it to inspect a background
browser. Close docked DevTools before reproducing a layout problem.

If Chromium exposes only its toolbar/tabs and no webpage Accessibility tree,
the helper requests `AXEnhancedUserInterface` once and polls for up to four
seconds. Chromium [debounces this activation for two seconds](https://chromium.googlesource.com/chromium/src/+/main/chrome/browser/chrome_browser_application_mac.mm)
before exposing its renderer tree. Keep the browser focused and its window
still during this first attempt. The page geometry is read again after waiting.
This does not enable macOS VoiceOver. Chromium's Accessibility mode may remain
enabled for the running browser; the helper never disables it or another
assistive client's request. Failure diagnostics include the activation result
and retry count. If a build rejects the request, `chrome://accessibility` can
be used to enable its native Accessibility support manually.

## Configuration

Optional `${XDG_CONFIG_HOME:-~/.config}/obs-video-crop/config.json`:

```json
{
  "port": 4455,
  "password_file": "/Users/shaun/.config/obs-video-crop/password",
  "scene": "Video Capture",
  "source": "Browser Video"
}
```

All fields are optional. Omit `password_file` to reuse OBS's saved local
password. When supplied, it must be an absolute path to a private plaintext
file (e.g. mode 0600); a trailing newline is ignored. Connection is restricted
to IPv4 loopback. If you change OBS's port, set the same port here.

## Scope and limitations

- HTML5 videos in the top document, open shadow roots, and accessible
  same-origin frames are supported. Cross-origin iframe players can use the
  explicitly focused whole-frame fallback above. Inspecting the exact video
  bounds inside them still needs a browser extension with frame permissions;
  Apple Events JavaScript cannot bypass the browser's same-origin policy.
- Partly offscreen, unloaded, hidden, rotated/skewed videos are excluded.
  Multiple videos are ranked by playing state, then area.
- The adapter first matches the selected scriptable browser window's bounds
  to the corresponding Accessibility window, ignoring floating utility controls
  and unrelated native windows. It then uses Safari's native scroll viewport
  or Chromium's clipped root web-area bounds plus the matching Core Graphics
  window ID. It refuses ambiguity rather than guessing toolbar/sidebar offsets.
  Unusual browser layouts or unavailable Accessibility trees may therefore fail.
- Supported app bundle IDs are `com.apple.Safari`, `org.chromium.Chromium`,
  `io.ungoogled-software.ungoogled-chromium`, and `com.google.Chrome`. Other
  Chromium forks/channels are not implicitly allowed.
- This is pixel capture, not media extraction or DRM circumvention. Protected
  content may record black. DOM geometry cannot guarantee a region is free of
  page overlays or unusual CSS clipping.
- UI/browser/OBS integration needs a live macOS smoke test; mocked tests do not
  establish compatibility with every Safari or Chromium version.

## Linux boundary

The Rust OBS client, geometry mapping, and scene management are platform-neutral.
Automatic detection is currently macOS-only (Safari, Chromium, Google Chrome).
A future browser extension
and niri/Wayland adapter can supply a target with:

```sh
obs-video-crop --target /path/to/target.json
```

The JSON schema is the serializable `Target` in `src/geometry.rs`:
`window` and `viewport` are desktop logical rectangles; `video` is relative
to the page viewport in CSS pixels; `inner_width/inner_height` describe that
CSS viewport. `selection` is `video` (the default for older adapters) or
`focused-iframe`; the `video` rectangle denotes the selected region in either
case. `capture` optionally supplies OBS `input_kind` and `settings`.
With `capture: null`, preconfigure the sole source in the managed scene to the
correct window (e.g. through the Wayland portal). There is no Linux automatic
detection or Linux hotkey yet. Start OBS manually on Linux; automatic OBS
launch is currently macOS-only. The shared recording toggle works with the
external geometry adapter.

## Verify

```sh
cargo test
node --test tests/*.test.cjs
nix build .#obs-video-crop
```

The Nix package runs both test suites. Live macOS smoke test:

1. Open `tests/fixture.html` in Safari, Chromium, and Google Chrome; click Play
   and run the following checks with each browser focused in turn.
2. Run `--probe` and check the video/viewport/window rectangles.
3. Use `--crop-only` first to inspect the preview without recording. Press
   Option+Fn to start; verify the recording timer and the generated test picture.
   Switch to a non-browser app and press Option+Fn to stop/save. Check the
   reported output path and play the file in a video player. The helper-owned
   Browser Video source should disappear and its macOS sharing session should
   stop. Start again and verify the source is recreated with browser audio.
4. Repeat after page zoom, showing/hiding sidebars or bookmarks bars, resizing
   the window, scrolling, and moving it onto a display with a different scale
   factor. Keep Safari open in the background while testing Chromium and verify
   that only the focused Chromium window is captured. Also test immediately
   after restarting Chromium: the first crop may wait for its webpage
   Accessibility tree, while subsequent crops should not request it again.
5. Confirm ordinary Fn and Shift+Fn retain Hex behavior. A newly created
   preview source should be muted, but starting should unmute the macOS source;
   verify browser audio in both OBS's meter and the saved recording, including
   when reusing an older muted source. Verify a failed crop never starts
   recording; `--probe`
   and `--crop-only` leave recording state unchanged. Test a manually started
   or paused OBS recording: Option+Fn must stop it without probing the browser.
   Quit OBS and verify the next start restores the selected browser if OBS's
   first window steals focus. Manually switch to another app during launch and
   verify it is not overridden.
6. Put a second unrelated source into the managed scene and verify refusal;
   remove it and retry.
7. Open `tests/iframe-fixture.html`. Without clicking the embed, verify refusal
   instead of guessing a frame. Click the embedded player and press Option+Fn:
   expect its entire red child page (including the blue video and controls), but
   none of the gray parent page. Check the whole-iframe notification and
   `--probe` selection type. Scroll the iframe partly offscreen and verify
   refusal rather than an expanded crop.
