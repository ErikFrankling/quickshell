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
                    case "control": return clockCol;
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

                // Which page the control centre opens on. The clock is its
                // button and lands on the notifications; the tray's overflow
                // count is the one other thing that opens it, and it means the
                // tray. Set before openAt, read once by the Loader below, and
                // then owned by the panel's own tab strip.
                property string controlPage: "notifs"

                // A tunnel is any link with no hardware under it, which is
                // what Net matches on. `ip link show tun0` was one interface
                // name out of the several a tunnel can have, and on this
                // machine — where the tunnel is CloudflareWARP — it answered
                // no while the VPN was up.
                readonly property bool vpn: Net.vpn

                // Click anywhere off the card to dismiss. Declared first so the
                // rail and the card sit above it.
                MouseArea {
                    anchors.fill: parent
                    enabled: win.open
                    onClicked: win.page = ""
                }

                // ---- rail ---------------------------------------------------
                // The rail is a slab: square into all four screen edges, with
                // exactly one curve on its outline, where the workspaces end. It
                // used to round its own two right corners as well, so the top
                // hundred pixels showed three curves against the screen and none
                // of them meant anything.
                //
                // That is a statement about the rail's silhouette and only about
                // its silhouette. The clusters inside it keep their rounded
                // grounds — see Group — because "where does this surface end"
                // and "which of these controls belong together" are two
                // questions and a bar has to answer both. Squaring the outline
                // is what stops the rail looking like a floating card; grounding
                // the clusters is what stops it looking like one long strip.
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
                    // indicator. So the ladder below is this shell's own, and it
                    // is an order of who gives first:
                    //
                    //   1. Nothing. The workspaces stand at their full natural
                    //      height while any slack remains anywhere on the rail.
                    //   2. The metrics' centring. The group slides off the
                    //      rail's midpoint, upward, until it is sitting on the
                    //      player.
                    //   3. The metrics themselves. The block caps at what is
                    //      left and a chevron says the rest is behind it — and
                    //      the block is already the button that opens the panel
                    //      showing every one of them in full.
                    //   4. The tray, into the control centre behind a +N.
                    //   5. Only then the workspaces, which scroll with the
                    //      focused pill kept in view.
                    //
                    // The clock is not on this list and never gives.
                    //
                    // The workspaces used to be step 1 rather than step 5, on
                    // the reasoning that they are the most numerous thing here
                    // and the only one with a natural order to scroll through.
                    // Erik overruled it: the workspaces are what he navigates
                    // by, and the rings are a readout he can lose the tail of.
                    // Being numerous made them the easiest thing to take height
                    // from, not the right one.
                    //
                    // Height minus the 8px margin under the clock. There is no
                    // margin above: the workspaces run into the top edge.
                    readonly property int inner: rail.height - 8

                    // What the bottom of the rail costs, with the tray at
                    // nothing: the player, the radios, the clock, and the two
                    // gaps between those three.
                    //
                    // Two gaps, counted rather than assumed. The boundaries
                    // above the player and above the metrics are both spacers
                    // that grow, so they are slack and not height owed to
                    // anybody; only player-to-radios and radios-to-clock are
                    // fixed. This used to say four, which quietly held eight
                    // pixels back for a gap that was never drawn.
                    //
                    // The groups pinned to the bottom are measured by their
                    // grounds, not by their contents, because the ground is what
                    // occupies the rail — Theme.groupPad of air above and below
                    // each cluster is height nothing else can have.
                    //
                    // Wifi and bluetooth, and nothing else. This used to bill a
                    // third slot and a third gap whenever the tunnel was up, and
                    // that is 33px the rail has not owed since the tunnel became
                    // a padlock tucked into the corner of the network glyph
                    // rather than a button of its own — "It is a mark, not a
                    // slot", networkBtn below. Nothing could spend those 33px
                    // and nothing could see them either: they came off `elastic`
                    // and reappeared in the fillHeight spacer as dead air, so
                    // the rail would clip the workspaces while visibly holding
                    // a gap open above the player.
                    readonly property int stack:
                        playerGroup.implicitHeight + clockGroup.implicitHeight
                        + Theme.slot * 2
                        + Theme.slotGap
                        + Theme.groupPad * 2
                        + Theme.groupGap * 2

                    // The metrics' floor. Two rings and the block's own padding:
                    // cpu and ram are the pair /proc answers for on every host,
                    // so they are the two that are always there to keep, and a
                    // metrics block scrolled down to one ring is worse than no
                    // metrics block at all.
                    readonly property int ringMin: Theme.slot * 2 + 9 + 12
                    // Their natural height, before the rail has any say.
                    readonly property int ringNat: rings.implicitHeight + 12

                    // How tall the workspaces may stand. Everything below them
                    // at its own minimum, which is the whole bottom stack plus
                    // two rings and no tray at all — so this only ever bites on
                    // a screen too short to hold the workspaces and a legible
                    // clock at once, and it exists so that the thing that gives
                    // there is still not the clock. Counted against constants
                    // rather than against `elastic`: the budget below is derived
                    // from the workspaces' height, so reading it back here would
                    // close the loop.
                    readonly property int wsMax: Math.max(Theme.slot + 16,
                        rail.inner - rail.stack - rail.ringMin)

                    // The workspaces are paid first and in full. Erik navigates
                    // by them and has at most ten; they are not the rail's
                    // shock absorber and asking them to be one was this budget's
                    // first mistake, above whichever arithmetic went with it.
                    readonly property int fixed:
                        wsBlock.implicitHeight + rail.stack
                    // What the tray and the metrics have to share, and whatever
                    // neither of them wants is the slack the centring spends.
                    readonly property int elastic: Math.max(0, rail.inner - rail.fixed)
                    // The tray is served first but never all of it: two rings'
                    // worth is held back, so the rail always still says what the
                    // machine is doing. Each icon is a 26px cell over the
                    // column's own gap.
                    readonly property int trayCell: 26 + Theme.slotGap
                    readonly property int trayMax: Math.max(0,
                        Math.floor((rail.elastic - rail.ringMin) / rail.trayCell))
                    // How many cells the tray gets, and how many of them are
                    // icons. When the rail cannot hold them all the last cell
                    // carries the count instead of an icon, so saying how many
                    // are missing never costs the height that lost them.
                    readonly property int trayCells:
                        Math.min(rail.trayMax, Pins.railTray.length)
                    readonly property int trayShown:
                        rail.trayCells < Pins.railTray.length
                            ? Math.max(0, rail.trayCells - 1) : rail.trayCells
                    readonly property int trayHidden:
                        Pins.railTray.length - rail.trayShown
                    // And the metrics take whatever the tray left. Counted
                    // rather than measured: the icons are delegates of a
                    // Repeater inside the column this budget also pays for, so
                    // reading its height back would close the loop.
                    readonly property int ringRoom: Math.max(0, rail.elastic
                        - rail.trayCells * rail.trayCell)

                    // The metrics are the one group pinned to neither end. Erik
                    // wants them at the middle of the rail with air on both
                    // sides rather than riding on top of the player, so the gap
                    // above them is whatever puts their middle on the rail's
                    // middle — and never more than the room the rings did not
                    // themselves use, because that leftover is the only height
                    // on the rail the ladder above has not already promised to
                    // somebody.
                    //
                    // This is the second thing to give and it gives from the
                    // top: the gap above the metrics is the measured one and the
                    // gap below them is the fillHeight spacer that takes the
                    // rest, so as the slack runs out the metrics slide *up*
                    // toward the workspaces rather than the two gaps closing
                    // evenly. Splitting it evenly would cost the workspaces
                    // half of every pixel the centring wants, for a symmetry
                    // nobody can see once the group is off centre anyway. Full
                    // rail, no leftover, no gap: the metrics settle back onto
                    // the stack below them and the rail degrades to exactly the
                    // column it was before, rather than centring something off
                    // the bottom of the screen.
                    readonly property int ringGap: Math.max(0, Math.min(
                        Math.round(rail.height / 2 - ringBox.implicitHeight / 2
                            - wsBlock.implicitHeight),
                        rail.ringRoom - ringBox.implicitHeight))

                    // ---- the seam -------------------------------------------
                    // The rail's one curve sits on its right edge, and its right
                    // edge is also where a panel attaches. A card that runs the
                    // whole screen turns that edge from an outline into a seam:
                    // there is no desktop on the far side of it any more for the
                    // corner to curve away from. That is 883538b's rule read
                    // from the rail's side rather than the card's — a surface
                    // running into another surface does not have a corner there
                    // — so the rail drops its curve exactly when the card drops
                    // the two it would have met.
                    //
                    // Deliberately the card's own predicates and not a fresh
                    // measurement of the card's height. They already engage only
                    // where the free position equals the bound, so a panel that
                    // grows into full height slides into the edge instead of
                    // jumping to it, and the rail inherits that: the curve goes
                    // at the same instant the card's fillets do, and a list
                    // populating cannot make the two disagree for a frame.
                    readonly property bool seamed: card.visible
                        && card.squareTop && card.squareBottom

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.bottomMargin: 8
                        spacing: 0

                        // The workspaces, and the rail's one curve.
                        //
                        // Its ground is the one every other group copies —
                        // Theme.bgHi, see Group — so what sets this block apart
                        // is its shape rather than its colour. It is full width
                        // and runs square into the top and left screen edges,
                        // and its bottom right corner is the single curve on the
                        // rail's outline — the boundary between
                        // where he is and what the machine is doing. Zaphkiel
                        // stacks two rectangles into one block the same way,
                        // rounding the outside pair and squaring the pair where
                        // the sections meet (Widgets/CalendarView.qml:22-27,
                        // 42-47); skwd's DropdownTail.qml:34-37 squares exactly
                        // the one corner that touches the bar.
                        //
                        // It is also the *last* thing on the rail to give. It
                        // stands at its natural height and keeps standing there
                        // while the metrics' centring, the metrics themselves
                        // and the tray all yield in front of it; only on a
                        // screen too short to hold ten pills, two rings and a
                        // clock at once does it stop growing and scroll instead.
                        // On his 1080px screen that is twenty-four workspaces,
                        // so in practice this never engages and the block below
                        // behaves exactly as a plain column of pills.
                        //
                        // It is kept rather than deleted because deleting it
                        // does not make the overflow go away, it just moves who
                        // it lands on: an unbounded block pushes the clock off
                        // the bottom of a short screen, and the clock going
                        // quietly is the one thing that was never up for
                        // negotiation. Two things make the scroll safe rather
                        // than merely tidy: the focused pill is scrolled back
                        // into view whenever it moves, so the workspace he is
                        // actually on is never the one that went away, and a
                        // chevron sits over each edge that has more behind it,
                        // so a short list and a scrolled list never look alike.
                        Rectangle {
                            id: wsBlock

                            Layout.fillWidth: true
                            implicitHeight: wsBox.implicitHeight + 16
                            color: Theme.bgHi
                            // Gone while a full-height panel is against the
                            // rail — see rail.seamed. Eased on the card's own
                            // 150ms so the curve leaves with the panel that
                            // took it rather than snapping a frame later.
                            bottomRightRadius: rail.seamed ? 0 : Theme.radius
                            Behavior on bottomRightRadius {
                                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                            }
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
                                    Math.max(Theme.slot, rail.wsMax - 16))

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

                        // The two gaps that do the work. The first is measured,
                        // and puts the metrics on the rail's midpoint; the
                        // second is whatever is left, which is what holds the
                        // player, the radios and the clock down at the bottom.
                        // Which is also why the centring gives from the top:
                        // this one is clamped and that one is fillHeight, so
                        // pressure closes this gap and opens that one, and the
                        // metrics rise toward the workspaces instead of the
                        // group's air being shaved off both ends at once.
                        Item { Layout.preferredHeight: rail.ringGap }

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
                        // the numbers almost none of their contrast, because
                        // the wash is 12% of one step rather than a swap to a
                        // fully saturated fill.
                        //
                        // Erik pointed at that and asked for it on the other
                        // four things down the rail that open a panel, so the
                        // drawing lives in OpenGround now and this is one of its
                        // five callers rather than the only one. The shells read
                        // for it agree there is no single answer — whisker fills
                        // a quick-toggle with the primary colour (QuickPanel
                        // .qml:21-78), Zaphkiel scales the active glyph 1.6x and
                        // draws no ground at all (CentralSwipable.qml:52-67),
                        // and noctalia's bar pill has no open-panel state
                        // whatsoever, only hover (BarPillVertical.qml:62-65) —
                        // and none of them has a block this tall to fill: this
                        // one measures 262px on his desktop.
                        //
                        // This block *is* the metrics group's ground: it is
                        // already Theme.groupWidth wide, Theme.radiusS round and
                        // padded Theme.groupPad, which is a Group in everything
                        // but name. So it hands OpenGround Theme.bgHi as its
                        // resting colour rather than nothing, and the wash is
                        // composited over that ground rather than left to blend
                        // with the bare rail behind it. A half-transparent
                        // accent laid straight over an opaque resting colour
                        // would render *darker* than the resting colour, so
                        // opening the panel would dim the block instead of
                        // lighting it.
                        //
                        // This is the elastic thing on the rail now, and the
                        // first to give after the centring: its natural height
                        // while the rail can pay for it, and what is left when
                        // it cannot. It caps rather than scrolls, which is the
                        // one place this block deliberately does not copy the
                        // workspaces below. There is no focused ring for a
                        // follow() to keep in view, so a scroll position here
                        // would be a thing to manage with nothing to aim it at;
                        // and a Flickable would have to sit above ringMa to see
                        // the wheel at all, which puts a scroll surface on top
                        // of the click target that already opens the panel
                        // showing every one of these metrics in full. Capping
                        // costs one `clip` and keeps the press.
                        //
                        // It drops from the bottom, so the order the rings are
                        // declared in is the order they are kept in: cpu and ram
                        // first because /proc answers for those two on every
                        // host, then whatever this machine has sensors for, and
                        // the battery last. It never drops below rail.ringMin.
                        // The chevron is the same affordance the workspaces
                        // carry, in this block's own resolved colour so it
                        // follows the open and hover washes rather than sitting
                        // as a flat Theme.bgHi patch on top of them.
                        OpenGround {
                            id: ringBox

                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: Theme.groupWidth
                            implicitHeight: Math.min(rail.ringNat,
                                Math.max(rail.ringMin, rail.ringRoom))
                            on: win.page === "monitor"
                            ground: Theme.bgHi
                            hovering: ringMa.containsMouse
                            clip: true

                            ColumnLayout {
                                id: rings
                                anchors.top: parent.top
                                anchors.topMargin: 6
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
                                //
                                // The word "ram" used to appear only when the
                                // total was unknown, which meant the one ring
                                // that could say what it was never did. It says
                                // both now, on one caption row: "ram 31", 29px
                                // of 8px type on a 50px ground.
                                Ring {
                                    label: Sys.memTotalGb > 0
                                        ? "ram " + Math.round(Sys.memTotalGb)
                                        : "ram"
                                    value: Sys.mem
                                    text: Math.round(Sys.memUsedGb)
                                }
                                Ring { label: "gpu"; value: Sys.gpu; visible: Sys.hasGpu }
                                Ring { label: "°c"; value: Sys.temp; text: Sys.temp; visible: Sys.hasTemp }
                                Ring { label: "fan"; value: fan.pct; visible: Sys.hasFan }
                                // Capacity, not throughput — the disk graphs in
                                // the monitor panel already draw what is moving.
                                // One ring per mount Caps found, so the machine
                                // with two disks gets two and the laptop with
                                // one gets one. Waybar's own disk thresholds
                                // (config.jsonc:129-132).
                                //
                                // Gigabytes rather than a percentage, for the
                                // same reason memory reads in gigabytes: "95" is
                                // a number you have to convert before you can
                                // act on it and "845" under "root 947" is not.
                                // The arc keeps the percentage, because df's
                                // Use% is what says how much more can be
                                // written.
                                //
                                // The mount leads the caption, because with two
                                // disks the question the ring has to answer
                                // first is which disk. Root is still spelled out
                                // rather than left as "/": nothing is turned any
                                // more so a lone slash is legal again and would
                                // save 4px, but "root 947" is a name and a size
                                // and "/ 947" is a slash with a gap in it.
                                //
                                // Only the last path segment, never the path.
                                // The whole path is in the monitor panel, which
                                // is a click away and 430px wide.
                                //
                                // "data 2.0T" is the widest caption on the rail
                                // at 44px of advance carrying 43px of ink, and
                                // it stays 2.0T. Writing it "2T" measures 34 and
                                // buys the look of room rather than room: "data
                                // 1.5T" is 44px again, so the abbreviation only
                                // helps a disk whose size happens to round to a
                                // whole terabyte — and rounding it for real
                                // would print "2T" over a 1.5 TB disk, which is
                                // the unactionable number this ring reads in
                                // gigabytes to avoid.
                                //
                                // What was done instead is that the ground grew
                                // to meet it: Theme.groupWidth is 50 and this
                                // caption now sits 3px in from its left edge and
                                // 4px from its right, where on the old 46 it
                                // sat 1px and 2px in and read as spilling. The
                                // workspace pill was quoted here as the
                                // precedent for 44px on this ground and it is
                                // not one — it is 44px on the *full-width*
                                // workspaces block (Workspaces.qml:158 inside
                                // wsBlock above, which is Layout.fillWidth), so
                                // it has 7px of rail either side and always had.
                                Repeater {
                                    model: Sys.disks
                                    Ring {
                                        required property var modelData

                                        // Three characters is what the middle
                                        // holds, so a disk past a terabyte reads
                                        // in terabytes and takes its caption
                                        // with it — 1.8 under "data 2.0T"
                                        // rather than a four-digit number in a
                                        // 20px hole.
                                        function short(gb: real): string {
                                            return gb >= 1000 ? (gb / 1000).toFixed(1)
                                                              : Math.round(gb);
                                        }

                                        readonly property string mount:
                                            modelData.path === "/" ? "root"
                                            : modelData.path.replace(/.*\//, "")

                                        text: short(modelData.usedGb)
                                        label: mount + " " + short(modelData.sizeGb)
                                             + (modelData.sizeGb >= 1000 ? "T" : "")
                                        value: modelData.pct
                                        warnAt: 90
                                        critAt: 95
                                        blink: true
                                    }
                                }
                                // Full is the good end of this one, so it hands
                                // the ring the distance to empty and names its
                                // lines in the charge he reads off it.
                                //
                                // And on mains the two facts trade places: the
                                // bolt takes the middle and the charge takes
                                // the caption's second word, in the same
                                // "name value" grammar the memory and disk rings
                                // now read in. "bat 100" is 34px, well inside
                                // the 44 the disks already spend.
                                //
                                // The glyph is nf-fa-bolt, U+F0E7 — the exact
                                // one his waybar prefixed to the AC-side format
                                // string (config.jsonc:55) and the only charging
                                // affordance that bar ever had, since style.css
                                // has no #battery.charging rule at all.
                                //
                                // Sys.charging is "not discharging" rather than
                                // strictly "Charging" (Sys.qml:378), so the bolt
                                // means on mains: it stays up at Full and at the
                                // "Not charging" a charge limit reports. That is
                                // the same fact the blink is already gated on,
                                // and one fact with one name is worth more here
                                // than a finer distinction spelled two ways.
                                Ring {
                                    label: Sys.charging
                                        ? "bat " + Math.round(Sys.battery) : "bat"
                                    glyph: Sys.charging ? "" : ""
                                    value: Sys.battery
                                    heat: 100 - Sys.battery
                                    warnAt: 100 - Sys.batWarn
                                    critAt: 100 - Sys.batCrit
                                    blink: !Sys.charging
                                    visible: Sys.hasBattery
                                }
                            }

                            Rectangle {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: 10
                                color: ringBox.color
                                visible: rail.ringNat > ringBox.implicitHeight
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅀"
                                    color: Theme.accent
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: ringMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.openAt(ringBox, "monitor")
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // What is playing, at the head of the bottom stack. It
                        // used to sit hard against the metrics, on the grounds
                        // that both are read off the rail without touching it;
                        // the metrics have since floated off to the middle, and
                        // what is left down here is everything that is a
                        // control — the player, the radios, the tray, the clock.
                        Group {
                            id: playerGroup
                            RailPlayer {
                                id: playerBtn
                                active: win.page === "player"
                                onActivated: win.openAt(playerBtn, "player")
                            }
                        }

                        Item { implicitHeight: Theme.groupGap }

                        // The bottom cluster, and the whole of what the rail
                        // keeps permanently: the tray he pinned, and the
                        // radios.
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
                        // clock, which is the control centre now, or out of the
                        // shell entirely: looks is its own overlay window.
                        //
                        // The arrow that used to open the control centre is
                        // gone with them. It was a button whose whole job was
                        // to be a button, sitting one slot above a clock that
                        // was already the right size to press.
                        Group {
                            id: bottomGroup

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
                                model: ScriptModel { values: Pins.railTray.slice(0, rail.trayShown) }
                                // Tray icons are a zoo of shapes and palettes; a
                                // consistent circular ground makes the column read
                                // as one set. Theme.bgAlt reads as a cell against
                                // the group's Theme.bgHi the same way it read
                                // against the bare rail before the group came
                                // back — a step away from what is behind it,
                                // which is all a cell needs to be.
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

                            // A pin the rail could not honour is not a pin
                            // lost: the tray page lists every tray item,
                            // pinned or not, so the icon is exactly one click
                            // from where it always was. The count says so,
                            // because a pinned icon that simply stopped
                            // appearing would read as a bug. It takes the last
                            // cell rather than a row of its own, which is the
                            // trade Windows' taskbar chevron makes and the one
                            // the rail can afford: the count cannot cost the
                            // height that caused it.
                            Rectangle {
                                id: trayMore

                                visible: rail.trayHidden > 0
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 26
                                implicitHeight: 26
                                radius: 13
                                color: moreMa.containsMouse ? Theme.accent : Theme.bgAlt

                                Behavior on color { ColorAnimation { duration: 110 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "+" + rail.trayHidden
                                    color: moreMa.containsMouse ? Theme.bg : Theme.accent
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    id: moreMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        win.controlPage = "tray";
                                        win.openAt(trayMore, "control");
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
                                // A disc, like the tray cells directly above it.
                                disc: true
                                // Three states, three shapes: this button says
                                // which link, and only which link. It used to
                                // swap to a shield whenever the tunnel was up,
                                // which meant the one moment the rail could not
                                // tell him wifi from ethernet was the moment he
                                // was on a VPN — and REQUIREMENTS asks for all
                                // four at once.
                                glyph: Net.glyph
                                open: win.page === "network"
                                tint: Net.online ? Theme.fg : Theme.bad
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

                                // The tunnel, as a padlock tucked into the
                                // corner of the link glyph. Erik picked this
                                // one off the sheet of sixteen in
                                // docs/surveys/network-glyph.md.
                                //
                                // It is a mark, not a slot: the whole point is
                                // that the link glyph is untouched, so
                                // ethernet, wifi and offline stay exactly as
                                // far apart with the tunnel up as without —
                                // where swapping the glyph for a shield or a
                                // key puts those three states zero pixels
                                // apart, which is why this was two slots
                                // before.
                                // Pulled in from the corner now the ground is
                                // round. A 26px disc centred in the 28px slot
                                // reaches 13px from the middle; the box corner
                                // the lock used to hang off is 19.8px out along
                                // the diagonal, so the old -1/-3 margins would
                                // leave it floating clear of the button
                                // entirely. 0/0 lands its centre at about 23,23
                                // — on the disc's own edge at half past four,
                                // which is where a corner mark belongs when the
                                // corner is a curve.
                                Text {
                                    visible: win.vpn
                                    anchors {
                                        right: parent.right
                                        bottom: parent.bottom
                                        rightMargin: 0
                                        bottomMargin: 0
                                    }
                                    text: "󰌾"
                                    font.pixelSize: 9
                                    // One colour, in every state. It used to
                                    // repaint itself Theme.bg while the panel
                                    // was open, because the button flooded solid
                                    // accent underneath it and Theme.good on the
                                    // accent is 1.00:1 on Everforest, 1.02 on
                                    // Nord, 1.20 on his Gruvbox — the lock
                                    // disappeared. The disc washes now instead
                                    // of flooding, and green on the washed disc
                                    // is 5.80 on Gruvbox, 4.33 on Everforest,
                                    // 7.24 on Tokyo Night and 3.01 on Gruvbox
                                    // Light, which is within a fifth of a point
                                    // of what it reads when the panel is shut.
                                    // So the branch goes, and the lock is green
                                    // for the same reason it always was.
                                    color: Theme.good
                                }
                            }

                            Btn {
                                id: btBtn
                                disc: true
                                glyph: Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
                                open: win.page === "bluetooth"
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

                        Item { implicitHeight: Theme.groupGap }

                        // The clock, and the control centre behind it. The time
                        // stacks and the date sits beside it as a fraction, so
                        // this is a group of one 36px slot rather than the 92px
                        // stack of five lines it replaced — the tallest single
                        // thing on a rail that overflows on a laptop, for a date
                        // nobody could read twice.
                        //
                        // It used to open a month grid. That grid is deleted:
                        // no account is signed in, Erik keeps his calendar in
                        // applications that have one, and a page of bare
                        // numbers was a page. What the clock opens now is
                        // everything the arrow above it used to — notifications,
                        // volume, the tray — because a clock is already the
                        // biggest press target on the rail and it was spending
                        // that on the least.
                        Group {
                            id: clockGroup
                            RailClock {
                                id: clockCol
                                active: win.page === "control"
                                // The bell's job, minus the bell. The arrow
                                // carried this count and the arrow is gone; the
                                // notifications are still the first thing behind
                                // this button, so the count still belongs on it.
                                badge: Notifs.unread
                                onActivated: {
                                    win.controlPage = "notifs";
                                    win.openAt(clockCol, "control");
                                }
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
                    // The room an inverted corner needs: it is drawn a whole
                    // radius outside the card, so a card with less than this
                    // between it and a screen edge cannot draw the one on that
                    // side.
                    readonly property int edge: Theme.radius
                    // The card may run the whole screen. It used to stop
                    // `Theme.pad + Theme.radius` short at each end so the
                    // fillets always had room, which meant a tall panel was
                    // shoved 34px off the bottom of the screen and left a
                    // sliver of wallpaper under it. That sliver reads as a
                    // mistake, and it is: the gap existed to protect a curve
                    // that only matters when the card is floating. Against a
                    // screen edge the honest shape is no curve at all.
                    readonly property int room: win.height
                    x: Theme.rail
                    // Centred on the rail item that opened the page, so the
                    // junction lands on the button you pressed, then clamped
                    // to the screen. That is the sum noctalia does for a
                    // vertical bar in SmartPanel's setPosition(): centre on the
                    // button, then Math.max(top, Math.min(y, bottom - height)),
                    // with the screen centre standing in when there is no
                    // button. Unlike noctalia's, which runs once and keeps the
                    // answer, this is a binding all the way down to the opener.
                    //
                    // The clamp is to 0 and win.height - height rather than to
                    // an inset, so a card that has to move to fit arrives
                    // *flush* against the edge it was moved off. Position stays
                    // continuous across that transition: the clamp only engages
                    // at the moment the free position equals the bound, so a
                    // panel growing while open slides into the edge rather than
                    // jumping to it.
                    //
                    // Whole pixels: a half-pixel card edge puts a seam of
                    // antialiasing where the fillet meets the rail.
                    y: {
                        const mid = win.anchorY >= 0 ? win.anchorY : win.height / 2;
                        return Math.round(Math.max(0,
                            Math.min(mid - card.height / 2,
                                     win.height - card.height)));
                    }
                    width: Theme.panel * win.p
                    // The floor keeps a page that has not reported a size yet
                    // from flashing past as a sliver.
                    height: Math.min(room, Math.max(200,
                        (pageLoader.item ? pageLoader.item.implicitHeight : 0) + inset * 2))

                    // Which fillets there is room to draw. A corner is dropped
                    // exactly when the screen edge would start cutting it —
                    // Erik's rule, "as soon as the gap is so small that the
                    // inverted corner touches the end of the screen" — so a
                    // fillet is never drawn clipped, and a card clamped at both
                    // ends is full height with both squared off.
                    readonly property bool squareTop: card.y < card.edge
                    readonly property bool squareBottom:
                        win.height - (card.y + card.height) < card.edge

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
                        squareTop: card.squareTop
                        squareBottom: card.squareBottom
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

                        // Scrolling belongs to the card, not to the pages.
                        //
                        // Only the wifi list scrolled before, because it is the
                        // only page that thought to put a ListView in itself,
                        // and every other page simply lost whatever did not fit
                        // to the clip above. A page cannot be the right place to
                        // decide this: how much room it has is the card's
                        // business, it changes with the screen and with what the
                        // page itself has loaded, and a page that forgets is a
                        // page that silently hides content.
                        //
                        // So the card gives every page the height it asked for
                        // and scrolls it when the screen cannot pay. Pages that
                        // fit are untouched: `interactive` is false and the
                        // Flickable is inert, exactly as the workspace list is
                        // when the rail is not full.
                        //
                        // Two of the fifteen shells read do it at the container
                        // like this — Brainitech's PopupPage.qml wraps a
                        // `default property alias content` in a Flickable with
                        // an as-needed scrollbar, and whisker's BaseMenu.qml
                        // does the same for all ten of its settings pages.
                        // Everyone else makes the page opt in, and noctalia
                        // shows what that costs: its panel Loader
                        // (SmartPanel.qml:1311-1317) neither scrolls nor clips,
                        // each page has to reach for NScrollView itself, and
                        // nine of its panels never do — so an oversized one
                        // simply runs out of the box the clamp put it in.
                        //
                        // The `max(viewport, content)` on the Loader below is
                        // the other half: a page with no child absorbing slack
                        // used to have the old fixed 976px split between its
                        // layout children, which pushed the bottom of it out of
                        // sight.
                        Flickable {
                            id: body

                            x: card.inset
                            y: card.inset
                            width: Theme.panel - card.inset * 2
                            height: card.height - card.inset * 2
                            contentWidth: width
                            contentHeight: pageLoader.item ? pageLoader.item.implicitHeight : 0
                            clip: true
                            interactive: contentHeight > height
                            boundsBehavior: Flickable.StopAtBounds

                            // A fresh page starts at the top, and a page that
                            // shrinks under a scrolled viewport is pulled back
                            // into it rather than left showing empty space.
                            Connections {
                                target: win
                                function onShownChanged() { body.contentY = 0; }
                            }
                            onContentHeightChanged: returnToBounds()

                            Loader {
                                id: pageLoader
                                width: body.width
                                // The page is as tall as it asked to be, or as
                                // tall as the viewport when it asked for less —
                                // the second half is what lets a page put a
                                // fillHeight spacer in itself and have it mean
                                // "the rest of the card" rather than "the rest
                                // of the screen".
                                height: Math.max(body.height, body.contentHeight)
                                active: win.shown !== ""
                                sourceComponent: win.shown === "monitor" ? cMonitor
                                    : win.shown === "network" ? cNetwork
                                    : win.shown === "bluetooth" ? cBluetooth
                                    : win.shown === "player" ? cPlayer
                                    : win.shown === "control" ? cControl : null
                            }
                        }

                        // The scrollbar, and only when there is something to
                        // scroll. Erik asked for one by name; the rail's own
                        // overflow uses chevrons because a 28px column has no
                        // room for a bar, but a 430px card does.
                        Rectangle {
                            id: scrollBar

                            readonly property real track: body.height - 8
                            readonly property real frac:
                                body.contentHeight > 0
                                    ? Math.min(1, body.height / body.contentHeight) : 1

                            visible: body.interactive
                            width: 3
                            radius: 1.5
                            color: Theme.line
                            x: body.x + body.width + 5
                            height: Math.max(24, scrollBar.track * scrollBar.frac)
                            y: body.y + 4 + (scrollBar.track - height)
                               * (body.contentHeight > body.height
                                  ? body.contentY / (body.contentHeight - body.height) : 0)
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
                            page: win.controlPage
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
                        id: card
                        required property var modelData
                        Layout.fillWidth: true
                        n: modelData
                        popup: true

                        // How long this one is allowed to stay, in ms, where 0
                        // is "until it is dismissed".
                        //
                        // Critical never expires, which is what dunst, mako and
                        // three of the thirteen shells surveyed do; a critical
                        // notification you can miss is not critical.
                        //
                        // Everything else starts from what the sender asked
                        // for, which used to be thrown away entirely: measured
                        // before this change, `notify-send -t 20000` was on
                        // screen for 6.7 seconds. 0 means never expire and is
                        // honoured — four of the five shells that read the
                        // field at all fold 0 into their default instead, which
                        // takes down the one popup that asked to stay.
                        //
                        // The ask is a floor rather than an override. An
                        // application asking for longer means it; one asking
                        // for shorter is usually just repeating its toolkit's
                        // default and does not know he is mid-sentence. That is
                        // the same conclusion noctalia reached from the other
                        // direction, shipping respectExpireTimeout off by
                        // default (Commons/Settings.qml:679-682).
                        //
                        // 12s is longer than any of the thirteen — they run
                        // 3-8s — because this one is read while working, and
                        // the two things that make a long popup obnoxious are
                        // both handled: hovering one stops the clock, and four
                        // is still the most that can be on screen.
                        readonly property int life: {
                            const asked = modelData.timeout ?? -1;
                            if (modelData.urgency === "critical" || asked === 0)
                                return 0;
                            return Math.max(modelData.urgency === "low" ? 6000 : 12000, asked);
                        }

                        // Reaching for a popup must not lose it. A Timer starts
                        // its interval again from zero when `running` goes back
                        // true, so leaving the card grants a fresh full life
                        // rather than the remainder — the one-line version of
                        // hover-to-pause, and the one doannc2212 uses
                        // (notifications/NotificationData.qml:65-73). Resuming
                        // instead needs a paused flag, a timestamp pair and a
                        // remaining-time field, all to make a popup you just
                        // looked at leave sooner.
                        //
                        // HoverHandler rather than a MouseArea because the
                        // action buttons have MouseAreas of their own, and one
                        // underneath them would report the card un-hovered
                        // exactly while he is reaching for Reply.
                        HoverHandler { id: hov }

                        Timer {
                            running: card.life > 0 && !hov.hovered
                            interval: card.life
                            onTriggered: Notifs.dismissPopup(modelData.key)
                        }
                    }
                }
            }
        }
    }
}
