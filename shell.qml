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

        // Two windows per screen, both a fixed size for their whole life.
        // Noctalia and caelestia both split it this way: a tiny window whose
        // only job is to reserve space, and one persistent full-screen window
        // that ignores exclusion and draws everything. Nothing is resized when
        // a panel opens, which is the only way the rail cannot move.
        Scope {
            id: scope

            required property var modelData

            PanelWindow {
                screen: scope.modelData
                anchors { top: true; left: true; bottom: true }
                implicitWidth: 1
                exclusiveZone: Theme.rail
                color: "transparent"
                mask: Region {}
                WlrLayershell.namespace: "shell-exclusion"
            }

            PanelWindow {
                id: win

                screen: scope.modelData

                // "" when closed, otherwise the page name.
                property string page: ""
                readonly property bool open: page !== ""

                // The page whose content is loaded. It lags `page` on close so
                // the card still has something to draw while it folds away.
                property string shown: ""
                onPageChanged: if (page !== "") shown = page

                // One driver for the whole open animation. The curve is M3
                // emphasized — the same twelve numbers noctalia puts in
                // SmartPanel's bezierCurve and caelestia in Tokens.anim
                // .emphasized; 300ms out and 150ms back, as in noctalia's
                // animationNormal / animationFast.
                property real p: open ? 1 : 0
                Behavior on p {
                    NumberAnimation {
                        duration: win.open ? 300 : 150
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4,
                                             0.208, 0.82, 0.25, 1, 1, 1]
                    }
                }

                anchors { top: true; left: true; right: true; bottom: true }
                color: "transparent"

                WlrLayershell.namespace: "shell"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                // Exclusive rather than OnDemand: a panel is opened from a
                // keybind, so no click ever hands the surface focus, and
                // without focus Escape never arrives.
                WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive
                                                  : WlrKeyboardFocus.None

                // Closed, only the rail strip takes clicks and the rest of the
                // desktop is untouched. Open, the whole window takes them, so
                // anything outside the card dismisses it.
                mask: Region {
                    width: win.open ? win.width : Theme.rail
                    height: win.height
                }

                Shortcut {
                    sequence: "Escape"
                    enabled: win.open
                    onActivated: win.page = ""
                }

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

                // Waybar's network-status.sh calls it VPN when tun0 is up, so
                // the rail agrees with the bar he already reads.
                property bool vpn: false
                Process {
                    id: vpnProbe
                    command: ["ip", "link", "show", "tun0", "up"]
                    onExited: code => win.vpn = code === 0
                }
                Timer {
                    interval: 5000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: vpnProbe.running = true
                }

                // Click anywhere off the card to dismiss. Declared first so the
                // rail and the card sit above it.
                MouseArea {
                    anchors.fill: parent
                    enabled: win.open
                    onClicked: win.page = ""
                }

                // ---- rail ---------------------------------------------------
                Rectangle {
                    id: rail
                    width: Theme.rail
                    height: parent.height
                    color: Theme.bg
                    topRightRadius: Theme.radius
                    bottomRightRadius: Theme.radius

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        spacing: 0

                        Group {
                            Workspaces { Layout.alignment: Qt.AlignHCenter }
                        }

                        // the gap that does the work: everything above sits at the
                        // top, everything below at the bottom.
                        Item { Layout.fillHeight: true }

                        // The rings are the monitor button. A separate button
                        // for the numbers printed directly above it was rail
                        // spent twice.
                        Item {
                            id: ringBox

                            property bool hovering: false

                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: rings.implicitWidth
                            implicitHeight: rings.implicitHeight

                            Group {
                                id: rings
                                gap: 9
                                color: win.page === "monitor" ? Theme.accent
                                     : ringBox.hovering ? Theme.line : Theme.bgHi

                                Behavior on color { ColorAnimation { duration: 110 } }

                                Ring { label: "cpu"; value: Sys.cpu }
                                Ring { label: "ram"; value: Sys.mem }
                                Ring { label: "gpu"; value: Sys.gpu; visible: Sys.hasGpu ?? true }
                                Ring { label: "°c"; value: Sys.temp; text: Sys.temp }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: ringBox.hovering = true
                                onExited: ringBox.hovering = false
                                onClicked: win.page = win.page === "monitor" ? "" : "monitor"
                            }
                        }

                        Item { implicitHeight: 8 }

                        Group {
                            // Each of these reports state, not just what it opens.
                            Btn {
                                glyph: "󰸉"
                                active: win.page === "looks"
                                onClicked: win.page = win.page === "looks" ? "" : "looks"
                            }
                            Btn {
                                glyph: Audio.muted ? "󰝟" : Audio.vol > 0.66 ? "󰕾" : Audio.vol > 0.33 ? "󰖀" : "󰕿"
                                active: win.page === "audio"
                                tint: Audio.muted ? Theme.bad : Theme.fg
                                onClicked: win.page = win.page === "audio" ? "" : "audio"
                            }
                            Btn {
                                // Four states, four shapes, and a dot that stays
                                // lit on VPN — he wants to see that without
                                // opening anything.
                                glyph: win.vpn ? "󰦝"
                                    : Sys.net === "" ? "󰤮"
                                    : Sys.net.toLowerCase().indexOf("eth") >= 0 ? "󰈀" : "󰤨"
                                active: win.page === "network"
                                badge: win.vpn ? 1 : 0
                                tint: win.vpn ? Theme.good
                                    : Sys.net === "" ? Theme.bad : Theme.fg
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
                                glyph: "󰂚"
                                active: win.page === "notifs"
                                badge: Notifs.unread
                                tint: Notifs.unread > 0 ? Theme.accent : Theme.dim
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
                                // Tray icons are a zoo of shapes and palettes; a
                                // consistent circular ground makes the column read
                                // as one set.
                                Rectangle {
                                    id: cell
                                    required property var modelData
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 13
                                    property bool hovering: false
                                    color: hovering ? Theme.accent : Theme.bgAlt

                                    Behavior on color { ColorAnimation { duration: 110 } }

                                    Image {
                                        anchors.centerIn: parent
                                        width: 15
                                        height: 15
                                        source: cell.modelData.icon
                                        smooth: true
                                    }

                                    // The menu is a DBusMenuHandle. anchor.item
                                    // on its own does not place it: Zaphkiel,
                                    // vast-shell and diinki all set the window
                                    // and a rect mapped into that window, so do
                                    // the same. The rect is set on click,
                                    // because the rail scrolls under the cell.
                                    QsMenuAnchor {
                                        id: trayMenu
                                        menu: cell.modelData.menu
                                        anchor.edges: Edges.Right
                                        anchor.gravity: Edges.Right
                                        anchor.adjustment: PopupAdjustment.Flip
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: cell.hovering = true
                                        onExited: cell.hovering = false
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                        onClicked: e => {
                                            if (e.button === Qt.MiddleButton) {
                                                cell.modelData.secondaryActivate();
                                                return;
                                            }
                                            // Some items have no activate action
                                            // at all and expect the menu instead.
                                            if (e.button === Qt.LeftButton && !cell.modelData.onlyMenu) {
                                                cell.modelData.activate();
                                                return;
                                            }
                                            if (!cell.modelData.hasMenu)
                                                return;
                                            const w = cell.QsWindow.window;
                                            trayMenu.anchor.window = w;
                                            trayMenu.anchor.rect = w.contentItem.mapFromItem(
                                                cell, 0, 0, cell.width, cell.height);
                                            trayMenu.open();
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
                // A floating card, not a slab: inset from the screen, centred
                // beside the rail, only as tall as its content. It unfolds out
                // of the rail edge, which is noctalia's attached-panel
                // animation — pin the edge nearest the bar, animate the far
                // one — so the near edge never moves and the rail is untouched.
                Rectangle {
                    id: card

                    readonly property int inset: Theme.pad + 4
                    readonly property int room: win.height - Theme.pad * 2
                    // The two list pages fill whatever height they are given;
                    // every other page is exactly as tall as its content.
                    readonly property bool list: win.shown === "notifs" || win.shown === "network"

                    x: Theme.rail + Theme.pad
                    y: (win.height - height) / 2
                    width: Theme.panel * win.p
                    // The floor keeps a page that has not reported a size yet
                    // from flashing past as a sliver.
                    height: Math.min(room, Math.max(200, list ? 560
                        : (body.item ? body.item.implicitHeight : 0) + inset * 2))
                    radius: Theme.radius
                    color: Theme.bg
                    clip: true

                    visible: win.p > 0
                    opacity: win.open ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: win.open ? 150 : 100
                            easing.type: Easing.OutQuad
                        }
                    }

                    // Swallow clicks so they do not reach the dismiss layer.
                    MouseArea { anchors.fill: parent }

                    // Laid out at a constant width and revealed left to right,
                    // so nothing reflows while the card is opening.
                    Loader {
                        id: body
                        x: card.inset
                        y: card.inset
                        width: Theme.panel - card.inset * 2
                        height: card.list ? card.height - card.inset * 2
                                          : card.room - card.inset * 2
                        active: win.shown !== ""
                        sourceComponent: win.shown === "notifs" ? cNotifs
                            : win.shown === "monitor" ? cMonitor
                            : win.shown === "audio" ? cAudio
                            : win.shown === "network" ? cNetwork
                            : win.shown === "bluetooth" ? cBluetooth
                            : win.shown === "player" ? cPlayer
                            : win.shown === "looks" ? cLooks : null
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
    }

    // ---- launcher ---------------------------------------------------------
    // Not a rail panel: a centred overlay on its own keybind.
    LauncherWindow { id: launcher }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.open ? launcher.hide() : launcher.show(); }
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
