import QtQuick
import QtQuick.Layouts

// The hover ground is one rectangle that is both what you see and what the
// pointer hits: the MouseArea and the Rectangle both fill the item, so they can
// never disagree about where the button is. Every button component worth
// copying does this — noctalia's NIconButton, whisker's StyledButton, skwd's
// and doannc2212's IconButton all fill the root with the MouseArea and draw the
// ground at the same size.
//
// Two things about the colour matter and both were wrong before:
//
//  * The idle colour is the hover colour at zero alpha, not "transparent".
//    "transparent" is transparent *black*, and ColorAnimation interpolates the
//    channels, so fading in from it washes the button dark before it arrives —
//    a visible flash on every enter and exit.
//  * The hover colour is Theme.line, not one of the ground colours. A button on
//    the rail sits inside a Group, whose ground is bgAlt, and the workspaces
//    stand on bgHi, so a highlight in either of those is invisible somewhere.
//    line is the step above both and reads on bg, bgAlt and bgHi alike. It is
//    the same colour the rail already uses to light the metrics group under the
//    pointer.
Item {
    id: root

    property string glyph: ""
    property bool active: false
    property int badge: 0
    property color tint: Theme.dim
    property color hoverColor: Theme.line

    // Read from the MouseArea rather than latched by entered/exited, so it
    // cannot stick on when the button is hidden or reparented mid-hover.
    readonly property bool hovering: ma.containsMouse

    signal clicked

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: Theme.slot
    implicitHeight: Theme.slot

    Rectangle {
        id: visual
        anchors.fill: parent
        radius: Theme.radiusS
        color: root.active ? Theme.accent
             : root.hovering ? root.hoverColor
             : Qt.alpha(root.hoverColor, 0)

        Behavior on color { ColorAnimation { duration: 110 } }

        Text {
            anchors.centerIn: parent
            text: root.glyph
            color: root.active ? Theme.bg : root.tint
            font.pixelSize: Theme.icon
        }
    }

    Rectangle {
        visible: root.badge > 0 && !root.active
        anchors { top: visual.top; right: visual.right; margins: 3 }
        width: 8
        height: 8
        radius: 4
        color: Theme.accent
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
