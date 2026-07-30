import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "panels" as Panels

// Themes and wallpapers, centred, the same shape as the launcher:
//   qs -p <repo> ipc call looks toggle
//
// It was a page in the 430px rail panel, which is a column narrow enough that
// a wallpaper grid got three thumbnails to a row and a theme list got a
// scrollbar. Picking one usually means picking the other, so they belong side
// by side and side by side needs width the rail does not have. Everything here
// except the window is the same two components the panel already used.
PanelWindow {
    id: root

    property bool open: false

    visible: root.open
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "looks"
    // Exclusive focus while open, so the search boxes get the keystrokes and
    // not the window underneath; None when closed or it would swallow every
    // keystroke on the desktop.
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    function show() {
        root.open = true;
        card.forceActiveFocus();
    }

    function hide() {
        root.open = false;
    }

    // Click anywhere outside the card to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(1180, parent.width - 120)
        height: Math.min(760, parent.height - 120)
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.line

        focus: true
        Keys.onEscapePressed: root.hide()

        // Swallow clicks so they do not reach the dismiss layer behind.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Text {
                text: "Looks"
                color: Theme.fg
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 18

                Themes {
                    Layout.preferredWidth: 420
                    Layout.fillHeight: true
                }

                Panels.Wallpapers {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
