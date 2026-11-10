(() => {
    // Deliberately return geometry only: no page URLs, titles or media data.
    const candidates = [], focusedFrames = [];
    let blockedFrames = 0;
    const rect = (x, y, width, height) => ({ x, y, width, height });
    const inside = (r, c) => r.x >= c.x - 0.5 && r.y >= c.y - 0.5 &&
        r.x + r.width <= c.x + c.width + 0.5 &&
        r.y + r.height <= c.y + c.height + 0.5;
    const intersection = (a, b) => rect(Math.max(a.x, b.x), Math.max(a.y, b.y),
        Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x),
        Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y));
    function visit(root, ox, oy, sx, sy, clip, depth, focusedContext) {
        if (depth > 12) return;
        for (const el of root.querySelectorAll("*")) {
            const style = el.ownerDocument.defaultView.getComputedStyle(el);
            if (style.display === "none" || style.visibility !== "visible" ||
                Number(style.opacity) === 0) continue;
            if (el.shadowRoot) visit(el.shadowRoot, ox, oy, sx, sy, clip, depth + 1,
                focusedContext && root.activeElement === el);
            if (el.tagName !== "VIDEO" && el.tagName !== "IFRAME") continue;
            if (el.checkVisibility && !el.checkVisibility({ opacityProperty: true, visibilityProperty: true })) continue;
            // Rotated/skewed videos cannot be represented by a rectangular crop.
            let transformed = false;
            for (let p = el; p; p = p.parentElement) {
                const transform = p.ownerDocument.defaultView.getComputedStyle(p).transform;
                if (transform && transform !== "none") {
                    const m = new DOMMatrixReadOnly(transform);
                    if (!m.is2D || Math.abs(m.b) > 0.001 || Math.abs(m.c) > 0.001 ||
                        m.a <= 0 || m.d <= 0) transformed = true;
                }
            }
            if (transformed) continue;
            const b = el.getBoundingClientRect();
            if (b.width <= 1 || b.height <= 1) continue;
            const r = rect(ox + b.x * sx, oy + b.y * sy, b.width * sx, b.height * sy);
            if (el.tagName === "VIDEO") {
                if (!inside(r, clip)) continue;
                if (el.readyState >= 2 && el.videoWidth > 0 && el.videoHeight > 0) {
                    candidates.push({ rect: r, playing: !el.paused && !el.ended });
                }
            } else {
                const frameClip = intersection(r, clip);
                if (frameClip.width <= 0 || frameClip.height <= 0) continue;
                const focused = focusedContext && root.activeElement === el;
                let doc;
                try { doc = el.contentDocument; } catch (_) { /* Cross-origin access. */ }
                if (!doc) {
                    blockedFrames++;
                    // The focus chain is explicit user selection, not a guess about
                    // which inaccessible frame contains a video. Capture its whole
                    // outer rectangle only when it is fully inside every viewport.
                    if (focused && inside(r, clip)) focusedFrames.push(r);
                    continue;
                }
                const fx = b.width / el.offsetWidth;
                const fy = b.height / el.offsetHeight;
                visit(doc, r.x + el.clientLeft * fx * sx,
                    r.y + el.clientTop * fy * sy, sx * fx, sy * fy, frameClip, depth + 1, focused);
            }
        }
    }
    const viewport = rect(0, 0, innerWidth, innerHeight);
    visit(document, 0, 0, 1, 1, viewport, 0, document.hasFocus());
    candidates.sort((a, b) => Number(b.playing) - Number(a.playing) ||
        b.rect.width * b.rect.height - a.rect.width * a.rect.height);
    const fallback = !candidates.length && focusedFrames.length === 1;
    if (!candidates.length && !fallback) {
        throw new Error(blockedFrames
            ? "No accessible video found. Click inside the cross-origin player, make its entire iframe visible, then press Option+Fn to capture the whole iframe including controls."
            : "No fully visible, loaded video found. Play a video and scroll it fully into view.");
    }
    return JSON.stringify({
        video: fallback ? focusedFrames[0] : candidates[0].rect,
        inner_width: innerWidth,
        inner_height: innerHeight,
        selection: fallback ? "focused-iframe" : "video"
    });
})()
