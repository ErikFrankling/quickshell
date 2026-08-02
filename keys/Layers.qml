import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Window

// The Dactyl's own layers. A chip per layer the keymap actually has, and the
// board under it — nothing else, because the board is the page.
ColumnLayout {
    id: root

    spacing: 12

    property int activeLayer: 0

    // What the window asks of every page. There is nothing here to search — a
    // board is a picture, not a list — so the window keeps its field hidden and
    // sends the arrow keys through to the layers instead of to a row cursor.
    property string query: ""
    readonly property bool searchable: false
    readonly property string chips: "layer"
    readonly property int hits: -1
    readonly property int sheetWidth: 0

    function scroll(rows) {}

    function cycle(by) {
        const n = Math.max(1, Keymap.layerCount);
        root.activeLayer = (root.activeLayer + by + n) % n;
    }

    // Ask the keyboard again whenever the sheet comes up, so plugging the board
    // in between two looks is enough. The Loader keeps this page alive across
    // page changes, so `Component.onCompleted` alone would only fire once.
    readonly property bool showing: root.Window.window ? root.Window.window.visible : false
    onShowingChanged: if (root.showing)
        Keymap.probe()

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: Keymap.layerNames.slice(0, Keymap.layerCount)

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

        // Which of the two sources drew this, because "from the keyboard" and
        // "from the config" are the same board until the day they are not.
        Text {
            text: Keymap.keys.length + " keys · " + Keymap.layerCount + " layers · " + Keymap.origin
            color: Theme.dim
            font.pixelSize: 11
            visible: Keymap.keys.length > 0
        }
    }

    KeyBoard {
        id: board
        Layout.alignment: Qt.AlignHCenter
        visible: Keymap.keys.length > 0
        activeLayer: root.activeLayer
        unit: Math.min(46, (root.width - 8) / Math.max(1, bounds.w))
    }

    // Neither the board nor the committed baseline answered. Say so: an empty
    // card looks like a board with nothing on it, which is a different bug.
    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 24
        Layout.bottomMargin: 24
        visible: Keymap.keys.length === 0
        text: "no keyboard found"
        color: Theme.dim
        font.pixelSize: 13
    }
}
