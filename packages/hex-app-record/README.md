# Hex app audio

On macOS 13+, Shift+Fn toggles transcription of the app that was frontmost
when recording started. Switching focus does not change the source. Browser
capture includes audio from all its tabs, not just the active tab. No microphone
or screen images are recorded. Fn remains Hex's dictation shortcut.

Requires Hex's `/streams` API and a loaded GGUF dictation model (not Apple
Speech). Grant `hex-app-record` Screen Recording permission when macOS asks;
ScreenCaptureKit requires this permission even for audio-only capture. A changed
Nix store executable may require granting permission again after an upgrade.

Press Shift+Fn again to finish, or use macOS's capture Stop button.
Markdown transcripts are saved under
`~/Documents/hex`; this explicit output is independent of Hex's disabled
dictation history. Notifications show start, completion, and failures. Diagnostic
output is in `~/Library/Caches/hex-app-record/record.log`. Audio is sent only to
Hex's authenticated loopback API and is not saved by this helper. One recording
can run at a time; a second shortcut press while finishing does not start another.

Capture, toggling, the Hex client, and transcript saving all run in one Swift
executable, with no Python runtime or capture subprocess. The Nix build runs
Swift tests for audio buffering, authenticated API requests, finish retries, and
cancellation. To run them directly on a Mac:

```sh
swiftc -parse-as-library Core.swift Tests.swift -o /tmp/hex-app-tests
/tmp/hex-app-tests
```

On a Mac, verify that a browser playing through headphones is transcribed,
that another app's audio and the microphone are excluded, that a second press
saves a transcript, and that Fn dictation still works during capture.
