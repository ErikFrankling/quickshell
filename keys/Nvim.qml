import ".."
import QtQuick
import QtQuick.Layouts

// Neovim's keymaps as a cheat sheet. `NvimMaps` reads the dump and sorts it
// into task sections; this is only the chrome around them.
ColumnLayout {
    id: root

    spacing: 10

    // What the window asks of every page.
    property string query: ""
    readonly property bool searchable: maps.have
    readonly property int hits: maps.have ? sheet.hits : -1
    readonly property int sheetWidth: 1220

    function scroll(rows) {
        sheet.scroll(rows);
    }

    function cycle(by) {
        maps.builtins = !maps.builtins;
    }

    NvimMaps {
        id: maps
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        // His own maps are the default and stay the default: they are the ones
        // he cannot remember. Vim's 182 builtins he either knows or can reach
        // with `:help`, and putting them in the same list would double the
        // sheet to say things the editor already documents better.
        Repeater {
            model: ["His own", "Vim's own"]

            Rectangle {
                id: chip

                required property var modelData
                required property int index
                readonly property bool here: (chip.index === 1) === maps.builtins

                visible: maps.have
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
                    onClicked: maps.builtins = chip.index === 1
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
            text: !maps.have ? "" : root.query !== "" ? sheet.hits + " of " + shown + " shown" : maps.count + " maps · no filetype-local ones"
            color: Theme.dim
            font.pixelSize: 11

            readonly property int shown: maps.sections.reduce((a, s) => a + s.items.length, 0)
        }
    }

    Text {
        Layout.fillWidth: true
        visible: !maps.have
        wrapMode: Text.WordWrap
        text: "No dump at " + maps.file + ".\n\nIt is written by a Home Manager activation script running the real Neovim headless once per rebuild — the maps do not exist until one has started, and lazy.nvim does not register a plugin's description until then either. Until that lands there is nothing honest to show here."
        color: Theme.dim
        font.pixelSize: 12
    }

    Sheet {
        id: sheet
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: maps.have ? contentHeight : 0
        visible: maps.have
        sections: maps.sections
        query: root.query
        cols: 3
        // Wide enough for `<leader><Space>`, the longest key in the dump. A
        // description that elides can be found by searching for it; a key that
        // elides is the one thing on the row you came here to read.
        keyW: 118
    }
}
