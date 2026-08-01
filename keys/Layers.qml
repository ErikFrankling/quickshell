import ".."
import QtQuick
import QtQuick.Layouts

// The Dactyl's own layers. A chip per layer the keymap actually has, and the
// board under it — nothing else, because the board is the page.
ColumnLayout {
    id: root

    spacing: 12

    property int activeLayer: 0

    function cycle() {
        root.activeLayer = (root.activeLayer + 1) % Math.max(1, Keymap.layers.length);
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

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

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: Keymap.keys.length + " keys · " + Keymap.layers.length + " layers · Tab to flip"
            color: Theme.dim
            font.pixelSize: 11
        }
    }

    KeyBoard {
        id: board
        Layout.alignment: Qt.AlignHCenter
        activeLayer: root.activeLayer
        unit: Math.min(46, (root.width - 8) / Math.max(1, bounds.w))
    }
}
