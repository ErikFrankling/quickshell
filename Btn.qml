import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string glyph: ""
    property bool active: false
    property int badge: 0
    property string tip: ""
    // Colour the glyph when the thing it represents is actually on.
    property color tint: Theme.dim

    signal clicked

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: 34
    implicitHeight: 34

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusS
        color: root.active ? Theme.accent : ma.containsMouse ? Theme.bgHi : "transparent"

        Behavior on color { ColorAnimation { duration: 110 } }

        Text {
            anchors.centerIn: parent
            text: root.glyph
            color: root.active ? Theme.bg : root.tint
            font.pixelSize: 16
        }
    }

    Rectangle {
        visible: root.badge > 0 && !root.active
        anchors { top: parent.top; right: parent.right; margins: 5 }
        width: 8; height: 8; radius: 4
        color: Theme.accent
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
