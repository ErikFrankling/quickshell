import QtQuick

// The Dactyl Manuform, drawn key by key at the positions its own
// `keyboard.json` gives — including the two splayed outer columns and the
// six-key thumb clusters, which are the part a generic keyboard picture cannot
// show and the part worth looking at.
//
// One unit is one key pitch. Nothing here knows how many rows there are: the
// bounds come out of the data, so a keymap change is a file change and not an
// edit here.
Item {
    id: root

    required property int activeLayer
    property real unit: 44

    readonly property var bounds: {
        if (Keymap.keys.length === 0)
            return {
                x: 0,
                y: 0,
                w: 1,
                h: 1
            };
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
        for (const k of Keymap.keys) {
            x0 = Math.min(x0, k.x);
            y0 = Math.min(y0, k.y);
            x1 = Math.max(x1, k.x);
            y1 = Math.max(y1, k.y);
        }
        return {
            x: x0,
            y: y0,
            w: x1 - x0 + 1,
            h: y1 - y0 + 1
        };
    }

    implicitWidth: root.bounds.w * root.unit
    implicitHeight: root.bounds.h * root.unit

    Repeater {
        model: Keymap.keys

        Rectangle {
            id: key

            required property var modelData

            // A legend of `▽` is QMK's transparent — this layer does not change
            // the key, so it falls through to the one underneath. Still drawn,
            // but drawn as absent: a hole in a layer is information.
            readonly property string cap: modelData.legends[root.activeLayer] ?? ""
            readonly property bool live: cap !== "" && cap !== "▽"

            x: (modelData.x - root.bounds.x) * root.unit
            y: (modelData.y - root.bounds.y) * root.unit
            width: root.unit - 4
            height: root.unit - 4
            radius: 6
            color: key.live ? Theme.bgAlt : "transparent"
            border.width: 1
            border.color: key.live ? Theme.line : Qt.rgba(Theme.line.r, Theme.line.g, Theme.line.b, 0.4)

            Text {
                anchors.centerIn: parent
                width: parent.width - 4
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: key.cap
                // Whatever the Fn layer adds is the reason to look at the Fn
                // layer, so it is the accent; the base layer is just the board.
                color: !key.live ? Theme.dim : root.activeLayer > 0 ? Theme.accent : Theme.fg
                opacity: key.live ? 1 : 0.45
                font.pixelSize: key.cap.length > 4 ? 9 : key.cap.length > 1 ? 11 : 14
            }
        }
    }
}
