import QtQuick
import Quickshell
import Quickshell.Wayland
import "panels" as Panels

// Same centered overlay and focus lifecycle as KeysWindow/LauncherWindow.
PanelWindow {
    id: root
    property bool open: false
    visible: open
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "power"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }

    function show(onScreen) {
        if (onScreen) root.screen = onScreen;
        root.open = true;
        Qt.callLater(() => card.forceActiveFocus());
    }
    function hide() { root.open = false; }

    MouseArea { anchors.fill: parent; onClicked: root.hide() }
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(460, parent.width - 40)
        height: loader.implicitHeight + 36
        color: Theme.bg
        radius: Theme.radius
        border.width: 1
        border.color: Theme.line
        Keys.onEscapePressed: root.hide()
        MouseArea { anchors.fill: parent }
        Loader {
            id: loader
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            active: root.open
            sourceComponent: Panels.Power { onCloseRequested: root.hide() }
        }
    }
}
