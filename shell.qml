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

            // Its own overlay window so it can sit above everything and take
            // the focus Escape needs. Opened from the tray cells below.
            TrayMenu {
                id: trayMenu
                screen: scope.modelData
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

                // The background rolls out solid; only the page inside it
                // fades, and it starts halfway through the roll. That is
                // noctalia's opacityTrigger — a timer at animationNormal * 0.5
                // — and it is what keeps a page from being legible while it is
                // still a sliver. On the way out the page leaves first.
                property bool bodyShown: false
                onOpenChanged: {
                    if (open) {
                        bodyIn.restart();
                    } else {
                        bodyIn.stop();
                        bodyShown = false;
                    }
                }
                Timer { id: bodyIn; interval: 150; onTriggered: win.bodyShown = true }

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

                // Where the card centres itself: the middle of the rail item
                // that opened the page, in this window's coordinates. -1 means
                // nothing claimed a position and the card falls back to the
                // middle of the screen.
                //
                // Resolved once, on the click, and stored — mapToItem sets up
                // no binding dependency on the source item's position (Ricelin
                // says the same in its VFader), so a live binding would go
                // stale the moment the rail relaid itself out.
                property real anchorY: -1

                // `item` is the rail item that was clicked, or null for a
                // keybind, in which case the rail is asked whether this page
                // has a button pinned on it after all. Noctalia does the same
                // lookup by name — SmartPanel.open() hands its buttonName to
                // BarService.lookupWidget() — and centres on the screen when
                // the widget is not on the bar.
                function openAt(item, name) {
                    const src = item ?? win.railItem(name);
                    win.anchorY = (src && src.visible)
                        ? src.mapToItem(null, 0, src.height / 2).y : -1;
                    win.page = win.page === name ? "" : name;
                }

                // The rail item a page belongs to, if it is on the rail at all.
                function railItem(name) {
                    if (name === "monitor")
                        return ringBox;
                    if (name === "widgets")
                        return chevron;
                    for (let i = 0; i < cluster.count; i++) {
                        const l = cluster.itemAt(i);
                        if (l && l.modelData.id === name)
                            return l;
                    }
                    return null;
                }

                // One function per page: quickshell 0.3 does not pass arguments
                // through `qs ipc call`, and this reads better in a keybind anyway.
                IpcHandler {
                    target: "panel"
                    function notifs(): void { win.openAt(null, "notifs"); }
                    function monitor(): void { win.openAt(null, "monitor"); }
                    function audio(): void { win.openAt(null, "audio"); }
                    function network(): void { win.openAt(null, "network"); }
                    function bluetooth(): void { win.openAt(null, "bluetooth"); }
                    function player(): void { win.openAt(null, "player"); }
                    function looks(): void { win.openAt(null, "looks"); }
                    function widgets(): void { win.openAt(null, "widgets"); }
                    function close(): void { win.page = ""; }
                }

                // A row in the flyout opens the widget's own panel. Only the
                // window actually showing the flyout answers — the others are
                // on other screens and were never asked. anchorY is left where
                // the chevron put it: the new page takes the flyout's place
                // rather than jumping somewhere else on the way.
                Connections {
                    target: Pins
                    function onActivate(id: string): void {
                        if (win.page === "widgets")
                            win.page = id;
                    }
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

                    // One per cluster button. They report state, not just what
                    // they open. In components rather than inline in the column
                    // because the column is the pin list now.
                    Component {
                        id: bLooks
                        Btn {
                            id: looksBtn
                            glyph: "󰸉"
                            active: win.page === "looks"
                            onClicked: win.openAt(looksBtn, "looks")
                        }
                    }
                    Component {
                        id: bAudio
                        Btn {
                            id: audioBtn
                            glyph: Audio.muted ? "󰝟" : Audio.vol > 0.66 ? "󰕾" : Audio.vol > 0.33 ? "󰖀" : "󰕿"
                            active: win.page === "audio"
                            tint: Audio.muted ? Theme.bad : Theme.fg
                            onClicked: win.openAt(audioBtn, "audio")
                        }
                    }
                    Component {
                        id: bNetwork
                        Btn {
                            id: networkBtn
                            // Four states, four shapes, and a dot that stays lit
                            // on VPN — he wants to see that without opening
                            // anything.
                            glyph: win.vpn ? "󰦝"
                                : Sys.net === "" ? "󰤮"
                                : Sys.net.toLowerCase().indexOf("eth") >= 0 ? "󰈀" : "󰤨"
                            active: win.page === "network"
                            badge: win.vpn ? 1 : 0
                            tint: win.vpn ? Theme.good
                                : Sys.net === "" ? Theme.bad : Theme.fg
                            onClicked: win.openAt(networkBtn, "network")
                        }
                    }
                    Component {
                        id: bBluetooth
                        Btn {
                            id: btBtn
                            glyph: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
                            active: win.page === "bluetooth"
                            tint: !Bluetooth.defaultAdapter?.enabled ? Theme.dim
                                : Bluetooth.devices.values.some(d => d.connected) ? Theme.good : Theme.fg
                            onClicked: win.openAt(btBtn, "bluetooth")
                        }
                    }
                    Component {
                        id: bPlayer
                        Btn {
                            id: playerBtn
                            glyph: Mpris.players.values.some(p => p.isPlaying) ? "󰝚" : "󰎊"
                            active: win.page === "player"
                            tint: Mpris.players.values.some(p => p.isPlaying) ? Theme.good : Theme.dim
                            onClicked: win.openAt(playerBtn, "player")
                        }
                    }
                    Component {
                        id: bNotifs
                        Btn {
                            id: notifsBtn
                            glyph: "󰂚"
                            active: win.page === "notifs"
                            badge: Notifs.unread
                            tint: Notifs.unread > 0 ? Theme.accent : Theme.dim
                            onClicked: {
                                win.openAt(notifsBtn, "notifs");
                                if (win.page === "notifs") Notifs.markSeen();
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        spacing: 0

                        Group {
                            visible: Pins.state("workspaces") === "pinned"
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

                            visible: Pins.state("monitor") === "pinned"
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
                                onClicked: win.openAt(ringBox, "monitor")
                            }
                        }

                        Item { implicitHeight: 8 }

                        // Which buttons this cluster draws, and in what order,
                        // is the pin list — nothing here is hardcoded. Noctalia
                        // drives its whole bar this way, off a widget registry
                        // and a per-section Repeater of loaders; this is the
                        // same shape, one cluster wide.
                        Group {
                            visible: cluster.count > 0

                            Repeater {
                                id: cluster
                                model: ScriptModel { values: Pins.railWidgets }

                                Loader {
                                    required property var modelData
                                    Layout.alignment: Qt.AlignHCenter
                                    sourceComponent: modelData.id === "looks" ? bLooks
                                        : modelData.id === "audio" ? bAudio
                                        : modelData.id === "network" ? bNetwork
                                        : modelData.id === "bluetooth" ? bBluetooth
                                        : modelData.id === "player" ? bPlayer
                                        : modelData.id === "notifs" ? bNotifs : null
                                }
                            }
                        }

                        Item { implicitHeight: 8 }

                        Group {
                            gap: 6

                            // Everything not pinned to the rail lives behind
                            // this, as it does behind Windows' taskbar chevron
                            // and Plasma's ExpanderArrow.
                            Btn {
                                id: chevron
                                glyph: "󰅂"
                                active: win.page === "widgets"
                                onClicked: win.openAt(chevron, "widgets")
                            }

                            Repeater {
                                // ScriptModel, not the bare array: binding a
                                // live values slice straight into model has Qt
                                // rebuild every delegate synchronously from
                                // inside the destructor of the item that just
                                // went away, which segfaults when an
                                // application quits. ScriptModel diffs by
                                // identity and only removes the one delegate.
                                model: ScriptModel { values: Pins.railTray }
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
                                            // TrayMenu draws the menu itself,
                                            // so it wants a position rather
                                            // than an anchor. win covers the
                                            // whole screen, so mapping to its
                                            // root item gives screen
                                            // coordinates. Beside the rail, top
                                            // aligned with the icon.
                                            const p = cell.mapToItem(null, 0, 0);
                                            trayMenu.show(cell.modelData,
                                                Theme.rail + Theme.pad, p.y - 6);
                                        }
                                    }
                                }
                            }
                        }

                        Item { implicitHeight: 8 }

                        Group {
                            gap: 0
                            visible: Pins.state("clock") === "pinned"
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
                // Attached, not floating. The card's left edge *is* the rail's
                // right edge, and the two corners along it curve the wrong way,
                // so the rail reads as flaring out into the card rather than as
                // having a card parked beside it — see CardShape. Only as tall
                // as its content, clamped so the fillets still fit on screen.
                //
                // It unfolds out of the rail: noctalia's attached-panel
                // animation pins the edge nearest the bar and moves only the
                // far one, which is also why the rail cannot be disturbed.
                Item {
                    id: card

                    readonly property int inset: Theme.pad + 4
                    // The gap the fillets need: an inverted corner is drawn a
                    // whole radius outside the card, so the card has to stop
                    // that much short of the screen edge or the curve is cut.
                    readonly property int edge: Theme.pad + Theme.radius
                    readonly property int room: win.height - card.edge * 2
                    x: Theme.rail
                    // Centred on the rail item that opened the page, so the
                    // junction lands on the button you pressed, then clamped
                    // into `room`. That is the sum noctalia does for a vertical
                    // bar in SmartPanel's setPosition(): centre on the button,
                    // then Math.max(top, Math.min(y, bottom - height)), with
                    // the screen centre standing in when there is no button.
                    //
                    // Whole pixels: a half-pixel card edge puts a seam of
                    // antialiasing where the fillet meets the rail.
                    y: {
                        const mid = win.anchorY >= 0 ? win.anchorY : win.height / 2;
                        return Math.round(Math.max(card.edge,
                            Math.min(mid - card.height / 2,
                                     win.height - card.edge - card.height)));
                    }
                    width: Theme.panel * win.p
                    // The floor keeps a page that has not reported a size yet
                    // from flashing past as a sliver.
                    height: Math.min(room, Math.max(200,
                        (body.item ? body.item.implicitHeight : 0) + inset * 2))

                    // Content grows while the card is open — a wifi scan
                    // landing, a notification arriving. Centred on a button
                    // that moves both edges, so ease it instead of jumping;
                    // noctalia animates the same resize, its height Behavior
                    // running at animationNormal whenever the panel is not
                    // mid-open. Off during the roll so it cannot fight it.
                    Behavior on height {
                        enabled: win.p === 1
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    visible: win.p > 0

                    CardShape {
                        cardWidth: card.width
                        cardHeight: card.height
                    }

                    // Swallow clicks so they do not reach the dismiss layer.
                    MouseArea { anchors.fill: parent }

                    // Laid out at a constant width and revealed left to right,
                    // so nothing reflows while the card is opening. The clip is
                    // here rather than on the card because an inverted corner is
                    // drawn outside the card's own bounds.
                    Item {
                        anchors.fill: parent
                        clip: true
                        opacity: win.bodyShown ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: win.open ? 150 : 75
                                easing.type: Easing.OutQuad
                            }
                        }

                        Loader {
                            id: body
                            x: card.inset
                            y: card.inset
                            width: Theme.panel - card.inset * 2
                            height: card.room - card.inset * 2
                            active: win.shown !== ""
                            sourceComponent: win.shown === "notifs" ? cNotifs
                                : win.shown === "monitor" ? cMonitor
                                : win.shown === "audio" ? cAudio
                                : win.shown === "network" ? cNetwork
                                : win.shown === "bluetooth" ? cBluetooth
                                : win.shown === "player" ? cPlayer
                                : win.shown === "looks" ? cLooks
                                : win.shown === "widgets" ? cWidgets : null
                        }
                    }

                    Component { id: cNotifs; Panels.NotifCenter {} }
                    Component { id: cMonitor; Panels.Monitor {} }
                    Component { id: cAudio; Panels.Audio {} }
                    Component { id: cNetwork; Panels.Network {} }
                    Component { id: cBluetooth; Panels.Bluetooth {} }
                    Component { id: cPlayer; Panels.Player {} }
                    Component { id: cLooks; Panels.Looks {} }
                    Component { id: cWidgets; Panels.Widgets {} }
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
