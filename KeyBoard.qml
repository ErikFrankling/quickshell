import QtQuick

// The Dactyl Manuform, drawn key by key at the positions its own `vial.json`
// gives — including the two splayed outer columns and, the part that makes it
// look like the object on his desk rather than a grid, both thumb clusters
// turned 15° in towards each other.
//
// One unit is one key pitch. Nothing here knows how many rows there are or
// where they stop: the bounds come out of the data, so a re-flash is a file
// change and not an edit here.
//
// The keycap is two rounded rectangles, which is what the Vial GUI draws
// (widgets/keyboard_widget.py, calculate_background_draw_path and its
// foreground twin): a dark base, and a lighter top inset by a tenth of a unit
// at the sides, a twentieth at the top and three twentieths at the bottom.
// The bottom inset being three times the top is the whole of the 3D effect —
// the base shows under the cap the way a keycap shows its own shadow. The
// proportions are Vial's too: a cap is 3.2/3.4 of the pitch, and the corner
// radius is 0.08 of the *pitch*, so every cap is rounded alike however wide.
Item {
    id: root

    required property int activeLayer
    property real unit: 44

    readonly property var bounds: Keymap.bounds

    implicitWidth: root.bounds.w * root.unit
    implicitHeight: root.bounds.h * root.unit

    Repeater {
        model: Keymap.keys

        Item {
            id: key

            required property var modelData

            // A legend of `▽` is QMK's transparent — this layer does not change
            // the key, so it falls through to the one underneath. Still drawn,
            // but drawn as absent: a hole in a layer is information.
            readonly property string cap: modelData.legends[root.activeLayer] ?? ""
            readonly property bool live: cap !== "" && cap !== "▽"

            x: (modelData.x - root.bounds.x) * root.unit
            y: (modelData.y - root.bounds.y) * root.unit
            width: modelData.w * root.unit - root.unit * 0.059
            height: modelData.h * root.unit - root.unit * 0.059

            // Both thumb clusters carry their own angle and their own origin —
            // the same origin for all six of their keys — so each key turns
            // about a point that is usually outside itself. Vial does the same
            // thing, a transform per key rather than a group node.
            transform: Rotation {
                origin.x: (key.modelData.rx - key.modelData.x) * root.unit
                origin.y: (key.modelData.ry - key.modelData.y) * root.unit
                angle: key.modelData.r
            }

            Rectangle {
                anchors.fill: parent
                radius: root.unit * 0.09
                color: key.live ? Theme.bgAlt : "transparent"
                border.width: 1
                border.color: key.live ? Theme.line : Qt.rgba(Theme.line.r, Theme.line.g, Theme.line.b, 0.35)
            }

            Rectangle {
                x: root.unit * 0.1
                y: root.unit * 0.05
                width: parent.width - root.unit * 0.2
                height: parent.height - root.unit * 0.2
                radius: root.unit * 0.07
                color: key.live ? Theme.bgHi : "transparent"
                border.width: key.live ? 0 : 1
                border.color: Qt.rgba(Theme.line.r, Theme.line.g, Theme.line.b, 0.25)

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 2
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: key.cap
                    // Whatever the Fn layer adds is the reason to look at the
                    // Fn layer, so it is the accent; the base layer is just the
                    // board, and reads in the ordinary foreground.
                    color: !key.live ? Theme.dim : root.activeLayer > 0 ? Theme.accent : Theme.fg
                    opacity: key.live ? 1 : 0.4
                    font.pixelSize: key.cap.length > 4 ? root.unit * 0.21 : key.cap.length > 1 ? root.unit * 0.26 : root.unit * 0.34
                }
            }
        }
    }
}
