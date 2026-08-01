.pragma library

// KLE's serialised layout format, read the way `vial-kb/vial-gui`'s
// `kle_serial.py` reads it — which is itself a port of the deserialiser in
// `ijprest/keyboard-layout-editor`'s own `serial.js`.
//
// Do not port `ijprest/kle-serial`, the npm package: its master is missing the
// `x = rx` reset at the end of a row, so rotated clusters land one row low.
// That is its issue #7, and the fix is an unmerged pull request. KLE's own
// wiki is wrong about the same line, saying each row resets `x = 0`.
//
// A row is a list mixing property objects with legend strings. A string emits
// a key at the cursor and moves the cursor on. Three rules are easy to get
// wrong and all three matter for the Dactyl:
//
//   - `x` and `y` are *deltas* on a running cursor, not absolute positions.
//   - `w` and `h` are absolute, and last for one key only.
//   - `rx` or `ry` — either one alone — opens a rotation cluster and snaps the
//     cursor to that cluster's origin. The origin is persistent, which is how
//     his right thumb cluster inherits `ry: 4` from the left without saying
//     so, and `r`/`rx`/`ry` are sticky across rows, which is how a cluster
//     spans two of them.
//
// Only the properties this board uses are read; colours, legend sizes, stepped
// and ISO-enter second rectangles are all skipped.
function deserialise(rows) {
    const out = [];
    let x = 0, y = 0, w = 1, h = 1, r = 0, rx = 0, ry = 0, cx = 0, cy = 0;
    for (const row of rows) {
        if (!Array.isArray(row))
            continue;
        for (const item of row) {
            if (typeof item === "string") {
                out.push({
                    x: x,
                    y: y,
                    w: w,
                    h: h,
                    r: r,
                    rx: rx,
                    ry: ry,
                    matrix: item
                });
                x += w;
                w = 1;
                h = 1;
                continue;
            }
            if (item.r !== undefined)
                r = item.r;
            if (item.rx !== undefined) {
                rx = cx = item.rx;
                x = cx;
                y = cy;
            }
            if (item.ry !== undefined) {
                ry = cy = item.ry;
                x = cx;
                y = cy;
            }
            if (item.x !== undefined)
                x += item.x;
            if (item.y !== undefined)
                y += item.y;
            if (item.w !== undefined)
                w = item.w;
            if (item.h !== undefined)
                h = item.h;
        }
        y += 1;
        x = rx;
    }
    return out;
}

// The extent of a set of deserialised keys, in key units, with every corner
// put through its own key's rotation first: a cluster turned 15° reaches
// further down and further out than its unturned x and y admit, and cropping
// it would be the whole point of reading the rotation, missed.
function bounds(keys) {
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    for (const k of keys) {
        const a = k.r * Math.PI / 180, c = Math.cos(a), s = Math.sin(a);
        for (const p of [[k.x, k.y], [k.x + k.w, k.y], [k.x, k.y + k.h], [k.x + k.w, k.y + k.h]]) {
            const dx = p[0] - k.rx, dy = p[1] - k.ry;
            x0 = Math.min(x0, k.rx + dx * c - dy * s);
            x1 = Math.max(x1, k.rx + dx * c - dy * s);
            y0 = Math.min(y0, k.ry + dx * s + dy * c);
            y1 = Math.max(y1, k.ry + dx * s + dy * c);
        }
    }
    return x1 > x0 ? {
        x: x0,
        y: y0,
        w: x1 - x0,
        h: y1 - y0
    } : {
        x: 0,
        y: 0,
        w: 1,
        h: 1
    };
}
