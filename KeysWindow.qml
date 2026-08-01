import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// What the keys do, on one sheet: the Dactyl's own layers above, Hyprland's
// binds below. The launcher's shape — a centred overlay on a keybind, Escape
// to dismiss, no rail button:
//   qs -p <repo> ipc call keys toggle
//
// Board and binds share one sheet rather than two tabs because they answer one
// question. Neovim's keymaps are deliberately absent: being right about them
// needs RPC into a live instance (docs/keyboard.md), and a list that is quietly
// wrong is worse than no list.
PanelWindow {
    id: root

    property bool open: false
    property int activeLayer: 0

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

    function show() {
        root.open = true;
        card.forceActiveFocus();
    }

    function hide() {
        root.open = false;
    }

    // Click anywhere outside the card to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(860, parent.width - 80)
        height: Math.min(840, parent.height - 80)
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.line

        focus: true
        Keys.onEscapePressed: root.hide()
        // Tab flips layers, which is the only thing on this sheet to flip.
        Keys.onTabPressed: event => {
            root.activeLayer = (root.activeLayer + 1) % Math.max(1, Keymap.layers.length);
            event.accepted = true;
        }

        // Swallow clicks so they do not reach the dismiss layer behind.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Keys"
                    color: Theme.fg
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Item {
                    Layout.fillWidth: true
                }

                // One chip per layer the keymap actually has.
                Repeater {
                    model: Keymap.layerNames.slice(0, Keymap.layers.length)

                    Rectangle {
                        id: chip

                        required property var modelData
                        required property int index
                        readonly property bool here: chip.index === root.activeLayer

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
                            onClicked: root.activeLayer = chip.index
                        }
                    }
                }
            }

            KeyBoard {
                id: board
                Layout.alignment: Qt.AlignHCenter
                activeLayer: root.activeLayer
                unit: Math.min(44, (card.width - 40) / Math.max(1, bounds.w))
            }

            // The board is not the binds, and a rule says so.
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.line
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Hyprland"
                    color: Theme.fg
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: Keymap.binds.length + " binds · " + Keymap.keys.length + " keys · " + Keymap.layers.length + " layers"
                    color: Theme.dim
                    font.pixelSize: 11
                }
            }

            Flickable {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
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
                        model: Keymap.bindGroups

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
                                            width: 100
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
                                            // A bind with no description shows
                                            // its dispatcher instead, dimmer and
                                            // italic, so the sheet never pretends
                                            // the label was written for it.
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
    }
}
