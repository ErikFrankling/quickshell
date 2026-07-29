import QtQuick
import QtQuick.Layouts

// Labelled slider.
ColumnLayout {
    id: root

    property string label: ""
    property string glyph: ""
    property real value: 0

    signal moved(real v)

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        Text { text: root.glyph; color: Theme.dim; font.pixelSize: 13 }
        Text { text: root.label; color: Theme.dim; font.pixelSize: 12; Layout.fillWidth: true }
        Text {
            text: Math.round(root.value * 100) + "%"
            color: Theme.fg
            font.pixelSize: 12
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 7
        radius: 4
        color: Theme.bgHi

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            onPositionChanged: m => root.moved(Math.max(0, Math.min(1, m.x / width)))
            onPressed: m => root.moved(Math.max(0, Math.min(1, m.x / width)))
        }
    }
}
