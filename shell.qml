//@ pragma ShellId erikshell
//@ pragma UseQApplication

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Networking
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

                // The rail item the open page belongs to. A reference, not a
                // position: the rail relays out under an open panel every time
                // a widget is pinned from the flyout, a tray icon arrives or a
                // workspace appears, and a stored position is wrong from that
                // moment on.
                property Item opener: null

                // Where the card centres itself: the middle of `opener`, in
                // this window's coordinates. -1 means nothing claimed a
                // position and the card falls back to the middle of the screen.
                //
                // The sum up the parent chain is what makes this a binding.
                // mapToItem is an ordinary function call into C++ and reads no
                // QML properties, so a binding built on it never re-evaluates —
                // it is stale from the first frame, before the layout has even
                // run. Reading each ancestor's `y` registers it as a
                // dependency, so the card re-centres whenever any of them
                // moves. Ricelin's VFader forces the same dependency with
                // `void tick.y` before its mapToItem; walking the chain is that
                // idiom with nothing left to remember to list.
                readonly property real anchorY: {
                    if (!opener || !opener.visible)
                        return -1;
                    let y = opener.height / 2;
                    for (let i = opener; i; i = i.parent)
                        y += i.y;
                    return y;
                }

                // `item` is the rail item that was clicked, or null for a
                // keybind, in which case the rail is asked whether this page
                // has a button pinned on it after all. Noctalia does the same
                // lookup by name — SmartPanel.open() hands its buttonName to
                // BarService.lookupWidget() — and centres on the screen when
                // the widget is not on the bar.
                function openAt(item, name) {
                    win.opener = item ?? win.railItem(name);
                    win.page = win.page === name ? "" : name;
                }

                // The rail item a page belongs to. Every page has one: the rail
                // is fixed, so a keybind can always find the button it would
                // have been opened from.
                function railItem(name) {
                    switch (name) {
                    case "monitor": return ringBox;
                    case "player": return playerBtn;
                    case "network": return networkBtn;
                    case "bluetooth": return btBtn;
                    case "control": return chevron;
                    }
                    return null;
                }

                // One function per page: quickshell 0.3 does not pass arguments
                // through `qs ipc call`, and this reads better in a keybind anyway.
                IpcHandler {
                    target: "panel"
                    function monitor(): void { win.openAt(null, "monitor"); }
                    function network(): void { win.openAt(null, "network"); }
                    function bluetooth(): void { win.openAt(null, "bluetooth"); }
                    function player(): void { win.openAt(null, "player"); }
                    function control(): void { win.openAt(null, "control"); }
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
                // The rail is a slab: square into all four screen edges, with
                // exactly one curve on it, where the workspaces end. It used to
                // round its own two right corners and then stand five rounded
                // groups on top of that, so the top hundred pixels alone showed
                // three curves and none of them meant anything.
                //
                // Square is what a vertical bar gets everywhere it is thought
                // about. bjarneo's bar rounds only when it is horizontal —
                // `cloudMode: round && isHorizontal`, desktop/Bar.qml:24, over
                // the comment "Vertical bars keep the original slab geometry" —
                // and falls back to a `slabBg` with no radius at all
                // (Bar.qml:80-108). shub39's right-hand bar has no radius
                // anywhere in the file and segments itself with 4px gaps
                // between flat blocks (quickshell/bar/Bar.qml:11-17, 42).
                // whisker's vertical container rounds only when the bar is set
                // to float off the edge, `radius: floating ? 20 : 0`
                // (VBarContainer.qml:28). A curve belongs where two things meet
                // or where the surface leaves the screen; the rail never
                // leaves the screen, so it keeps the one curve that means
                // something.
                Rectangle {
                    id: rail
                    width: Theme.rail
                    height: parent.height
                    color: Theme.bg

                    // ---- the overflow budget --------------------------------
                    // A vertical rail has a screen height to spend and no say
                    // in what wants to sit on it: Hyprland makes workspaces as
                    // he works and he pins tray icons as he finds them. A
                    // ColumnLayout on its own does not care — the fillHeight
                    // spacer collapses to nothing and then every group keeps
                    // its full implicit height and the column simply runs off
                    // the bottom of the screen, taking the tray and the clock
                    // with it, invisible and unclickable.
                    //
                    // Nobody in this space handles it. Noctalia's vertical bar
                    // is three independently anchored columns inside one
                    // `clip: true` Item (Modules/Bar/Bar.qml:514-518), so its
                    // sections grow into each other and whatever passes the
                    // screen edge is cut; whisker's VBarContainer.qml:24 does
                    // exactly the same. Neither has a cap, a scroll or an
                    // indicator. So the ladder below is this shell's own, and
                    // its one rule is that the rail spends its height from the
                    // bottom up: the clock, the tray, the shell's own buttons
                    // and the metrics all keep their place, and the workspaces
                    // — the most numerous thing here and the only one with a
                    // natural order to scroll through — are what gives.
                    //
                    // Height minus the 8px margin under the clock. There is no
                    // margin above: the workspaces run into the top edge.
                    readonly property int inner: rail.height - 8
                    // The part of the rail that is not negotiable: the metrics,
                    // what is playing, the arrow and the two radios, the clock,
                    // and the four 8px gaps between them.
                    readonly property int fixed: ringBox.implicitHeight
                        + playerBtn.implicitHeight + clockCol.implicitHeight
                        // The arrow, wifi and bluetooth, which are three slots
                        // of bottomCol whatever the tray does.
                        + Theme.slot * 3 + Theme.slotGap * 2 + 32
                    // What the two things that grow on their own have to share.
                    readonly property int elastic: Math.max(0, rail.inner - rail.fixed)
                    // The tray is served first but never all of it: one
                    // workspace pill's worth is held back so the rail always
                    // still says which workspace he is on. Each icon is a 26px
                    // cell over the column's own gap.
                    readonly property int trayCell: 26 + Theme.slotGap
                    readonly property int trayMax: Math.max(0,
                        Math.floor((rail.elastic - Theme.slot) / rail.trayCell))
                    readonly property int trayHidden:
                        Math.max(0, Pins.railTray.length - rail.trayMax)
                    // And the workspaces take whatever the tray left. Counted
                    // rather than measured: the icons are delegates of a
                    // Repeater inside the column this budget also pays for, so
                    // reading its height back would close the loop.
                    readonly property int wsRoom: Math.max(0, rail.elastic
                        - Math.min(rail.trayMax, Pins.railTray.length) * rail.trayCell)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.bottomMargin: 8
                        spacing: 0

                        // The workspaces, and the rail's one curve.
                        //
                        // This is the only thing left on the rail with a ground
                        // of its own. It is full width and runs square into the
                        // top and left screen edges, and its bottom right
                        // corner is the single curve — the boundary between
                        // where he is and what the machine is doing. Zaphkiel
                        // stacks two rectangles into one block the same way,
                        // rounding the outside pair and squaring the pair where
                        // the sections meet (Widgets/CalendarView.qml:22-27,
                        // 42-47); skwd's DropdownTail.qml:34-37 squares exactly
                        // the one corner that touches the bar.
                        //
                        // It is also the one elastic thing on the rail: its
                        // natural height until the rail runs out, and then it
                        // stops growing and scrolls instead. Two things make
                        // that safe rather than merely tidy: the focused pill is
                        // scrolled back into view whenever it moves, so the
                        // workspace he is actually on is never the one that
                        // went away, and a chevron sits over each edge that has
                        // more behind it, so a short list and a scrolled list
                        // never look alike.
                        Rectangle {
                            id: wsBlock

                            Layout.fillWidth: true
                            implicitHeight: wsBox.implicitHeight + 16
                            color: Theme.bgHi
                            bottomRightRadius: Theme.radius
                            clip: true

                            Item {
                                id: wsBox

                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 8
                                width: implicitWidth
                                height: implicitHeight
                                implicitWidth: wsCol.implicitWidth
                                // Never taller than the pills, never taller
                                // than the rail can pay for, and never shorter
                                // than one pill.
                                implicitHeight: Math.min(wsCol.implicitHeight,
                                    Math.max(Theme.slot, rail.wsRoom - 16))

                                Flickable {
                                    id: wsFlick

                                    anchors.fill: parent
                                    contentWidth: width
                                    contentHeight: wsCol.implicitHeight
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    // Dead to the pointer while everything
                                    // fits, so the common case behaves exactly
                                    // as it did before there was a Flickable
                                    // here at all.
                                    interactive: contentHeight > height

                                    // Scroll the focused pill back into view,
                                    // by the shortest move that does it, so the
                                    // list does not jump when he steps between
                                    // two workspaces that are both already on
                                    // screen.
                                    function follow(): void {
                                        if (contentHeight <= height) {
                                            contentY = 0;
                                            return;
                                        }
                                        for (let i = 0; i < wsCol.children.length; i++) {
                                            const c = wsCol.children[i];
                                            if (!c.here)
                                                continue;
                                            if (c.y < contentY)
                                                contentY = c.y;
                                            else if (c.y + c.height > contentY + height)
                                                contentY = c.y + c.height - height;
                                            break;
                                        }
                                        returnToBounds();
                                    }

                                    // callLater every time: the pill has not
                                    // been given its y yet at the moment any of
                                    // these fire.
                                    onHeightChanged: Qt.callLater(wsFlick.follow)
                                    onContentHeightChanged: Qt.callLater(wsFlick.follow)
                                    Component.onCompleted: Qt.callLater(wsFlick.follow)

                                    Connections {
                                        target: Hyprland
                                        function onFocusedWorkspaceChanged() {
                                            Qt.callLater(wsFlick.follow);
                                        }
                                    }

                                    Workspaces {
                                        id: wsCol
                                        width: wsFlick.width
                                        height: implicitHeight
                                    }
                                }

                                // The affordance, one per edge that has more
                                // behind it. Drawn in the group's own ground
                                // colour so it reads as the list running under
                                // the edge rather than as a pill with a chevron
                                // in it.
                                Rectangle {
                                    anchors { top: parent.top; left: parent.left; right: parent.right }
                                    height: 10
                                    color: Theme.bgHi
                                    visible: wsFlick.contentY > 0.5
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅃"
                                        color: Theme.accent
                                        font.pixelSize: 10
                                    }
                                }

                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                    height: 10
                                    color: Theme.bgHi
                                    visible: wsFlick.contentY + wsFlick.height
                                        < wsFlick.contentHeight - 0.5
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅀"
                                        color: Theme.accent
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }

                        // the gap that does the work: everything above sits at the
                        // top, everything below at the bottom.
                        Item { Layout.fillHeight: true }

                        // The rings are the monitor button. A separate button
                        // for the numbers printed directly above it was rail
                        // spent twice.
                        //
                        // With the monitor panel open this used to fill solid
                        // Theme.accent while the numbers inside the rings
                        // stayed Theme.fg. That is text on its own accent:
                        // 1.8:1 on Gruvbox, 1.5:1 on Everforest, 1.3:1 on
                        // Gruvbox Light. It is not dim, it is illegible, and
                        // the brighter the theme's accent the worse it gets.
                        //
                        // So the ground barely moves and the edge does the
                        // talking: a 12% wash and a hairline in the accent.
                        // That reads as selected from across the room and costs
                        // the numbers about a fifth of their contrast rather
                        // than six sevenths — 9.8:1, 3.1:1 and 6.5:1 against
                        // idle figures of 12.0, 3.8 and 7.8.
                        //
                        // Btn keeps its solid fill: it inverts its glyph to
                        // Theme.bg along with it, and it is one 28px slot
                        // rather than a 190px block — a badge, not a wall. The
                        // shells read for this agree there is no single answer.
                        // whisker fills a quick-toggle with the primary colour
                        // (QuickPanel.qml:21-78), Zaphkiel scales the active
                        // glyph 1.6x and draws no ground at all
                        // (CentralSwipable.qml:52-67), and noctalia's bar pill
                        // has no open-panel state whatsoever, only hover
                        // (BarPillVertical.qml:62-65). None of them fills a
                        // block this tall, because none of them has one.
                        Rectangle {
                            id: ringBox

                            readonly property bool on: win.page === "monitor"

                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: Theme.groupWidth
                            implicitHeight: rings.implicitHeight + 12
                            radius: Theme.radiusS
                            color: ringBox.on ? Qt.alpha(Theme.accent, 0.12)
                                 : ringMa.containsMouse ? Theme.line
                                 : Qt.alpha(Theme.line, 0)
                            border.width: ringBox.on ? 1 : 0
                            border.color: Theme.accent

                            Behavior on color { ColorAnimation { duration: 110 } }

                            ColumnLayout {
                                id: rings
                                anchors.centerIn: parent
                                width: parent.width
                                spacing: 9

                                // Every ring but the first two is conditional,
                                // because every one of them can be a number no
                                // sensor on this host produces. /proc/stat and
                                // /proc/meminfo answer everywhere, so cpu and
                                // ram are the only two that need no permission.
                                Ring { label: "cpu"; value: Sys.cpu }
                                // Free gigabytes is the question anyone actually
                                // asks of memory; a percentage of an unstated
                                // total is not an answer. The arc still runs on
                                // the percentage because an arc needs a
                                // fraction, and the caption carries the total,
                                // so the ring reads "14 of 31". Only whole
                                // gigabytes fit: the ring's clear middle is
                                // about 20px across and 10px digits are 6px
                                // wide, so "14" fits where "14.1" does not.
                                Ring {
                                    label: Sys.memTotalGb > 0
                                        ? "/" + Math.round(Sys.memTotalGb) : "ram"
                                    value: Sys.mem
                                    text: Math.round(Sys.memUsedGb)
                                }
                                Ring { label: "gpu"; value: Sys.gpu; visible: Sys.hasGpu }
                                Ring { label: "°c"; value: Sys.temp; text: Sys.temp; visible: Sys.hasTemp }
                                Ring { label: "fan"; value: fan.pct; visible: Sys.hasFan }
                                // Full is the good end of this one.
                                Ring { label: "bat"; value: Sys.battery; heat: 100 - Sys.battery; visible: Sys.hasBattery }
                            }

                            MouseArea {
                                id: ringMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.openAt(ringBox, "monitor")
                            }
                        }

                        Item { implicitHeight: 8 }

                        // What is playing, straight under the metrics, because
                        // both are things he wants to read off the rail without
                        // touching it.
                        RailPlayer {
                            id: playerBtn
                            active: win.page === "player"
                            onActivated: win.openAt(playerBtn, "player")
                        }

                        Item { implicitHeight: 8 }

                        // The bottom cluster, and the whole of what the rail
                        // keeps permanently: the arrow, the tray he pinned, and
                        // the two radios.
                        //
                        // There used to be six buttons here. A theme button, a
                        // volume button and a notification button each cost a
                        // slot to say nothing — no volume level, no theme name,
                        // a bell that is the same bell whether or not anything
                        // arrived — and the tray arrow cost a seventh to open a
                        // list of tray icons that were already on the rail
                        // beside it. Wifi and bluetooth are the two that carry
                        // state you want without asking for it, so they are the
                        // two that stayed. Everything else moved behind the
                        // arrow, which is now the control centre, or out of the
                        // shell entirely: looks is its own overlay window.
                        ColumnLayout {
                            id: bottomCol
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Theme.slotGap

                            // Everything without a slot of its own lives behind
                            // this, as it does behind Windows' taskbar chevron
                            // and Plasma's ExpanderArrow. It is here whether or
                            // not anything is pinned, because it is no longer
                            // only about the tray.
                            Btn {
                                id: chevron
                                glyph: "󰅂"
                                active: win.page === "control"
                                // The bell's job, minus the bell: the only
                                // thing that button ever said was a number, and
                                // a number fits on the arrow.
                                badge: Notifs.unread
                                tint: Notifs.unread > 0 ? Theme.accent : Theme.dim
                                onClicked: win.openAt(chevron, "control")

                                // A pin the rail could not honour is not a pin
                                // lost: the tray page lists every tray item,
                                // pinned or not, so the icon is exactly one
                                // click from where it always was. The count
                                // says so, because a pinned icon that simply
                                // stopped appearing would read as a bug.
                                Text {
                                    anchors { right: parent.right; bottom: parent.bottom; margins: 1 }
                                    visible: rail.trayHidden > 0
                                    text: "+" + rail.trayHidden
                                    color: chevron.active ? Theme.bg : Theme.accent
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }
                            }

                            Repeater {
                                // ScriptModel, not the bare array: binding a
                                // live values slice straight into model has Qt
                                // rebuild every delegate synchronously from
                                // inside the destructor of the item that just
                                // went away, which segfaults when an
                                // application quits. ScriptModel diffs by
                                // identity and only removes the one delegate.
                                //
                                // Sliced to what the rail can pay for. The
                                // workspaces above absorb most of the pressure,
                                // so this only bites once he has pinned more
                                // icons than a screen this tall can hold — but
                                // without it the tray is what pushes the clock
                                // off the bottom, and the tray and the clock
                                // are the two things that must never go quietly.
                                model: ScriptModel { values: Pins.railTray.slice(0, rail.trayMax) }
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

                            // The two that stayed, and the two that answer a
                            // question you did not have to ask: which network,
                            // and is anything connected.
                            //
                            // Left click opens the panel and right click flips
                            // the radio, not the other way round. What he
                            // actually does at this button is join a network or
                            // pair a headset, which needs the list; killing the
                            // radio is the rarer and the destructive one, so it
                            // does not get the button you hit by accident. It is
                            // also where every shell read for this puts it.
                            Btn {
                                id: networkBtn
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
                                onClicked: win.openAt(networkBtn, "network")

                                // Right button only, so the left one is
                                // declined here and falls through to the
                                // button's own area underneath — the same way
                                // the tray rows in the flyout take their menu
                                // click without losing their activate click.
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                                }
                            }

                            Btn {
                                id: btBtn
                                glyph: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
                                active: win.page === "bluetooth"
                                tint: !Bluetooth.defaultAdapter?.enabled ? Theme.dim
                                    : Bluetooth.devices.values.some(d => d.connected) ? Theme.good : Theme.fg
                                onClicked: win.openAt(btBtn, "bluetooth")

                                // Unblock, then power up. While rfkill has the
                                // radio soft-blocked — which is what blueman's
                                // toggle and every airplane mode leave behind —
                                // Quickshell refuses to write Powered at all
                                // and logs the reason somewhere nobody reads.
                                // The panel's own row has done this since it
                                // was written; the button has to as well.
                                Process {
                                    id: btUnblock
                                    command: ["rfkill", "unblock", "bluetooth"]
                                    onExited: {
                                        const a = Bluetooth.defaultAdapter;
                                        if (a)
                                            a.enabled = true;
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: {
                                        const a = Bluetooth.defaultAdapter;
                                        if (a?.enabled)
                                            a.enabled = false;
                                        else
                                            btUnblock.running = true;
                                    }
                                }
                            }
                        }

                        Item { implicitHeight: 8 }

                        ColumnLayout {
                            id: clockCol
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0
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
                    // Unlike noctalia's, which runs once and keeps the answer,
                    // this is a binding all the way down to the opener.
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
                    //
                    // y eases for the same reason and on the same terms: now
                    // that it tracks the opener, the rail relaying out slides
                    // the card rather than teleporting it.
                    Behavior on height {
                        enabled: win.p === 1
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }
                    Behavior on y {
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
                            sourceComponent: win.shown === "monitor" ? cMonitor
                                : win.shown === "network" ? cNetwork
                                : win.shown === "bluetooth" ? cBluetooth
                                : win.shown === "player" ? cPlayer
                                : win.shown === "control" ? cControl : null
                        }
                    }

                    Component { id: cMonitor; Panels.Monitor {} }
                    Component { id: cNetwork; Panels.Network {} }
                    Component { id: cBluetooth; Panels.Bluetooth {} }
                    Component { id: cPlayer; Panels.Player {} }
                    // The control centre's tray rows open the same menu the
                    // rail's icons do, and its Looks button opens the overlay
                    // window. Neither is reachable from a panel's own scope, so
                    // it asks and this hands them over.
                    Component {
                        id: cControl
                        Panels.Control {
                            onMenuRequested: (item, x, y) => trayMenu.show(item, x, y)
                            onLooksRequested: {
                                win.page = "";
                                looksWin.show();
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- fan ---------------------------------------------------------------
    // A ring wants a fraction and rpm is not one. Under fw-fanctrl Sys.fan is
    // already a percentage of maximum — that is what the waybar config prints
    // and it is passed straight through. hwmon reports rpm instead, which only
    // means something against a ceiling, in this order: fan1_max where the
    // driver publishes one (amdgpu does, 3300 on the desktop), otherwise the
    // fastest this fan has ever been seen to spin, starting from a figure low
    // enough that a typical case fan at full tilt reads as full. The ceiling
    // only ever grows, so an early guess corrects itself and never un-corrects,
    // and it is never zero, so the division is always safe.
    Scope {
        id: fan

        readonly property int pct: Caps.fanSource === "fw" ? Sys.fan
            : Math.min(100, Math.round(100 * Sys.fan / ceiling))

        property int ceiling: 2000

        Process {
            running: true
            command: ["sh", "-c", "cat /sys/class/hwmon/hwmon*/fan1_max 2>/dev/null | sort -rn | head -1"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const max = parseInt(text) || 0;
                    if (max > fan.ceiling)
                        fan.ceiling = max;
                }
            }
        }

        Connections {
            target: Sys
            function onFanChanged() {
                if (Caps.fanSource !== "fw" && Sys.fan > fan.ceiling)
                    fan.ceiling = Sys.fan;
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

    // The keybind itself. Registered over hyprland-global-shortcuts-v1, so the
    // press arrives in this process; `bind = ..., global, quickshell:launcher`
    // in his hyprland config points at it. The IpcHandler above stays for the
    // command line, but the hot path forks no `qs` client.
    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        description: "Toggle the application launcher"
        onPressed: launcher.open ? launcher.hide() : launcher.show()
    }

    // ---- looks --------------------------------------------------------------
    // Themes and wallpapers. It was a button on the rail and a page in the
    // 430px panel, and it was wrong on both counts: a wallpaper grid that
    // narrow gets three thumbnails to a row, and a button that permanently
    // costs a rail slot to change something he changes twice a month is a slot
    // spent on nothing. So it is the launcher's shape instead — a centred
    // overlay on a keybind — and the control centre carries the button for the
    // times he does not remember the key.
    LooksWindow { id: looksWin }

    IpcHandler {
        target: "looks"
        function toggle(): void { looksWin.open ? looksWin.hide() : looksWin.show(); }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "looks"
        description: "Toggle the themes and wallpapers overlay"
        onPressed: looksWin.open ? looksWin.hide() : looksWin.show()
    }

    // The volume and brightness card at the bottom of the screen.
    Osd {}

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
