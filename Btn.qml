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
//  * The hover colour is Theme.line, not Theme.bgHi. A button on the rail sits
//    inside a Group, and Group draws its ground in bgHi, so a bgHi highlight
//    there is invisible; line is the step above it and reads on bg, bgAlt and
//    bgHi alike. It is the same colour the rail already uses to light the
//    metrics group under the pointer.
Item {
    id: root

    property string glyph: ""
    property bool active: false
    property int badge: 0
    property color tint: Theme.dim
    property color hoverColor: Theme.line

    // A ground that is there when the button is idle, and round, instead of a
    // rounded square that only appears under the pointer.
    //
    // Two controls take it — wifi and bluetooth — because they stand directly
    // under the tray cells in the same bottom cluster, and a tray cell is a 26px
    // disc of Theme.bgAlt (shell.qml:752-760, and the overflow count at :818-826
    // is the same shape). Without it that column reads as two grounded icons
    // followed by two floating glyphs, which is the thing Erik pointed at.
    //
    // This is not an option asking "should I show this?". It is the button's
    // shape, stated once at the two call sites that happen to be standing in a
    // row of discs; every other Btn on the rail is deliberately bare and says
    // nothing at all. The diameter is the tray cell's 26 rather than the slot's
    // 28, so the two kinds of icon are literally the same disc — and the slot is
    // untouched, so the rail's rhythm and rail.fixed are exactly what they were.
    //
    // A ground under a dim glyph is where legibility usually goes, so it was
    // measured rather than assumed. bgAlt is one step nearer base00 than the
    // bgHi these buttons used to sit on, so every glyph gained contrast in every
    // theme checked: on his Gruvbox dark the fg glyph goes 9.57 to 10.75 and the
    // dim one 3.58 to 4.02; on One Light 9.01 to 9.96 and 4.16 to 4.60; on
    // Atelier Dune Light — the worst of six — 2.08 to 4.18 and 1.68 to 3.38. The
    // one pairing still under 3.3 is Theme.good on a light scheme (2.81 on One
    // Light, 2.20 on Atelier Dune), which is the bluetooth-connected tint and the
    // VPN padlock. That was already below the floor before this change, at 2.55
    // and 1.10, and it is a light-scheme green problem rather than a disc one.
    property bool disc: false

    // Read from the MouseArea rather than latched by entered/exited, so it
    // cannot stick on when the button is hidden or reparented mid-hover.
    readonly property bool hovering: ma.containsMouse

    signal clicked

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: Theme.slot
    implicitHeight: Theme.slot

    Rectangle {
        id: visual
        anchors.centerIn: parent
        width: root.disc ? 26 : parent.width
        height: root.disc ? 26 : parent.height
        radius: root.disc ? width / 2 : Theme.radiusS
        // A disc is never absent, so its resting colour is a real colour rather
        // than the hover colour at zero alpha — and the animation still runs
        // between two real colours either way, which is the whole reason the
        // zero-alpha idiom is there.
        color: root.active ? Theme.accent
             : root.hovering ? root.hoverColor
             : root.disc ? Theme.bgAlt
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
