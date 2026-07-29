//@ pragma ShellId erikshell

import Quickshell
import QtQuick

ShellRoot {
    PanelWindow {
        anchors {
            top: true
            left: true
            bottom: true
        }
        implicitWidth: 60
        color: "#141a21"

        Text {
            anchors.centerIn: parent
            text: "hi"
            color: "#57c8b8"
            font.pixelSize: 14
        }
    }
}
