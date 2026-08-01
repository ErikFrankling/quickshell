import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Neovim's keymaps, from a dump his config writes on rebuild.
//
// They cannot be read live from here: the maps only exist inside a Neovim that
// has finished starting, and lazy.nvim does not register a plugin's `desc`
// until `VimEnter` has fired. So a headless run does it once — driven by an
// activation script in his dotfiles, writing the JSON below — and this page
// reads the file. If the file is not there, the page says so; a keymap list
// that is quietly incomplete is worse than no list at all.
ColumnLayout {
    id: root

    spacing: 12

    property var dump: ({})
    property bool have: false
    property bool builtins: false

    readonly property var maps: root.dump.maps ?? []

    readonly property string file: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/erikshell/nvim-keymaps.json"

    FileView {
        path: root.file
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: {
            root.have = false;
            root.dump = ({});
        }
        onLoaded: {
            try {
                root.dump = JSON.parse(text());
                root.have = true;
            } catch (e) {
                root.have = false;
            }
        }
    }

    // which-key writes its group headings with the leader spelled `<Space>`
    // and the maps themselves with `<leader>`. One of them has to give.
    function norm(lhs) {
        return (lhs ?? "").replace("<Space>", "<leader>");
    }

    // The eight which-key groups are the headings; everything that does not
    // fall under one lands in a last section of its own — last, not biggest
    // first, because the named groups are the part worth reading. Longest
    // prefix wins, so `<leader>s` does not swallow a key a deeper group owns.
    //
    // One row per key, not one per mode: the same `[%` is bound in visual,
    // operator-pending and select, and three near-identical lines say nothing
    // the modes column does not already say in one.
    readonly property string other: "Everything else"

    readonly property var sections: {
        const heads = root.maps.filter(m => m.group === true).map(g => ({
                    p: root.norm(g.lhs),
                    name: g.desc
                })).sort((a, b) => b.p.length - a.p.length);
        const by = {}, order = [], seen = {};
        for (const m of root.maps) {
            if (m.group === true || (m.builtin === true) !== root.builtins)
                continue;
            const l = root.norm(m.lhs), key = l + "\t" + (m.desc ?? "");
            if (seen[key] !== undefined) {
                if (seen[key].modes.indexOf(m.mode) < 0)
                    seen[key].modes += m.mode;
                continue;
            }
            const h = heads.find(g => l.length > g.p.length && l.startsWith(g.p));
            const name = h ? h.name : root.other;
            const row = {
                lhs: l,
                desc: m.desc ?? "",
                modes: m.mode
            };
            seen[key] = row;
            if (by[name] === undefined) {
                by[name] = [];
                order.push(name);
            }
            by[name].push(row);
        }
        return order.map(k => ({
            name: k,
            items: by[k].sort((a, b) => a.lhs.localeCompare(b.lhs))
        })).sort((a, b) => a.name === root.other ? 1 : b.name === root.other ? -1 : b.items.length - a.items.length);
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: ["His own", "Vim's own"]

            Rectangle {
                id: chip

                required property var modelData
                required property int index
                readonly property bool here: (chip.index === 1) === root.builtins

                visible: root.have
                implicitWidth: tab.implicitWidth + 20
                implicitHeight: 24
                radius: 12
                color: chip.here ? Theme.bgHi : "transparent"
                border.width: 1
                border.color: chip.here ? Theme.accent : Theme.line

                Text {
                    id: tab
                    anchors.centerIn: parent
                    text: chip.modelData
                    color: chip.here ? Theme.fg : Theme.dim
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.builtins = chip.index === 1
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            // Filetype-local maps — the LSP set, markdown, tex — do not exist
            // until a buffer of that type is open, so no dump can contain them.
            // Saying so is the difference between a sheet and a wrong sheet.
            text: root.have ? (root.dump.count ?? 0) + " maps · no filetype-local ones" : ""
            color: Theme.dim
            font.pixelSize: 11
        }
    }

    Text {
        Layout.fillWidth: true
        visible: !root.have
        wrapMode: Text.WordWrap
        text: "No dump at " + root.file + ".\n\nIt is written by a Home Manager activation script running the real Neovim headless once per rebuild — the maps do not exist until one has started, and lazy.nvim does not register a plugin's description until then either. Until that lands there is nothing honest to show here."
        color: Theme.dim
        font.pixelSize: 12
    }

    Flickable {
        id: scroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: root.have ? groups.implicitHeight : 0
        visible: root.have
        clip: true
        contentHeight: groups.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        readonly property int cols: 2
        readonly property real cell: (width - (scroll.cols - 1) * 16) / scroll.cols

        ColumnLayout {
            id: groups
            width: scroll.width
            spacing: 9

            Repeater {
                model: root.sections

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
                                    id: lhs
                                    width: 128
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.lhs
                                    color: Theme.fg
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                // The modes only earn a mark when they are not
                                // just normal, which is most of the sheet.
                                Text {
                                    id: modes
                                    anchors.left: lhs.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 22
                                    text: row.modelData.modes === "n" ? "" : row.modelData.modes
                                    color: Theme.accent
                                    font.pixelSize: 10
                                }

                                Text {
                                    anchors.left: modes.right
                                    anchors.leftMargin: 5
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.desc
                                    color: row.modelData.desc ? Theme.fg : Theme.dim
                                    font.italic: !row.modelData.desc
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
