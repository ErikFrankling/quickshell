pragma Singleton

import "kle.js" as Kle
import Quickshell
import Quickshell.Io
import QtQuick

// The Dactyl Manuform's layers, read from the QMK tree the firmware was built
// from — which matches what is flashed, since the LZMA blob in the hex is
// `vial.json` byte for byte (docs/keyboard.md).
//
// Three files, because the board's shape and the board's keycodes live apart:
//
//   vial.json      the physical layout, as KLE — and the only one of the three
//                  with the thumb clusters' ±15° rotation in it. It is the
//                  same payload the Vial GUI itself renders.
//   keyboard.json  the matrix address of every position, in `LAYOUT()` order.
//   keymap.c       the keycodes, one `LAYOUT(...)` per layer.
//
// The join is the matrix address: KLE labels every key "row,col", and
// `keyboard.json`'s nth entry is the nth argument of the generated `LAYOUT()`
// macro, so "row,col" gives an index and the index gives a keycode.
Singleton {
    id: root

    readonly property string board: "/home/erikf/projects/3d/vial-qmk/keyboards/handwired/dactyl_manuform/5x6_64"

    property var placed: []   // KLE keys: x, y, w, h, r, rx, ry, matrix
    property var order: ({})  // matrix address → index into a LAYOUT() call
    property var layers: []   // keycodes per layer

    readonly property var layerNames: ["Base", "Fn"]

    // `keyboard.json` gives every key an x and a y as well, but with the
    // rotation thrown away and both thumb clusters flattened into the bottom
    // row — which is why the board used to read as a flat grid. The KLE is the
    // richer description, so it wins; keyboard.json stays only for the matrix
    // addresses, which the KLE's labels have to resolve against.
    FileView {
        path: root.board + "/keymaps/vial/vial.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.placed = Kle.deserialise(JSON.parse(text()).layouts.keymap);
            } catch (e) {
                root.placed = [];
            }
        }
    }

    FileView {
        path: root.board + "/keyboard.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const by = {};
            try {
                const l = JSON.parse(text()).layouts.LAYOUT.layout;
                for (let i = 0; i < l.length; i++)
                    by[l[i].matrix[0] + "," + l[i].matrix[1]] = i;
            } catch (e) {}
            root.order = by;
        }
    }

    FileView {
        path: root.board + "/keymaps/vial/keymap.c"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.layers = root.parseLayers(text())
    }

    // Each `LAYOUT(...)` in keymap.c lists its keycodes in exactly the order
    // keyboard.json lists positions — that is what the generated macro is — so
    // the nth argument is the nth matrix address and no arithmetic is needed.
    // Comments go first: the file keeps a whole commented-out old keymap under
    // the live one, and the row markers inside the live one.
    function parseLayers(src) {
        const s = src.replace(/\/\*[\s\S]*?\*\//g, " ").replace(/\/\/[^\n]*/g, " ");
        const out = [];
        let at = 0;
        for (;;) {
            const start = s.indexOf("LAYOUT(", at);
            if (start < 0)
                break;
            let depth = 1, tok = "", cur = [], i = start + 7;
            for (; i < s.length; i++) {
                const c = s[i];
                if (c === "(")
                    depth++;
                else if (c === ")" && --depth === 0)
                    break;
                if (depth === 1 && c === ",") {
                    cur.push(tok.trim());
                    tok = "";
                } else {
                    tok += c;
                }
            }
            cur.push(tok.trim());
            out.push(cur);
            at = i + 1;
        }
        return out;
    }

    // Only the keycodes whose name is not already the legend. Everything else
    // — letters, digits, F-keys — is `KC_` and then the thing itself.
    readonly property var legends: ({
            "KC_TRNS": "▽",
            "KC_NO": "",
            "KC_EQL": "=",
            "KC_MINS": "−",
            "KC_BSLS": "\\",
            "KC_SCLN": ";",
            "KC_QUOT": "'",
            "KC_COMM": ",",
            "KC_DOT": ".",
            "KC_SLSH": "/",
            "KC_GRV": "`",
            "KC_LBRC": "[",
            "KC_RBRC": "]",
            "KC_TAB": "Tab",
            "KC_ESC": "Esc",
            "KC_BSPC": "Bksp",
            "KC_DEL": "Del",
            "KC_SPC": "Space",
            "KC_ENT": "Enter",
            "KC_LSFT": "Shift",
            "KC_RSFT": "Shift",
            "KC_LCTL": "Ctrl",
            "KC_RCTL": "Ctrl",
            "KC_LALT": "Alt",
            "KC_LGUI": "Super",
            "KC_HOME": "Home",
            "KC_END": "End",
            "KC_PGUP": "PgUp",
            "KC_PGDN": "PgDn",
            "KC_LEFT": "←",
            "KC_DOWN": "↓",
            "KC_UP": "↑",
            "KC_RGHT": "→",
            "KC_VOLD": "Vol−",
            "KC_VOLU": "Vol+",
            "KC_MPLY": "Play",
            "KC_MNXT": "Next",
            "KC_MPRV": "Prev",
            "KC_BRID": "Bri−",
            "KC_BRIU": "Bri+",
            "KC_PSCR": "PrtSc",
            "QK_BOOT": "Boot",
            "MO(1)": "Fn",
            "UP(AA_LOWER, AA_UPPER)": "å",
            "UP(OE_LOWER, OE_UPPER)": "ö",
            "UP(AE_LOWER, AE_UPPER)": "ä"
        })

    function legend(code) {
        return root.legends[code] ?? (code.startsWith("KC_") ? code.slice(3) : code);
    }

    // One entry per physical key, carrying its legend on every layer, so a
    // layer switch is a property read and not a re-parse.
    readonly property var keys: {
        if (root.placed.length === 0 || root.layers.length === 0)
            return [];
        const out = [];
        for (const p of root.placed) {
            const i = root.order[p.matrix];
            if (i === undefined)
                continue;
            out.push({
                x: p.x,
                y: p.y,
                w: p.w,
                h: p.h,
                r: p.r,
                rx: p.rx,
                ry: p.ry,
                legends: root.layers.map(l => i < l.length ? root.legend(l[i]) : "")
            });
        }
        return out;
    }

    readonly property var bounds: Kle.bounds(root.keys)
}
