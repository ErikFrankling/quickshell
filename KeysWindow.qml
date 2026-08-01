import "keys" as Pages
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// What the keys do. The launcher's shape — a centred overlay on a keybind,
// Escape to dismiss, no rail button:
//   qs -p <repo> ipc call keys toggle
//
// Three pages rather than one sheet, because they answer three questions and
// only ever one at a time. The shape is `panels/Control.qml`'s, which is
// vast-shell's: a strip of chips along the top and a single Loader under it.
// The card takes its height from whatever the Loader is holding, so the board
// — wide and short — does not have to live in a window sized for the bind list.
PanelWindow {
    id: root

    property bool open: false
    property string page: "board"

    visible: root.open
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "keys"
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    readonly property var pages: [["board", "Dactyl"], ["hypr", "Hyprland"], ["nvim", "Neovim"]]

    function show() {
        root.open = true;
        card.forceActiveFocus();
    }

    function hide() {
        root.open = false;
    }

    function step(by) {
        const i = root.pages.findIndex(p => p[0] === root.page);
        root.page = root.pages[(i + by + root.pages.length) % root.pages.length][0];
    }

    // Click anywhere outside the card to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(880, parent.width - 80)
        // Only as tall as the page showing, and never taller than the screen.
        height: Math.min(parent.height - 80, col.implicitHeight + 36)
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.line

        Behavior on height {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        focus: true
        Keys.onEscapePressed: root.hide()
        Keys.onLeftPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
        // Tab flips the Dactyl's layers, which is the only thing on any of
        // these pages to flip. Elsewhere it walks the pages instead.
        Keys.onTabPressed: event => {
            if (root.page === "board" && loader.item)
                loader.item.cycle();
            else
                root.step(1);
            event.accepted = true;
        }

        // Swallow clicks so they do not reach the dismiss layer behind.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Keys"
                    color: Theme.fg
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    Layout.rightMargin: 8
                }

                Repeater {
                    model: root.pages

                    Rectangle {
                        id: chip

                        required property var modelData
                        readonly property bool here: chip.modelData[0] === root.page

                        implicitWidth: tab.implicitWidth + 22
                        implicitHeight: 26
                        radius: 13
                        color: chip.here ? Theme.bgHi : "transparent"
                        border.width: 1
                        border.color: chip.here ? Theme.accent : Theme.line

                        Text {
                            id: tab
                            anchors.centerIn: parent
                            text: chip.modelData[1]
                            color: chip.here ? Theme.fg : Theme.dim
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.page = chip.modelData[0]
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Loader {
                id: loader
                Layout.fillWidth: true
                Layout.fillHeight: true
                // What makes the card resize per page: fillHeight alone reports
                // nothing upwards, so the column would ask for the chip strip
                // and stop.
                Layout.preferredHeight: item ? item.implicitHeight : 0
                sourceComponent: root.page === "hypr" ? cHypr : root.page === "nvim" ? cNvim : cBoard
            }

            Component {
                id: cBoard
                Pages.Layers {}
            }
            Component {
                id: cHypr
                Pages.Hypr {}
            }
            Component {
                id: cNvim
                Pages.Nvim {}
            }
        }
    }
}
