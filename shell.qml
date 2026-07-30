//@ pragma ShellId erikshell
//@ pragma UseQApplication

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
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
                function launcher(): void { win.page = win.page === "launcher" ? "" : "launcher"; }
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
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    spacing: 0

                    // top: launch + looks
                    Group {
                        Btn { glyph: "󰀻"; active: win.page === "launcher"; onClicked: win.page = win.page === "launcher" ? "" : "launcher" }
                        Btn { glyph: "󰸉"; active: win.page === "looks"; onClicked: win.page = win.page === "looks" ? "" : "looks" }
                    }

                    Item { implicitHeight: 8 }

                    Group {
                        Workspaces { Layout.alignment: Qt.AlignHCenter }
                    }

                    // the gap that does the work: everything above sits at the
                    // top, everything below at the bottom.
                    Item { Layout.fillHeight: true }

                    Group {
                        gap: 9
                        Ring { label: "cpu"; value: Sys.cpu }
                        Ring { label: "ram"; value: Sys.mem }
                        Ring { label: "gpu"; value: Sys.gpu }
                        Ring { label: "°c"; value: Sys.temp; text: Sys.temp }
                    }

                    Item { implicitHeight: 8 }

                    Group {
                        // Each of these reports state, not just what it opens.
                        Btn {
                            glyph: "󰍹"
                            active: win.page === "monitor"
                            tint: Sys.cpu >= 90 || Sys.temp >= 85 ? Theme.bad
                                : Sys.cpu >= 70 || Sys.temp >= 75 ? Theme.warn : Theme.dim
                            onClicked: win.page = win.page === "monitor" ? "" : "monitor"
                        }
                        Btn {
                            glyph: Audio.muted ? "󰝟" : Audio.vol > 0.66 ? "󰕾" : Audio.vol > 0.33 ? "󰖀" : "󰕿"
                            active: win.page === "audio"
                            tint: Audio.muted ? Theme.bad : Theme.fg
                            onClicked: win.page = win.page === "audio" ? "" : "audio"
                        }
                        Btn {
                            glyph: Sys.net === "" ? "󰤮" : Sys.net.toLowerCase().indexOf("eth") >= 0 ? "󰈀" : "󰤨"
                            active: win.page === "network"
                            tint: Sys.net === "" ? Theme.bad : Theme.good
                            onClicked: win.page = win.page === "network" ? "" : "network"
                        }
                        Btn {
                            glyph: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
                            active: win.page === "bluetooth"
                            tint: !Bluetooth.defaultAdapter?.enabled ? Theme.dim
                                : Bluetooth.devices.values.some(d => d.connected) ? Theme.good : Theme.fg
                            onClicked: win.page = win.page === "bluetooth" ? "" : "bluetooth"
                        }
                        Btn {
                            glyph: Mpris.players.values.some(p => p.isPlaying) ? "󰝚" : "󰎊"
                            active: win.page === "player"
                            tint: Mpris.players.values.some(p => p.isPlaying) ? Theme.good : Theme.dim
                            onClicked: win.page = win.page === "player" ? "" : "player"
                        }
                        Btn {
                            glyph: Notifs.dnd ? "󰂛" : "󰂚"
                            active: win.page === "notifs"
                            badge: Notifs.unread
                            tint: Notifs.dnd ? Theme.warn : Notifs.unread > 0 ? Theme.accent : Theme.dim
                            onClicked: {
                                win.page = win.page === "notifs" ? "" : "notifs";
                                if (win.page === "notifs") Notifs.markSeen();
                            }
                        }
                    }

                    Item { implicitHeight: 8 }

                    Group {
                        visible: SystemTray.items.values.length > 0
                        gap: 6
                        Repeater {
                            model: SystemTray.items.values.slice(0, 5)
                            // Tray icons are a zoo of shapes and palettes. A
                            // consistent circular ground under each one is what
                            // makes the column read as one set.
                            Rectangle {
                                required property var modelData
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 26
                                implicitHeight: 26
                                radius: 13
                                color: tm.containsMouse ? Theme.accent : Theme.bgAlt

                                Behavior on color { ColorAnimation { duration: 110 } }

                                Image {
                                    anchors.centerIn: parent
                                    width: 15
                                    height: 15
                                    source: parent.modelData.icon
                                    smooth: true
                                }

                                MouseArea {
                                    id: tm
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: e => {
                                        if (e.button === Qt.RightButton)
                                            parent.modelData.display(parent, 0, 0);
                                        else
                                            parent.modelData.activate();
                                    }
                                }
                            }
                        }
                    }

                    Item { implicitHeight: 8 }

                    Group {
                        gap: 0
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
                            color: Theme.fg
                            font.pixelSize: 15
                        }
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 5
                            Layout.bottomMargin: 4
                            width: 16; height: 1
                            color: Theme.line
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clock.date, "dd")
                            color: Theme.dim
                            font.pixelSize: 11
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clock.date, "MM")
                            color: Theme.dim
                            font.pixelSize: 11
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
                        : win.page === "looks" ? cLooks
                        : win.page === "launcher" ? cLauncher : null
                }

                Component { id: cNotifs; Panels.NotifCenter {} }
                Component { id: cMonitor; Panels.Monitor {} }
                Component { id: cAudio; Panels.Audio {} }
                Component { id: cNetwork; Panels.Network {} }
                Component { id: cBluetooth; Panels.Bluetooth {} }
                Component { id: cPlayer; Panels.Player {} }
                Component { id: cLooks; Panels.Looks {} }
                Component { id: cLauncher; Panels.Launcher {} }
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
