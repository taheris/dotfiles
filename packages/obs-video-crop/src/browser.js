ObjC.import("AppKit");
ObjC.import("CoreGraphics");

function run(argv) {
    function phase(value) { console.log("obs-video-crop probe phase: " + value); }
    phase("resolving foreground browser");
    // Use the same native foreground-app API as hex-app-record. Resolve identity
    // independently of System Events' lazy Accessibility collection specifiers.
    const front = $.NSWorkspace.sharedWorkspace.frontmostApplication;
    const bundle = ObjC.unwrap(front.bundleIdentifier) || "";
    const name = ObjC.unwrap(front.localizedName) || "unknown app";
    const pid = Number(front.processIdentifier);
    if (!bundle || !Number.isInteger(pid) || pid <= 0) {
        throw new Error("Cannot identify the focused application through NSWorkspace.");
    }
    const identity = `${name} (${bundle}, PID ${pid})`;
    const isSafari = bundle === "com.apple.Safari";
    const isChromium = [
        "org.chromium.Chromium",
        "io.ungoogled-software.ungoogled-chromium",
        "com.google.Chrome"
    ].includes(bundle);
    if (!isSafari && !isChromium) {
        throw new Error(`Unsupported focused application: ${identity}. Supported browsers: Safari, Chromium, ungoogled Chromium, Google Chrome.`);
    }
    phase("locating browser process");
    const events = Application("System Events");
    // Materialize JXA collections before counting: specifiers are not JS arrays.
    const processes = events.applicationProcesses.whose({ unixId: pid })();
    if (processes.length !== 1) {
        throw new Error(`Cannot access the Accessibility process for ${identity}. Check Automation/Accessibility permissions.`);
    }
    const browser = Application(bundle);
    const browserWindows = browser.windows();
    if (!browserWindows.length) throw new Error(`${identity} has no window available to scripting.`);
    phase("selecting scriptable browser window");
    // Scripting/Accessibility window indices can change when utility windows
    // appear/disappear. Pin the scripting window by ID and resolve AX windows
    // afresh for each scan instead of retaining an indexed AX object over waits.
    const browserWindow = browser.windows.byId(browserWindows[0].id());
    function documentFrame() {
        const raw = browserWindow.bounds();
        const frame = Array.isArray(raw) && raw.length === 4
            ? { x: raw[0], y: raw[1], width: raw[2] - raw[0], height: raw[3] - raw[1] }
            : raw;
        if (!frame || !["x", "y", "width", "height"].every(key =>
            Number.isFinite(frame[key])) || frame.width <= 0 || frame.height <= 0) {
            throw new Error("The browser returned invalid document-window bounds.");
        }
        return frame;
    }
    function invalidIndex(error) {
        return error.number === -1719 || error.errorNumber === -1719 ||
            String(error.message || error).includes("Invalid index");
    }
    const documentBounds = documentFrame();
    function nativeDocumentWindow() {
        phase("matching Accessibility window");
        for (let attempt = 0; attempt < 3; attempt++) {
            const nativeWindows = processes[0].windows();
            if (!nativeWindows.length) {
                throw new Error(`No Accessibility window for ${identity}. Check Accessibility permission.`);
            }
            let stale = false;
            const snapshots = nativeWindows.map(node => {
                try {
                    const p = node.position(), s = node.size();
                    return { node, bounds: { x: p[0], y: p[1], width: s[0], height: s[1] } };
                } catch (error) {
                    if (invalidIndex(error)) stale = true;
                    return { node, bounds: null };
                }
            });
            const matches = snapshots.filter(item => item.bounds &&
                ["x", "y", "width", "height"].every(key =>
                    Math.abs(item.bounds[key] - documentBounds[key]) < 2));
            if (matches.length === 1) return matches[0];
            if (stale && attempt < 2) { delay(0.05); continue; }
            throw new Error("Cannot uniquely match the browser document to an Accessibility window. Window diagnostics: " +
                JSON.stringify({ bundle, documentBounds, matchingWindows: matches.length,
                    nativeWindows: snapshots.slice(0, 8).map(item => item.bounds) }));
        }
    }
    const bounds = nativeDocumentWindow().bounds;
    phase("enumerating capture windows");
    // Core Graphics returns an opaque CFArrayRef. deepUnwrap alone does not
    // toll-free bridge that reference to NSArray, so it has no JS array methods.
    const windows = ObjC.deepUnwrap(
        ObjC.castRefToObject($.CGWindowListCopyWindowInfo(17, 0))
    );
    if (!Array.isArray(windows)) {
        throw new Error("Core Graphics window enumeration did not return an array.");
    }
    const matches = windows.filter(w => w.kCGWindowOwnerPID === pid && w.kCGWindowLayer === 0 &&
        Math.abs(w.kCGWindowBounds.X - bounds.x) < 2 &&
        Math.abs(w.kCGWindowBounds.Y - bounds.y) < 2 &&
        Math.abs(w.kCGWindowBounds.Width - bounds.width) < 2 &&
        Math.abs(w.kCGWindowBounds.Height - bounds.height) < 2);
    if (matches.length !== 1) {
        throw new Error(`Cannot uniquely identify the capture window for ${identity}. Check Screen Recording permission.`);
    }
    // Chromium may return null when page JavaScript throws. Catch errors inside
    // the page and return an explicit envelope instead of losing the real cause.
    const probeSource = `(() => {
        try {
            return JSON.stringify({ ok: true, value: JSON.parse((${argv[0]})) });
        } catch (error) {
            return JSON.stringify({ ok: false, error: String(error.message || error) });
        }
    })()`;
    function readPageProbe() {
        phase("reading page video geometry");
        const response = isSafari
            ? browser.doJavaScript(probeSource, { in: browserWindow.currentTab() })
            : browser.execute(browserWindow.activeTab(), { javascript: probeSource });
        if (typeof response !== "string" || !response) {
            throw new Error(`${identity} returned no page-probe data. Check that the tab is loaded and Allow JavaScript from Apple Events is enabled.`);
        }
        let reply;
        try { reply = JSON.parse(response); }
        catch (_) { throw new Error("The browser returned an invalid page-probe response."); }
        if (!reply || reply.ok !== true) {
            throw new Error("Page video probe failed: " +
                (reply && typeof reply.error === "string" ? reply.error : "invalid probe response"));
        }
        const value = reply.value;
        if (!value || !Number.isFinite(value.inner_width) || value.inner_width <= 0 ||
            !Number.isFinite(value.inner_height) || value.inner_height <= 0) {
            throw new Error("Page video probe returned invalid viewport geometry.");
        }
        return value;
    }
    let result = readPageProbe();
    // Safari's AXWebArea may cover the document: use its enclosing scroll viewport.
    // Chromium exposes the root AXWebArea's clipped screen bounds instead:
    // ui/accessibility/platform/browser_accessibility_cocoa.mm (accessibilityFrame).
    // Stop at web areas: never enumerate the webpage's Accessibility descendants.
    const viewports = [], areaSamples = [];
    const roles = Object.create(null);
    let visited = 0, areasSeen = 0, truncated = false, staleElements = 0;
    const chromeControls = new Set([
        "AXToolbar", "AXOutline", "AXTable", "AXButton", "AXPopUpButton", "AXTextField", "AXRadioButton",
        "AXImage", "AXStaticText", "AXMenuButton", "AXMenuBar", "AXCheckBox", "AXSlider"
    ]);
    function walk(node, depth) {
        if (depth > 12 || visited >= 500) { truncated = true; return; }
        visited++;
        try {
            const role = node.role();
            roles[role] = (roles[role] || 0) + 1;
            if (role === "AXWebArea") {
                if (isChromium) addViewport(node, role);
                return;
            }
            // Each System Events property is a cross-process Apple Event.
            // Native toolbars, bookmark outlines/tables, and leaf controls
            // cannot contain the page viewport.
            // Do NOT prune groups/tab groups: those may contain page content.
            if (chromeControls.has(role)) return;
            const children = node.uiElements();
            if (isSafari && role === "AXScrollArea" && children.some(c => c.role() === "AXWebArea")) {
                addViewport(node, role);
                return;
            }
            for (const child of children) walk(child, depth + 1);
        } catch (error) {
            if (!invalidIndex(error)) throw error;
            staleElements++;
        }
    }
    function addViewport(node, role) {
        const p = node.position(), s = node.size();
        const rect = { x: p[0], y: p[1], width: s[0], height: s[1] };
        const scaleX = s[0] / result.inner_width;
        const scaleY = s[1] / result.inner_height;
        const accepted = s[0] > 0 && s[1] > 0 && Math.abs(scaleX / scaleY - 1) < 0.025;
        areasSeen++;
        // Bounded geometry-only diagnostics; never enumerate web-area descendants,
        // read page titles/URLs, or collect Accessibility labels and text.
        if (areaSamples.length < 8) areaSamples.push({ role, ...rect, accepted });
        if (accepted) viewports.push(rect);
    }
    function scanViewport() {
        for (let attempt = 0; attempt < 3; attempt++) {
            viewports.length = 0;
            areaSamples.length = 0;
            for (const role of Object.keys(roles)) delete roles[role];
            visited = 0; areasSeen = 0; truncated = false; staleElements = 0;
            ensureSameWindow();
            const window = nativeDocumentWindow().node;
            phase("scanning Accessibility tree");
            walk(window, 0);
            phase(`Accessibility scan complete: nodes=${visited}, areas=${areasSeen}, stale=${staleElements}`);
            if (staleElements === 0) return;
            if (attempt < 2) delay(0.05);
        }
    }
    function ensureSameWindow() {
        const currentPID = Number($.NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier);
        const frame = documentFrame();
        if (currentPID !== pid || ["x", "y", "width", "height"].some(key =>
            Math.abs(frame[key] - bounds[key]) > 2)) {
            throw new Error("Browser focus or window geometry changed during the probe; retry Option+Fn.");
        }
    }
    scanViewport();
    let accessibilityActivation = "not-needed", activationPolls = 0;
    if (isChromium && areasSeen === 0 && !truncated && staleElements === 0) {
        phase("requesting Chromium Accessibility tree");
        // Chromium exposes browser chrome before its renderer Accessibility tree.
        // AXEnhancedUserInterface is its native opt-in for assistive clients:
        // chrome/browser/chrome_browser_application_mac.mm, accessibilitySetValue.
        let requested = false;
        try {
            const attribute = processes[0].attributes.byName("AXEnhancedUserInterface");
            let enabled = false;
            try { enabled = attribute.value() === true; } catch (_) { /* May be write-only. */ }
            if (!enabled) attribute.value = true;
            accessibilityActivation = enabled ? "already-enabled" : "requested";
            requested = true;
        } catch (error) {
            accessibilityActivation = "failed: " + String(error.message || error);
        }
        if (requested) {
            // Chromium debounces activation for two seconds. Set the attribute
            // once, then poll: repeated writes would restart its debounce timer.
            while (areasSeen === 0 && activationPolls < 16) {
                phase("waiting for Chromium Accessibility tree");
                delay(0.25);
                activationPolls++;
                scanViewport();
            }
            ensureSameWindow();
            // The user may have scrolled or changed tabs while waiting. Never
            // combine old DOM geometry with the newly available native viewport.
            result = readPageProbe();
            scanViewport();
        }
    }
    phase("validating final window geometry");
    ensureSameWindow();
    if (viewports.length !== 1 || staleElements > 0) {
        const diagnostics = {
            bundle, cssViewport: [result.inner_width, result.inner_height],
            window: bounds, matchingViewports: viewports.length,
            areasSeen, areaSamples, roles, visited, truncated, staleElements,
            accessibilityActivation, activationPolls
        };
        throw new Error("Cannot uniquely identify the browser's page viewport; refusing to guess toolbar offsets. " +
            "Viewport diagnostics: " + JSON.stringify(diagnostics));
    }
    phase("complete");
    return JSON.stringify(Object.assign(result, {
        window: bounds,
        viewport: viewports[0],
        capture: {
            input_kind: "screen_capture",
            settings: {
                type: 1, window: matches[0].kCGWindowNumber,
                application: bundle, show_cursor: false
            }
        }
    }));
}
