pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Everything the cheatsheet knows: Hyprland's binds, and the Dactyl's layers.
//
// Both are read from the machine rather than restated here, so neither can go
// stale. The binds come from the running compositor; the layers come from the
// QMK tree the firmware was built from, which matches what is flashed (the
// LZMA blob in the hex is `vial.json` byte for byte — docs/keyboard.md).
Singleton {
    id: root

    // ---- Hyprland binds ---------------------------------------------------

    property var binds: []

    // `hyprctl binds -j` is *not* usable on 0.56.0: the writer emits the value
    // list one position out of step with the key names, prints `keycode`
    // unquoted and leaves `allow_input_capture` with no value at all, so it is
    // not JSON and `jq` refuses it at line 15. The plain output is correct, and
    // is a flat `bind\n\tkey: value` record per bind, so that is what is parsed.
    Process {
        id: bindsProc
        command: ["hyprctl", "binds"]
        stdout: StdioCollector {
            onStreamFinished: root.binds = root.parseBinds(text)
        }
    }

    // The mod bits Hyprland packs into `modmask`, in the order they read out
    // loud. CAPS and MOD2/3/5 exist too and are never used here.
    readonly property var modNames: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]

    function mods(mask) {
        return root.modNames.filter(m => (mask & m[0]) !== 0).map(m => m[1]);
    }

    // XF86AudioRaiseVolume is not a thing to read on a cheatsheet. Drop the
    // vendor prefix and put spaces where the humps are; keys his config spells
    // in lower case stay as they are, which is still shorter than the prefix.
    function keyLabel(key) {
        return key.replace(/^[Xx][Ff]86/, "").replace(/([a-z])([A-Z])/g, "$1 $2");
    }

    function parseBinds(text) {
        const out = [];
        let cur = null;
        for (const line of text.split("\n")) {
            if (line.length > 0 && line[0] !== "\t" && line[0] !== " ") {
                // `bind`, `bindd`, `bindl`, `bindle`, `bindm` all start a record.
                if (line.startsWith("bind")) {
                    cur = {};
                    out.push(cur);
                }
                continue;
            }
            const i = line.indexOf(":");
            if (cur && i > 0)
                cur[line.slice(0, i).trim()] = line.slice(i + 1).trim();
        }
        return out.map(b => {
            const desc = b.description ?? "";
            const arg = b.arg ?? "";
            return {
                mask: parseInt(b.modmask) || 0,
                combo: root.mods(parseInt(b.modmask) || 0).concat([root.keyLabel(b.key ?? "")]).join(" + "),
                // Honest degradation: 59 of his 61 binds carry no description,
                // so the dispatcher and its argument stand in — and are marked
                // as standing in, so a described bind still reads as the
                // better-documented thing it is. Converting `bind` to `bindd`
                // in his dotfiles is what fixes this, and belongs there.
                label: desc !== "" ? desc : (arg !== "" ? b.dispatcher + " " + arg : b.dispatcher ?? ""),
                described: desc !== ""
            };
        });
    }

    // Binds bucketed by their modifier combination, biggest bucket first, so
    // the sheet is four short lists rather than one long one.
    readonly property var bindGroups: {
        const by = {};
        for (const b of root.binds) {
            const name = root.mods(b.mask).join(" + ") || "No modifier";
            (by[name] = by[name] ?? []).push(b);
        }
        return Object.keys(by).map(k => ({
            name: k,
            items: by[k].sort((a, b) => a.combo.localeCompare(b.combo))
        })).sort((a, b) => b.items.length - a.items.length);
    }

    // Hyprland announces a config reload on socket2, so nothing has to poll.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                bindsProc.running = true;
        }
    }

    Component.onCompleted: bindsProc.running = true

    // ---- the Dactyl -------------------------------------------------------

    readonly property string board: "/home/erikf/projects/3d/vial-qmk/keyboards/handwired/dactyl_manuform/5x6_64"

    property var layout: []   // physical positions, from keyboard.json
    property var layers: []   // keycodes per layer, from keymap.c

    // The two files are read directly rather than run through `qmk c2json` and
    // keymap-drawer. That pipeline works — 256 ms, and it draws the split thumb
    // clusters correctly — but its output is an SVG using `dominant-baseline`
    // and `paint-order`, neither of which QtSvg implements, so the legends land
    // too high. Rather than rasterise out of process or patch thirty lines of
    // someone else's SVG, the keys are drawn in QML from the same two numbers
    // keymap-drawer would have used. This shell draws everything else itself.
    FileView {
        path: root.board + "/keyboard.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.layout = JSON.parse(text()).layouts.LAYOUT.layout;
            } catch (e) {
                root.layout = [];
            }
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
    // the nth argument is the nth key and no matrix arithmetic is needed.
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

    // One key per physical position, carrying its legend on every layer, so a
    // layer switch is a property read and not a re-parse.
    readonly property var keys: {
        const n = Math.min(root.layout.length, ...root.layers.map(l => l.length));
        if (!(n > 0))
            return [];
        const out = [];
        for (let i = 0; i < n; i++)
            out.push({
                x: root.layout[i].x,
                y: root.layout[i].y,
                legends: root.layers.map(l => root.legend(l[i]))
            });
        return out;
    }

    readonly property var layerNames: ["Base", "Fn"]
}
