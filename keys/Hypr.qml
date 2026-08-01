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

    Text {
        Layout.fillWidth: true
        text: root.binds.length + " binds · from the running compositor"
        color: Theme.dim
        font.pixelSize: 11
    }

    Flickable {
        id: scroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: groups.implicitHeight
        clip: true
        contentHeight: groups.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        readonly property int cols: 3
        readonly property real cell: (width - (scroll.cols - 1) * 16) / scroll.cols

        ColumnLayout {
            id: groups
            width: scroll.width
            spacing: 9

            Repeater {
                model: root.bindGroups

                ColumnLayout {
                    id: grp

                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: grp.modelData.name + "  " + grp.modelData.items.length
                        color: Theme.accent
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Grid {
                        Layout.fillWidth: true
                        columns: scroll.cols
                        columnSpacing: 16
                        rowSpacing: 1

                        Repeater {
                            model: grp.modelData.items

                            Item {
                                id: row

                                required property var modelData
                                width: scroll.cell
                                height: 17

                                Text {
                                    id: combo
                                    width: 120
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.combo
                                    color: Theme.fg
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                Text {
                                    anchors.left: combo.right
                                    anchors.leftMargin: 7
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    // A bind with no description shows its
                                    // dispatcher instead, dimmer and italic, so
                                    // the sheet never pretends the label was
                                    // written for it.
                                    text: row.modelData.label
                                    color: row.modelData.described ? Theme.fg : Theme.dim
                                    font.italic: !row.modelData.described
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
