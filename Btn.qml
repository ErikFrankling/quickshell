import QtQuick
import QtQuick.Layouts

// Hover is held in an explicit property set from entered/exited rather than
// read from containsMouse, which drops transiently and makes the highlight
// flicker while the pointer is still inside. The visual rect is centred at a
// fixed size rather than filling, so a relayout cannot resize it under the
// cursor. Both idioms taken from noctalia's NIconButton.
Item {
    id: root

    property string glyph: ""
    property bool active: false
    property int badge: 0
    property color tint: Theme.dim
    property bool hovering: false

    signal clicked

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: 34
    implicitHeight: 34

    Rectangle {
        id: visual
        width: root.implicitWidth
        height: root.implicitHeight
        anchors.centerIn: parent
        radius: Theme.radiusS
        color: root.active ? Theme.accent : root.hovering ? Theme.bgHi : "transparent"

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
        anchors { top: visual.top; right: visual.right; margins: 4 }
        width: 8
        height: 8
        radius: 4
        color: Theme.accent
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovering = true
        onExited: root.hovering = false
        onClicked: root.clicked()
    }
}
