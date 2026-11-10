const { test } = require("node:test");
const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const script = readFileSync(path.join(__dirname, "../src/focus.js"), "utf8");
const chromium = { pid: 123, bundle: "io.ungoogled-software.ungoogled-chromium" };
const obs = { pid: 456, bundle: "com.obsproject.obs-studio" };

function invoke(action, {
    foreground = obs, remembered = chromium, originalBundle = chromium.bundle,
    activationSucceeds = true, activationDelay = 0, neverActivates = false,
    userSwitches = false
} = {}) {
    let front = { ...foreground }, activated = 0, waited = 0;
    const context = {
        ObjC: { import: () => {}, unwrap: value => value },
        $: {
            NSWorkspace: { sharedWorkspace: {
                get frontmostApplication() {
                    return { processIdentifier: front.pid, bundleIdentifier: front.bundle };
                }
            } },
            NSApplicationActivateIgnoringOtherApps: 2,
            NSRunningApplication: {
                runningApplicationWithProcessIdentifier(pid) {
                    assert.equal(pid, remembered.pid);
                    return {
                        bundleIdentifier: originalBundle,
                        activateWithOptions(options) {
                            assert.equal(options, 2);
                            activated++;
                            if (activationSucceeds && activationDelay === 0 && !neverActivates)
                                front = { ...remembered };
                            return activationSucceeds;
                        }
                    };
                }
            }
        },
        delay(seconds) {
            assert.equal(seconds, 0.05);
            waited++;
            if (userSwitches) front = { pid: 789, bundle: "com.apple.Terminal" };
            else if (activated && !neverActivates && waited >= activationDelay)
                front = { ...remembered };
        }
    };
    const value = vm.runInNewContext(script + "\nrun(" + JSON.stringify([
        action, JSON.stringify(remembered)
    ]) + ");", context);
    return { value, activated, waited };
}

test("remember snapshots each supported browser, not OBS or another app", () => {
    for (const bundle of ["com.apple.Safari", "org.chromium.Chromium", chromium.bundle, "com.google.Chrome"]) {
        assert.deepEqual(JSON.parse(invoke("remember", { foreground: { pid: 123, bundle } }).value), { pid: 123, bundle });
    }
    assert.equal(JSON.parse(invoke("remember").value), null);
    assert.equal(JSON.parse(invoke("remember", { foreground: { pid: 789, bundle: "com.apple.Terminal" } }).value), null);
});
test("OBS stealing startup focus restores the exact original browser", () => {
    const result = invoke("restore");
    assert.equal(result.value, "restored");
    assert.equal(result.activated, 1);
});
test("an unchanged browser is not activated again", () => {
    const result = invoke("restore", { foreground: chromium });
    assert.equal(result.value, "unchanged");
    assert.equal(result.activated, 0);
});
test("a user switching to another app is never overridden", () => {
    assert.throws(() => invoke("restore", { foreground: { pid: 789, bundle: "com.apple.Terminal" } }), /Focus changed to another app/);
});
test("a terminated browser or reused PID is not activated", () => {
    assert.throws(() => invoke("restore", { originalBundle: "other.app" }), /original browser is no longer running/);
});
test("restoration waits for asynchronous foreground activation", () => {
    const result = invoke("restore", { activationDelay: 3 });
    assert.equal(result.value, "restored");
    assert.equal(result.waited, 4);
});
test("activation refusal and timeout have explicit errors", () => {
    assert.throws(() => invoke("restore", { activationSucceeds: false }), /Could not restore/);
    assert.throws(() => invoke("restore", { neverActivates: true }), /Timed out restoring/);
});
test("a user focus change during restoration is not repeatedly overridden", () => {
    assert.throws(() => invoke("restore", { activationDelay: 3, userSwitches: true }), /Focus changed while restoring/);
});
