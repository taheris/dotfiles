const { test } = require("node:test");
const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");
const detect = readFileSync(path.join(__dirname, "../src/detect.js"), "utf8");
const browser = readFileSync(path.join(__dirname, "../src/browser.js"), "utf8");

function document(elements = [], activeElement = null) {
    return {
        activeElement, hasFocus: () => true,
        querySelectorAll: () => elements,
        defaultView: { getComputedStyle: el => ({
            display: "block", visibility: "visible", opacity: "1", transform: "none", ...el.style
        }) }
    };
}
function element(tag, box, options = {}) {
    return {
        tagName: tag, ownerDocument: document(), parentElement: null,
        style: {}, getBoundingClientRect: () => box,
        readyState: 4, videoWidth: 1280, videoHeight: 720, paused: false, ended: false,
        checkVisibility: () => true, ...options
    };
}
function probe(elements, activeElement = null, focused = true) {
    const page = document(elements, activeElement);
    page.hasFocus = () => focused;
    return JSON.parse(vm.runInNewContext(detect, {
        document: page, innerWidth: 1000, innerHeight: 700,
        DOMMatrixReadOnly: class {
            constructor() { this.is2D = true; this.a = 1; this.b = 1; this.c = 0; this.d = 1; }
        }
    }));
}
const box = { x: 100, y: 50, width: 640, height: 360 };

test("prefers playing video, then largest area", () => {
    const paused = element("VIDEO", { x: 0, y: 0, width: 1000, height: 600 }, { paused: true });
    const small = element("VIDEO", { x: 0, y: 0, width: 100, height: 100 });
    assert.deepEqual(probe([paused, small, element("VIDEO", box)]).video, box);
});
test("rejects partially visible, hidden, unloaded and rotated videos", () => {
    for (const candidate of [
        element("VIDEO", { ...box, x: -10 }),
        element("VIDEO", box, { checkVisibility: () => false }),
        element("VIDEO", box, { readyState: 0 }),
        element("VIDEO", box, { style: { transform: "matrix(1,1,0,1,0,0)" } })
    ]) assert.throws(() => probe([candidate]), /No fully visible/);
});
test("open shadow roots are traversed", () => {
    const host = element("DIV", box, { shadowRoot: document([element("VIDEO", box)]) });
    assert.deepEqual(probe([host]).video, box);
});
test("same-origin iframe offsets, borders and CSS scaling", () => {
    const video = element("VIDEO", { x: 10, y: 20, width: 200, height: 100 });
    const frame = element("IFRAME", { x: 100, y: 100, width: 600, height: 400 }, {
        contentDocument: document([video]), offsetWidth: 300, offsetHeight: 200,
        clientLeft: 2, clientTop: 2
    });
    assert.deepEqual(probe([frame]).video, { x: 124, y: 144, width: 400, height: 200 });
});
test("visible video inside a partly offscreen iframe is still eligible", () => {
    const frame = element("IFRAME", { x: 0, y: -100, width: 1000, height: 900 }, {
        contentDocument: document([element("VIDEO", { x: 100, y: 150, width: 640, height: 360 })]),
        offsetWidth: 1000, offsetHeight: 900, clientLeft: 0, clientTop: 0
    });
    assert.deepEqual(probe([frame]).video, box);
});
test("reports inaccessible cross-origin players", () => {
    const frame = element("IFRAME", box, { contentDocument: null });
    assert.throws(() => probe([frame]), /cross-origin/);
});
test("focused inaccessible iframe fallback captures only the clicked embed", () => {
    const ad = element("IFRAME", { x: 0, y: 0, width: 80, height: 80 }, { contentDocument: null });
    const player = element("IFRAME", box, { contentDocument: null });
    const result = probe([ad, player], player);
    assert.deepEqual(result.video, box);
    assert.equal(result.selection, "focused-iframe");
});
test("iframe access exceptions use the same explicit-focus fallback", () => {
    const player = element("IFRAME", box);
    Object.defineProperty(player, "contentDocument", { get() { throw new Error("SecurityError"); } });
    assert.equal(probe([player], player).selection, "focused-iframe");
});
test("fallback requires the page itself to retain focus", () => {
    const player = element("IFRAME", box, { contentDocument: null });
    assert.throws(() => probe([player], player, false), /Click inside.*entire iframe/);
});
test("fallback never chooses an unfocused iframe even when there is only one", () => {
    const player = element("IFRAME", box, { contentDocument: null });
    assert.throws(() => probe([player]), /Click inside.*entire iframe/);
});
test("fallback rejects partially visible, hidden and rotated frames", () => {
    for (const player of [
        element("IFRAME", { ...box, x: -10 }, { contentDocument: null }),
        element("IFRAME", box, { contentDocument: null, checkVisibility: () => false }),
        element("IFRAME", box, { contentDocument: null, style: { transform: "matrix(1,1,0,1,0,0)" } })
    ]) assert.throws(() => probe([player], player));
});
test("accessible videos retain priority over the iframe fallback", () => {
    const player = element("IFRAME", box, { contentDocument: null });
    const videoBox = { x: 20, y: 20, width: 200, height: 100 };
    const result = probe([player, element("VIDEO", videoBox)], player);
    assert.deepEqual(result.video, videoBox);
    assert.equal(result.selection, "video");
});
function nestedFrame() {
    const player = element("IFRAME", { x: 10, y: 20, width: 200, height: 100 },
        { contentDocument: null });
    const outer = element("IFRAME", { x: 100, y: 100, width: 600, height: 400 }, {
        contentDocument: document([player], player), offsetWidth: 300, offsetHeight: 200,
        clientLeft: 2, clientTop: 2
    });
    return { player, outer };
}
test("nested same-origin focus chains preserve border and scaling offsets", () => {
    const { outer } = nestedFrame();
    const result = probe([outer], outer);
    assert.deepEqual(result.video, { x: 124, y: 144, width: 400, height: 200 });
    assert.equal(result.selection, "focused-iframe");
});
test("stale focus inside a background same-origin frame cannot select its embed", () => {
    const { outer } = nestedFrame();
    assert.throws(() => probe([outer]), /Click inside/);
});
test("nested fallback requires full visibility within the ancestor iframe", () => {
    const { player, outer } = nestedFrame();
    player.getBoundingClientRect = () => ({ x: 250, y: 20, width: 200, height: 100 });
    assert.throws(() => probe([outer], outer), /Click inside/);
});
test("open shadow-root focus chains can select an embedded player", () => {
    const player = element("IFRAME", box, { contentDocument: null });
    const host = element("DIV", box, { shadowRoot: document([player], player) });
    assert.equal(probe([host], host).selection, "focused-iframe");
    assert.throws(() => probe([host]), /Click inside/);
});
test("ambiguous focused frames are never guessed", () => {
    const player = element("IFRAME", box, { contentDocument: null });
    assert.throws(() => probe([player, player], player), /Click inside/);
});
test("returns only geometry and selection type, never page metadata", () => {
    assert.deepEqual(Object.keys(probe([element("VIDEO", box)])).sort(),
        ["inner_height", "inner_width", "selection", "video"]);
});

function browserProbe({
    bundle = "com.apple.Safari", extraViewport = false, frontmost = true,
    captureMatches = true, noWindow = false, badViewport = false,
    scrollWrapper = true, scriptError = false, processMatches = true, noNativeWindow = false,
    invalidWindowList = false, missingWebArea = false, depthChain = 0,
    nullProbeResponse = false, malformedProbeResponse = false,
    pageProbeError = false, invalidProbeGeometry = false,
    realDetector = false, noPageVideos = false, focusedEmbed = false,
    lazyAccessibility = false, activationFails = false, activationReadFails = false,
    accessibilityAlreadyEnabled = false, neverExposesWebArea = false,
    moveWindowWhileWaiting = false, changeFocusWhileWaiting = false,
    changePageWhileWaiting = false, onActivate = () => {}, onWait = () => {},
    onProbe = () => {}, floatingWindowFirst = false, onlyFloatingWindow = false,
    duplicateDocumentWindow = false, unreadableWindowFirst = false,
    arrayWindowBounds = false, invalidWindowBounds = false,
    nativeRefsExpireAfterWait = false, indexedScriptWindowStale = false,
    staleWebAreaOnce = false, chromeToolbar = false, pageInTabGroup = false,
    onPhase = () => {}
} = {}) {
    const isSafari = bundle === "com.apple.Safari";
    const viewport = { x: 200, y: 120, width: 1000, height: badViewport ? 300 : 700 };
    const nativeBounds = {
        position: () => [viewport.x, viewport.y], size: () => [viewport.width, viewport.height]
    };
    let webRoleReads = 0;
    const web = { role: () => {
        if (staleWebAreaOnce && webRoleReads++ === 0) throw new Error("Invalid index. (-1719)");
        return "AXWebArea";
    },
        uiElements: () => { throw new Error("must not traverse webpage"); },
        // Safari's web area can be document-sized; never use it as the viewport.
        ...nativeBounds, size: () => isSafari ? [1000, 4000] : nativeBounds.size()
    };
    const scroll = { role: () => "AXScrollArea", uiElements: () => [web], ...nativeBounds };
    let root = missingWebArea ? { role: () => "AXGroup", uiElements: () => [] }
        : scrollWrapper ? scroll : web;
    if (pageInTabGroup) {
        const child = root;
        root = { role: () => "AXTabGroup", uiElements: () => [child] };
    }
    for (let i = 0; i < depthChain; i++) {
        const child = root;
        root = { role: () => "AXGroup", uiElements: () => [child] };
    }
    let accessibilityReady = !lazyAccessibility;
    let accessibilityEnabled = accessibilityAlreadyEnabled;
    let waits = 0, windowMoved = false, nativeEpoch = 0;
    const toolbar = { role: () => "AXToolbar", uiElements: () => { throw new Error("must not traverse native toolbar controls"); } };
    const sidebar = { role: () => "AXOutline", uiElements: () => { throw new Error("must not traverse bookmark/sidebar rows"); } };
    const emptyRoot = { role: () => "AXGroup", uiElements: () => [] };
    const window = { role: () => "AXWindow", uiElements: () =>
        !accessibilityReady ? [emptyRoot] : chromeToolbar ? [toolbar, sidebar, root] : extraViewport ? [root, root] : [root],
        position: () => [windowMoved ? 210 : 200, 20], size: () => [1000, 800] };
    const accessibilityAttribute = {};
    Object.defineProperty(accessibilityAttribute, "value", {
        get: () => () => {
            if (activationReadFails) throw new Error("attribute is write-only");
            return accessibilityEnabled;
        },
        set: value => {
            if (activationFails) throw new Error("activation denied");
            assert.equal(value, true, "must not disable another client's Accessibility");
            accessibilityEnabled = true;
            onActivate();
        }
    });
    const floating = { role: () => "AXWindow",
        position: () => [126, 102], size: () => [53, 48],
        uiElements: () => [{ role: () => "AXButton", uiElements: () => [] }] };
    const unreadable = { position: () => { throw new Error("window cannot be read"); } };
    function nativeWindowRef() {
        if (!nativeRefsExpireAfterWait) return window;
        const createdAt = nativeEpoch;
        const ref = {};
        for (const key of ["role", "uiElements", "position", "size"]) ref[key] = () => {
            if (createdAt !== nativeEpoch) throw new Error("Invalid index. (-1719)");
            return window[key]();
        };
        return ref;
    }
    const process = {
        windows: () => {
            const current = nativeWindowRef();
            return noNativeWindow ? [] : onlyFloatingWindow ? [floating] :
                unreadableWindowFirst ? [unreadable, current] :
                floatingWindowFirst ? [floating, current] :
                duplicateDocumentWindow ? [current, current] : [current];
        },
        attributes: { byName: name => {
            assert.equal(name, "AXEnhancedUserInterface");
            return accessibilityAttribute;
        } }
    };
    function scriptResult(source) {
        onProbe();
        if (scriptError) throw new Error("Allow JavaScript from Apple Events is disabled");
        if (nullProbeResponse) return null;
        if (malformedProbeResponse) return "not JSON";
        const currentBox = changePageWhileWaiting && accessibilityReady ? { ...box, x: 150 } : box;
        const frame = element("IFRAME", currentBox, { contentDocument: null });
        const page = {
            probe: invalidProbeGeometry ? "null" :
                JSON.stringify({ video: currentBox, inner_width: 1000, inner_height: 700 }),
            document: focusedEmbed ? document([frame], frame) :
                document(noPageVideos ? [] : [element("VIDEO", currentBox)]),
            innerWidth: 1000, innerHeight: 700
        };
        // Execute the real transport wrapper. An uncaught page exception would
        // otherwise be swallowed by Chromium's Apple Events execute command.
        return vm.runInNewContext(source, page);
    }
    const scriptWindow = isSafari
        ? { currentTab: () => "safari-tab" } : { activeTab: () => "chromium-tab" };
    scriptWindow.id = () => 77;
    scriptWindow.bounds = () => invalidWindowBounds ? null : arrayWindowBounds
        ? [windowMoved ? 210 : 200, 20, windowMoved ? 1210 : 1200, 820]
        : { x: windowMoved ? 210 : 200, y: 20, width: 1000, height: 800 };
    const staleScriptWindow = { id: () => 77 };
    for (const key of ["bounds", "currentTab", "activeTab"])
        staleScriptWindow[key] = () => { throw new Error("Invalid index. (-1719)"); };
    const app = { windows: () => noWindow ? [] : [indexedScriptWindowStale ? staleScriptWindow : scriptWindow] };
    app.windows.byId = id => {
        assert.equal(id, 77);
        return scriptWindow;
    };
    if (isSafari) {
        app.doJavaScript = (script, options) => {
            assert.ok(script.includes("value: JSON.parse(("));
            assert.equal(options.in, "safari-tab");
            return scriptResult(script);
        };
    } else {
        app.execute = (tab, options) => {
            assert.equal(tab, "chromium-tab");
            assert.ok(options.javascript.includes("value: JSON.parse(("));
            return scriptResult(options.javascript);
        };
    }
    const context = {
        console: { log: message => onPhase(message) },
        delay: seconds => {
            assert.ok(seconds === 0.25 || seconds === 0.05);
            nativeEpoch++;
            if (seconds === 0.25) {
                waits++;
                onWait();
            }
            if (accessibilityEnabled && !neverExposesWebArea && waits >= 8)
                accessibilityReady = true;
            if (moveWindowWhileWaiting) windowMoved = true;
            if (changeFocusWhileWaiting)
                context.$.NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier = 999;
        },
        ObjC: {
            import: () => {}, deepUnwrap: x => x, unwrap: x => x,
            castRefToObject: ref => {
                assert.equal(ref.type, "CFArrayRef");
                return ref.value;
            }
        },
        $: {
            NSWorkspace: { sharedWorkspace: { frontmostApplication: {
                bundleIdentifier: frontmost ? bundle : null,
                localizedName: "Test Browser", processIdentifier: frontmost ? 123 : 0
            } } },
            // Model the real opaque CFArrayRef, not an already-converted JS array.
            // Without castRefToObject, deepUnwrap returns this object unchanged.
            CGWindowListCopyWindowInfo: () => ({
                type: "CFArrayRef",
                value: invalidWindowList ? null : captureMatches ? [{
                    kCGWindowOwnerPID: 123, kCGWindowLayer: 0, kCGWindowNumber: 42,
                    kCGWindowBounds: { X: 200, Y: 20, Width: 1000, Height: 800 }
                }] : []
            })
        },
        Application: name => {
            if (name === "System Events") return {
                applicationProcesses: { whose: query => {
                    // A lazy JXA specifier, deliberately NOT an array. Only its
                    // evaluated result has a meaningful length. System Events'
                    // frontmost property is never used for browser selection.
                    assert.equal(query.unixId, 123);
                    assert.equal(query.frontmost, undefined);
                    return () => processMatches ? [process] : [];
                } }
            };
            assert.equal(name, bundle);
            assert.ok(["com.apple.Safari", "org.chromium.Chromium", "io.ungoogled-software.ungoogled-chromium", "com.google.Chrome"].includes(name),
                "must not open an unsupported or background browser");
            return app;
        }
    };
    const probeExpression = realDetector ? detect : pageProbeError
        ? '(() => { throw new Error("No accessible video found. Embedded cross-origin players need a future browser extension."); })()'
        : "probe";
    return JSON.parse(vm.runInNewContext(browser +
        '\nrun([' + JSON.stringify(probeExpression) + ']);', context));
}
for (const bundle of ["com.apple.Safari", "org.chromium.Chromium", "io.ungoogled-software.ungoogled-chromium", "com.google.Chrome"]) {
    test(`browser adapter uses active tab and native viewport for ${bundle}`, () => {
        const result = browserProbe({ bundle });
        assert.deepEqual(result.viewport, { x: 200, y: 120, width: 1000, height: 700 });
        assert.equal(result.capture.settings.window, 42);
        assert.equal(result.capture.settings.type, 1);
        assert.equal(result.capture.settings.application, bundle);
    });
    test(`browser adapter refuses uncertain geometry for ${bundle}`, () => {
        assert.throws(() => browserProbe({ bundle, extraViewport: true }), /viewport/);
        assert.throws(() => browserProbe({ bundle, captureMatches: false }), /capture window/);
        assert.throws(() => browserProbe({ bundle, badViewport: true }), /viewport/);
    });
    test(`browser adapter reports missing window and scripting permission for ${bundle}`, () => {
        assert.throws(() => browserProbe({ bundle, noWindow: true }), /no window/);
        assert.throws(() => browserProbe({ bundle, scriptError: true }), /Apple Events/);
    });
}
test("the actual video detector runs inside the browser transport envelope", () => {
    const result = browserProbe({ realDetector: true });
    assert.deepEqual(result.video, box);
});
test("focused iframe selection survives the real detector and browser transport", () => {
    const result = browserProbe({
        bundle: "io.ungoogled-software.ungoogled-chromium",
        realDetector: true, focusedEmbed: true
    });
    assert.deepEqual(result.video, box);
    assert.equal(result.selection, "focused-iframe");
});
test("the actual detector's no-video error survives the browser transport", () => {
    assert.throws(() => browserProbe({ realDetector: true, noPageVideos: true }),
        /Page video probe failed: No fully visible, loaded video found/);
});
test("page exceptions survive Chromium's scripting transport", () => {
    assert.throws(() => browserProbe({
        bundle: "io.ungoogled-software.ungoogled-chromium", pageProbeError: true
    }), /Page video probe failed: No accessible video found.*cross-origin/);
});
test("null browser replies produce an actionable error instead of a null dereference", () => {
    assert.throws(() => browserProbe({ nullProbeResponse: true }),
        /returned no page-probe data/);
});
test("malformed replies and null geometry fail before viewport discovery", () => {
    assert.throws(() => browserProbe({ malformedProbeResponse: true }),
        /invalid page-probe response/);
    assert.throws(() => browserProbe({ invalidProbeGeometry: true }),
        /invalid viewport geometry/);
});
test("Core Graphics CFArrayRef is explicitly bridged before filtering", () => {
    const result = browserProbe({ bundle: "io.ungoogled-software.ungoogled-chromium" });
    assert.equal(result.capture.settings.window, 42);
});
test("invalid Core Graphics conversion is reported before array methods are used", () => {
    assert.throws(() => browserProbe({ invalidWindowList: true }),
        /Core Graphics window enumeration did not return an array/);
});
test("native foreground PID selects Chromium without querying System Events frontmost", () => {
    const result = browserProbe({ bundle: "org.chromium.Chromium" });
    assert.equal(result.capture.settings.application, "org.chromium.Chromium");
});
test("Accessibility process and window failures identify the actual foreground browser", () => {
    assert.throws(() => browserProbe({ bundle: "org.chromium.Chromium", processMatches: false }),
        /Accessibility process for Test Browser \(org.chromium.Chromium, PID 123\)/);
    assert.throws(() => browserProbe({ bundle: "org.chromium.Chromium", noNativeWindow: true }),
        /No Accessibility window for Test Browser \(org.chromium.Chromium, PID 123\)/);
});
test("ungoogled Chromium uses its exact bundle ID for scripting and OBS capture", () => {
    const bundle = "io.ungoogled-software.ungoogled-chromium";
    const result = browserProbe({ bundle, scrollWrapper: false });
    assert.equal(result.capture.settings.application, bundle);
    assert.equal(result.capture.settings.window, 42);
    assert.deepEqual(result.viewport, { x: 200, y: 120, width: 1000, height: 700 });
});
test("Chromium accepts a direct root AXWebArea without a Safari-style scroll wrapper", () => {
    assert.deepEqual(browserProbe({ bundle: "org.chromium.Chromium", scrollWrapper: false }).viewport,
        { x: 200, y: 120, width: 1000, height: 700 });
});
test("Safari rejects a document-sized web area without its scroll viewport", () => {
    assert.throws(() => browserProbe({ scrollWrapper: false }), /viewport/);
});
function viewportDiagnostics(options) {
    let diagnostics;
    assert.throws(() => browserProbe({
        bundle: "io.ungoogled-software.ungoogled-chromium", ...options
    }), error => {
        diagnostics = JSON.parse(error.message.split("Viewport diagnostics: ")[1]);
        return true;
    });
    return diagnostics;
}
test("viewport errors report rejected native geometry and CSS size", () => {
    const diagnostics = viewportDiagnostics({ badViewport: true });
    assert.deepEqual(diagnostics.cssViewport, [1000, 700]);
    assert.equal(diagnostics.matchingViewports, 0);
    assert.equal(diagnostics.areaSamples[0].height, 300);
    assert.equal(diagnostics.areaSamples[0].accepted, false);
    assert.equal(diagnostics.roles.AXWebArea, 1);
    assert.equal(diagnostics.truncated, false);
});
test("missing native web areas are distinguishable from mismatched geometry", () => {
    const diagnostics = viewportDiagnostics({ missingWebArea: true });
    assert.equal(diagnostics.areasSeen, 0);
    assert.deepEqual(diagnostics.areaSamples, []);
    assert.deepEqual(diagnostics.roles, { AXWindow: 1, AXGroup: 1 });
});
test("ambiguous viewports report their count without choosing one", () => {
    const diagnostics = viewportDiagnostics({ extraViewport: true });
    assert.equal(diagnostics.matchingViewports, 2);
    assert.equal(diagnostics.areaSamples.length, 2);
});
test("viewport diagnostics report traversal limits", () => {
    const diagnostics = viewportDiagnostics({ depthChain: 20 });
    assert.equal(diagnostics.truncated, true);
    assert.ok(diagnostics.visited <= 500);
    assert.equal(diagnostics.activationPolls, 0, "a truncated scan does not prove the tree is missing");
});
test("scriptable windows are pinned by ID rather than retaining an indexed reference", () => {
    assert.equal(browserProbe({ indexedScriptWindowStale: true }).window.width, 1000);
});
test("native window references are reacquired after Chromium activation waits", () => {
    const result = browserProbe({
        bundle: "org.chromium.Chromium", lazyAccessibility: true, nativeRefsExpireAfterWait: true
    });
    assert.equal(result.window.width, 1000);
});
test("a disappearing AX child causes a bounded fresh scan, not an Invalid index failure", () => {
    assert.equal(browserProbe({ staleWebAreaOnce: true }).window.width, 1000);
});
test("native toolbar/sidebar controls are pruned but tab groups containing the page are not", () => {
    assert.equal(browserProbe({ chromeToolbar: true, pageInTabGroup: true }).viewport.height, 700);
});
test("browser probe emits content-free progress stages", () => {
    const phases = [];
    browserProbe({ onPhase: message => phases.push(message) });
    assert.ok(phases.some(message => message.includes("reading page video geometry")));
    assert.ok(phases.some(message => message.includes("scanning Accessibility tree")));
    assert.equal(phases.at(-1), "obs-video-crop probe phase: complete");
});
test("Safari floating 53x48 controls are not mistaken for the document window", () => {
    const result = browserProbe({ floatingWindowFirst: true });
    assert.deepEqual(result.window, { x: 200, y: 20, width: 1000, height: 800 });
    assert.deepEqual(result.viewport, { x: 200, y: 120, width: 1000, height: 700 });
});
test("Chromium also matches scriptable bounds instead of AX window order", () => {
    assert.equal(browserProbe({
        bundle: "org.chromium.Chromium", floatingWindowFirst: true
    }).window.width, 1000);
});
test("AppleScript rectangle-list bounds are normalized without guessing", () => {
    assert.equal(browserProbe({ arrayWindowBounds: true, floatingWindowFirst: true }).window.width, 1000);
});
test("an unreadable utility window does not hide the matching document window", () => {
    assert.equal(browserProbe({ unreadableWindowFirst: true }).window.width, 1000);
});
test("missing or ambiguous document windows report geometry and do not pick a utility", () => {
    assert.throws(() => browserProbe({ onlyFloatingWindow: true }), error => {
        const data = JSON.parse(error.message.split("Window diagnostics: ")[1]);
        assert.equal(data.documentBounds.width, 1000);
        assert.equal(data.nativeWindows[0].width, 53);
        assert.equal(data.matchingWindows, 0);
        return true;
    });
    assert.throws(() => browserProbe({ duplicateDocumentWindow: true }),
        /Cannot uniquely match.*Window diagnostics/);
    assert.throws(() => browserProbe({ invalidWindowBounds: true }),
        /invalid document-window bounds/);
});
test("Chromium opts into its missing web Accessibility tree and honors activation debounce", () => {
    let requests = 0, waits = 0, probes = 0;
    const result = browserProbe({
        bundle: "io.ungoogled-software.ungoogled-chromium", lazyAccessibility: true,
        onActivate: () => requests++, onWait: () => waits++, onProbe: () => probes++
    });
    assert.equal(result.capture.settings.application, "io.ungoogled-software.ungoogled-chromium");
    assert.equal(requests, 1, "request only once, not once per poll");
    assert.equal(waits, 8, "Chromium's two-second debounce must settle");
    assert.equal(probes, 2, "refresh DOM geometry after waiting");
});
test("already-enabled Chromium Accessibility is not toggled or requested again", () => {
    let requests = 0;
    browserProbe({
        bundle: "org.chromium.Chromium", lazyAccessibility: true,
        accessibilityAlreadyEnabled: true, onActivate: () => requests++
    });
    assert.equal(requests, 0);
});
test("write-only activation attributes are still usable", () => {
    let requests = 0;
    browserProbe({
        bundle: "org.chromium.Chromium", lazyAccessibility: true,
        activationReadFails: true, onActivate: () => requests++
    });
    assert.equal(requests, 1);
});
test("geometry is reprobed after Chromium's Accessibility tree becomes ready", () => {
    const result = browserProbe({
        bundle: "org.chromium.Chromium", lazyAccessibility: true, changePageWhileWaiting: true
    });
    assert.equal(result.video.x, 150);
});
test("activation failures and bounded retry exhaustion appear in diagnostics", () => {
    const failure = viewportDiagnostics({ lazyAccessibility: true, activationFails: true });
    assert.equal(failure.accessibilityActivation, "failed: activation denied");
    assert.equal(failure.activationPolls, 0);
    const timeout = viewportDiagnostics({ lazyAccessibility: true, neverExposesWebArea: true });
    assert.equal(timeout.accessibilityActivation, "requested");
    assert.equal(timeout.activationPolls, 16);
    assert.equal(timeout.areasSeen, 0);
});
test("existing but mismatched viewport geometry never triggers Accessibility activation", () => {
    let requests = 0;
    viewportDiagnostics({ badViewport: true, onActivate: () => requests++ });
    assert.equal(requests, 0);
});
test("window or foreground-app changes during activation refuse a stale crop", () => {
    for (const options of [{ moveWindowWhileWaiting: true }, { changeFocusWhileWaiting: true }]) {
        assert.throws(() => browserProbe({
            bundle: "org.chromium.Chromium", lazyAccessibility: true, ...options
        }), /focus or window geometry changed/);
    }
});
test("unsupported focused applications do not fall back to a background browser", () => {
    assert.throws(() => browserProbe({ bundle: "com.apple.finder" }), /Unsupported focused application: Test Browser \(com.apple.finder, PID 123\)/);
    assert.throws(() => browserProbe({ frontmost: false }), /focused application through NSWorkspace/);
});
