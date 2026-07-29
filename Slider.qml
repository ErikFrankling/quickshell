import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string label
    property real value: 0

    signal moved(real value)

    spacing: 5
    Layout.fillWidth: true

    Text {
        text: root.label
        color: Theme.dim
        font.pixelSize: 13
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 8
        radius: 4
        color: Theme.bgAlt

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }

        MouseArea {
            anchors.fill: parent
            onPositionChanged: mouse => root.moved(mouse.x / width)
            onPressed: mouse => root.moved(mouse.x / width)
        }
    }
}
