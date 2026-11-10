ObjC.import("AppKit");

function run(argv) {
    const workspace = $.NSWorkspace.sharedWorkspace;
    const current = workspace.frontmostApplication;
    const pid = Number(current.processIdentifier);
    const bundle = ObjC.unwrap(current.bundleIdentifier) || "";
    if (argv[0] === "remember") {
        const browsers = [
            "com.apple.Safari", "org.chromium.Chromium",
            "io.ungoogled-software.ungoogled-chromium", "com.google.Chrome"
        ];
        return JSON.stringify(browsers.includes(bundle) && pid > 0 ? { pid, bundle } : null);
    }
    if (argv[0] !== "restore") throw new Error("Invalid browser-focus operation.");
    const remembered = JSON.parse(argv[1]);
    if (pid === remembered.pid) return "unchanged";
    if (bundle !== "com.obsproject.obs-studio") {
        throw new Error("Focus changed to another app while OBS was starting; focus the browser and retry Option+Fn.");
    }
    const browser = $.NSRunningApplication.runningApplicationWithProcessIdentifier(remembered.pid);
    if (ObjC.unwrap(browser.bundleIdentifier) !== remembered.bundle) {
        throw new Error("The original browser is no longer running; focus a browser and retry Option+Fn.");
    }
    // open -g can still lose focus when OBS creates its first window. Restore
    // only the original browser, and only when OBS actually took the foreground.
    if (!browser.activateWithOptions($.NSApplicationActivateIgnoringOtherApps)) {
        throw new Error("Could not restore the selected browser after starting OBS.");
    }
    for (let attempt = 0; attempt < 40; attempt++) {
        const front = workspace.frontmostApplication;
        if (Number(front.processIdentifier) === remembered.pid) {
            delay(0.05); // Allow document focus (including focused iframes) to settle.
            return "restored";
        }
        if (ObjC.unwrap(front.bundleIdentifier) !== "com.obsproject.obs-studio") {
            throw new Error("Focus changed while restoring the browser; retry Option+Fn.");
        }
        delay(0.05);
    }
    throw new Error("Timed out restoring browser focus after starting OBS; retry Option+Fn.");
}
