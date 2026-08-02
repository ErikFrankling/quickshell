pragma Singleton

import "kle.js" as Kle
import Quickshell
import Quickshell.Io
import QtQuick

// The Dactyl Manuform's layers, from two sources that answer the same question
// differently.
//
//   the board    `vial.py` asks the keyboard over Vial's raw-HID protocol,
//                which is the only source that cannot be stale: it is what is
//                flashed, whether it was flashed from the QMK tree or typed
//                into the Vial GUI five minutes ago.
//   the config   `dactyl.json`, generated from that QMK tree and committed
//                here, so a machine that has never had the keyboard plugged in
//                still draws the board rather than an empty card.
//
// The board wins when it answers. Nothing is cached between the two, because
// the committed baseline is already the offline answer and a third source
// would only raise the question of which keyboard the cache came from.
//
// Both arrive in one shape — `{layers, keymap, codes}`, KLE rows and a keycode
// per layer per matrix address — so there is one parser here and not two. The
// join is the matrix address: KLE labels every key "row,col", and that is
// exactly how `codes` is keyed.
Singleton {
    id: root

    property var live: null
    property var base: null

    readonly property var data: root.live ?? root.base
    readonly property string origin: root.live ? "from the keyboard" : root.base ? "from the config" : ""
    readonly property int layerCount: root.data ? root.data.layers : 0

    readonly property var layerNames: ["Base", "Fn"]

    function parse(text) {
        try {
            return JSON.parse(text);
        } catch (e) {
            return null;
        }
    }

    // Asked again every time the sheet opens, so plugging the board in is
    // enough — there is nothing to restart and nothing to press.
    function probe() {
        if (!ask.running)
            ask.running = true;
    }

    // No `watchChanges`: this file only changes when he regenerates it, which
    // is a git commit and not a re-flash.
    FileView {
        path: Quickshell.shellPath("dactyl.json")
        onLoaded: root.base = root.parse(text())
    }

    // A helper process because QML cannot open a hidraw node. It exits
    // non-zero with nothing on stdout when no keyboard answers, which parses
    // to null and falls back to the baseline — the same path as a board that
    // was unplugged since the last look.
    Process {
        id: ask

        command: ["python3", Quickshell.shellPath("vial.py")]
        Component.onCompleted: ask.running = true

        stdout: StdioCollector {
            onStreamFinished: root.live = root.parse(text)
        }
    }

    // Only the keycodes whose name is not already the legend. Everything else
    // — letters, digits, F-keys — is `KC_` and then the thing itself.
    //
    // `UP(4, 5)` rather than `UP(AA_LOWER, AA_UPPER)`: a unicode pair keycode
    // names two entries of the board's own `unicode_map`, and over HID the
    // board can only report their indices, so `vial.py` rewrites the source
    // side to indices too and both sources speak one vocabulary.
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
            "UP(4, 5)": "å",
            "UP(2, 3)": "ö",
            "UP(0, 1)": "ä"
        })

    function legend(code) {
        return root.legends[code] ?? (code.startsWith("KC_") ? code.slice(3) : code);
    }

    // One entry per physical key, carrying its legend on every layer, so a
    // layer switch is a property read and not a re-parse.
    readonly property var keys: {
        if (!root.data)
            return [];
        const out = [];
        for (const p of Kle.deserialise(root.data.keymap)) {
            const codes = root.data.codes[p.matrix];
            if (codes === undefined)
                continue;
            out.push({
                x: p.x,
                y: p.y,
                w: p.w,
                h: p.h,
                r: p.r,
                rx: p.rx,
                ry: p.ry,
                legends: codes.map(c => root.legend(c))
            });
        }
        return out;
    }

    readonly property var bounds: Kle.bounds(root.keys)
}
