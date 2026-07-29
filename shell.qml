//@ pragma ShellId erikshell

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            // Which panel page is open, or "" for none. The rail and the panel
            // live in one window so they share a surface, instead of being two
            // rectangles that happen to touch.
            property string page: ""

            anchors {
                top: true
                left: true
                bottom: true
            }
            implicitWidth: Theme.rail + (page === "" ? 0 : Theme.panel)
            // Windows tile around the rail only, never the open panel.
            exclusiveZone: Theme.rail
            color: "transparent"

            IpcHandler {
                target: "panel"

                function controls(): void {
                    win.page = win.page === "controls" ? "" : "controls";
                }

                function notifications(): void {
                    win.page = win.page === "notifications" ? "" : "notifications";
                }

                function close(): void {
                    win.page = "";
                }
            }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                topRightRadius: win.page === "" ? 0 : Theme.radius
                bottomRightRadius: win.page === "" ? 0 : Theme.radius

                // The seam. A hairline, never a shadow.
                Rectangle {
                    visible: win.page !== ""
                    x: Theme.rail
                    width: 1
                    height: parent.height
                    color: Theme.line
                }

                // ---- rail ------------------------------------------------
                ColumnLayout {
                    width: Theme.rail
                    height: parent.height
                    spacing: 0

                    RailButton {
                        text: "☰"
                        active: win.page === "controls"
                        onClicked: win.page = win.page === "controls" ? "" : "controls"
                    }

                    Item {
                        implicitHeight: 6
                    }

                    Repeater {
                        model: Hyprland.workspaces

                        Rectangle {
                            required property var modelData
                            readonly property bool here: Hyprland.focusedWorkspace?.id === modelData.id

                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 5
                            implicitWidth: 6
                            implicitHeight: here ? 20 : 6
                            radius: 3
                            color: here ? Theme.accent : Theme.line

                            MouseArea {
                                anchors.fill: parent
                                onClicked: parent.modelData.activate()
                            }

                            Behavior on implicitHeight {
                                NumberAnimation {
                                    duration: 120
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Stat {
                        label: "cpu"
                        value: Sys.cpu
                    }
                    Stat {
                        label: "mem"
                        value: Sys.mem
                    }
                    Stat {
                        label: "tmp"
                        value: Sys.temp
                        warnAt: 80
                    }

                    Item {
                        implicitHeight: 8
                    }

                    Repeater {
                        model: SystemTray.items

                        Item {
                            required property var modelData
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 20
                            implicitHeight: 24

                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: parent.modelData.icon
                            }
                        }
                    }

                    RailButton {
                        text: "•"
                        active: win.page === "notifications"
                        badge: Notifs.count
                        onClicked: win.page = win.page === "notifications" ? "" : "notifications"
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 12
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

                // ---- panel -----------------------------------------------
                Panel {
                    visible: win.page !== ""
                    page: win.page
                    x: Theme.rail + 1 + Theme.pad + 4
                    y: Theme.pad + 4
                    width: Theme.panel - (Theme.pad + 4) * 2
                    height: parent.height - (Theme.pad + 4) * 2
                }
            }
        }
    }
}
