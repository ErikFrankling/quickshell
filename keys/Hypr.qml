import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland

// Hyprland's binds, read from the running compositor so they cannot go stale,
// bucketed by modifier so the sheet is four short lists rather than one long
// one. The page owns the process: `hyprctl binds` answers in under a
// millisecond, so there is nothing to cache between openings.
ColumnLayout {
    id: root

    spacing: 12

    property var binds: []

    // `hyprctl binds -j` is *not* usable on 0.56.0: the writer emits the value
    // list one position out of step with the key names, prints `keycode`
    // unquoted and leaves `allow_input_capture` with no value at all, so it is
    // not JSON and `jq` refuses it at line 15. The plain output is correct, and
    // is a flat `bind\n\tkey: value` record per bind, so that is what is parsed.
    Process {
        id: proc
        command: ["hyprctl", "binds"]
        stdout: StdioCollector {
            onStreamFinished: root.binds = root.parseBinds(text)
        }
    }

    // Hyprland announces a config reload on socket2, so nothing has to poll.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                proc.running = true;
        }
    }

    Component.onCompleted: proc.running = true

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

    // By modifier, not by task. The Neovim sheet groups by what a mapping is
    // *for*, because `:help quickref` proves that is what a human scans for —
    // but that only works when something in the data says what a bind does, and
    // 59 of these 61 carry no description at all. The modifier is the one thing
    // every record honestly states, so it is the heading.
    readonly property var bindGroups: {
        const by = {};
        for (const b of root.binds) {
            const name = root.mods(b.mask).join(" + ") || "No modifier";
            const hay = (b.combo + "\t" + b.label).toLowerCase();
            (by[name] = by[name] ?? []).push({
                key: b.combo,
                desc: b.label,
                derived: !b.described,
                modes: "",
                hay: hay,
                fold: hay.replace(/[\[\]<>+_\s-]/g, "")
            });
        }
        return Object.keys(by).map(k => ({
            name: k,
            items: by[k].sort((a, b) => a.key.localeCompare(b.key))
        })).sort((a, b) => b.items.length - a.items.length);
    }

    // What the window asks of every page.
    property string query: ""
    readonly property bool searchable: true
    readonly property string chips: ""
    readonly property int hits: sheet.hits
    readonly property int sheetWidth: 1040

    function scroll(rows) {
        sheet.scroll(rows);
    }

    // Nothing on this page to filter — the binds are the binds.
    function cycle(by) {}

    Text {
        Layout.fillWidth: true
        text: root.query !== "" ? sheet.hits + " of " + root.binds.length + " shown" : root.binds.length + " binds · from the running compositor"
        color: Theme.dim
        font.pixelSize: 11
    }

    Sheet {
        id: sheet
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: contentHeight
        sections: root.bindGroups
        query: root.query
        cols: 2
        keyW: 150
    }
}
