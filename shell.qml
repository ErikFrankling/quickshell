//@ pragma ShellId erikshell
//@ pragma UseQApplication

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "panels" as Panels

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            // "" when closed, otherwise the page name.
            property string page: ""
            readonly property bool open: page !== ""

            anchors { top: true; left: true; bottom: true }
            implicitWidth: Theme.rail + (open ? Theme.panel : 0)
            exclusiveZone: Theme.rail          // windows tile around the rail only
            color: "transparent"

            WlrLayershell.namespace: "shell"
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            // One function per page: quickshell 0.3 does not pass arguments
            // through `qs ipc call`, and this reads better in a keybind anyway.
            IpcHandler {
                target: "panel"
                function notifs(): void { win.page = win.page === "notifs" ? "" : "notifs"; }
                function monitor(): void { win.page = win.page === "monitor" ? "" : "monitor"; }
                function audio(): void { win.page = win.page === "audio" ? "" : "audio"; }
                function network(): void { win.page = win.page === "network" ? "" : "network"; }
                function bluetooth(): void { win.page = win.page === "bluetooth" ? "" : "bluetooth"; }
                function player(): void { win.page = win.page === "player" ? "" : "player"; }
                function looks(): void { win.page = win.page === "looks" ? "" : "looks"; }
                function close(): void { win.page = ""; }
            }

            SystemClock { id: clock; precision: SystemClock.Minutes }

            // ---- rail ---------------------------------------------------
            Rectangle {
                id: rail
                width: Theme.rail
                height: parent.height
                color: Theme.bg
                topRightRadius: win.open ? 0 : Theme.radius
                bottomRightRadius: win.open ? 0 : Theme.radius

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 2

                    Btn { glyph: "󰀻"; active: win.page === "looks"; onClicked: win.page = win.page === "looks" ? "" : "looks" }

                    Item { implicitHeight: 8 }

                    Repeater {
                        model: Hyprland.workspaces
                        Rectangle {
                            required property var modelData
                            readonly property bool here: Hyprland.focusedWorkspace?.id === modelData.id
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 5
                            implicitWidth: 6
                            implicitHeight: here ? 22 : 6
                            radius: 3
                            color: here ? Theme.accent : Theme.line
                            Behavior on implicitHeight { NumberAnimation { duration: 130 } }
                            MouseArea { anchors.fill: parent; onClicked: parent.modelData.activate() }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // metrics as rings, hotter the closer to the limit
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 11
                        Ring { label: "cpu"; value: Sys.cpu }
                        Ring { label: "ram"; value: Sys.mem }
                        Ring { label: "gpu"; value: Sys.gpu }
                        Ring { label: "°c"; value: Sys.temp; text: Sys.temp }
                    }

                    Item { implicitHeight: 14 }

                    Btn { glyph: "󰍹"; active: win.page === "monitor"; onClicked: win.page = win.page === "monitor" ? "" : "monitor" }
                    Btn { glyph: "󰕾"; active: win.page === "audio"; onClicked: win.page = win.page === "audio" ? "" : "audio" }
                    Btn { glyph: "󰤨"; active: win.page === "network"; onClicked: win.page = win.page === "network" ? "" : "network" }
                    Btn { glyph: "󰂯"; active: win.page === "bluetooth"; onClicked: win.page = win.page === "bluetooth" ? "" : "bluetooth" }
                    Btn { glyph: "󰝚"; active: win.page === "player"; onClicked: win.page = win.page === "player" ? "" : "player" }
                    Btn {
                        glyph: "󰂚"
                        active: win.page === "notifs"
                        badge: Notifs.unread
                        onClicked: {
                            win.page = win.page === "notifs" ? "" : "notifs";
                            if (win.page === "notifs") Notifs.markSeen();
                        }
                    }

                    Item { implicitHeight: 6 }

                    Repeater {
                        model: SystemTray.items
                        Item {
                            required property var modelData
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 22
                            implicitHeight: 24
                            Image {
                                anchors.centerIn: parent
                                width: 16; height: 16
                                source: parent.modelData.icon
                            }
                            MouseArea { anchors.fill: parent; onClicked: parent.modelData.activate() }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8
                        spacing: -3
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clock.date, "HH")
                            color: Theme.fg
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clock.date, "mm")
                            color: Theme.dim
                            font.pixelSize: 15
                        }
                    }
                }
            }

            // ---- panel --------------------------------------------------
            Rectangle {
                id: sheet
                visible: win.open
                x: Theme.rail
                width: Theme.panel
                height: parent.height
                color: Theme.bg
                topRightRadius: Theme.radius
                bottomRightRadius: Theme.radius

                // The Noctalia detail: the rail's own corners curve *into* the
                // panel where the two meet, so it reads as one carved slab.
                ConcaveCorner {
                    corner: "tl"
                    fill: Theme.bg
                    anchors { right: parent.left; top: parent.top }
                }
                ConcaveCorner {
                    corner: "bl"
                    fill: Theme.bg
                    anchors { right: parent.left; bottom: parent.bottom }
                }

                Loader {
                    anchors.fill: parent
                    anchors.margins: Theme.pad + 4
                    sourceComponent: win.page === "notifs" ? cNotifs
                        : win.page === "monitor" ? cMonitor
                        : win.page === "audio" ? cAudio
                        : win.page === "network" ? cNetwork
                        : win.page === "bluetooth" ? cBluetooth
                        : win.page === "player" ? cPlayer
                        : win.page === "looks" ? cLooks : null
                }

                Component { id: cNotifs; Panels.NotifCenter {} }
                Component { id: cMonitor; Panels.Monitor {} }
                Component { id: cAudio; Panels.Audio {} }
                Component { id: cNetwork; Panels.Network {} }
                Component { id: cBluetooth; Panels.Bluetooth {} }
                Component { id: cPlayer; Panels.Player {} }
                Component { id: cLooks; Panels.Looks {} }
            }
        }
    }

    // ---- popups -----------------------------------------------------------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            visible: Notifs.popups.length > 0
            anchors { top: true; right: true }
            implicitWidth: 400
            implicitHeight: Math.max(1, stack.implicitHeight + 20)
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.namespace: "notifications"

            ColumnLayout {
                id: stack
                anchors { fill: parent; margins: 10 }
                spacing: 9

                Repeater {
                    model: Notifs.popups
                    NotifCard {
                        required property var modelData
                        Layout.fillWidth: true
                        n: modelData
                        popup: true

                        // Low and normal go away on their own; critical stays.
                        Timer {
                            running: modelData.urgency !== "critical"
                            interval: modelData.urgency === "low" ? 4000 : 7000
                            onTriggered: Notifs.dismissPopup(modelData.key)
                        }
                    }
                }
            }
        }
    }
}
