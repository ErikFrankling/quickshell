import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Drag the screens into place, centred like looks:
//   qs -p <repo> ipc call displays toggle
//
// Survey: docs/surveys/monitor-arrangement.md. The canvas, the glue snap and
// the frozen zoom while dragging are its section 11 sketch (ilyamiro's
// perimeter snap, displaywright's held box).
//
// Applying has two roads because the machines differ. Where kanshi runs (the
// laptops) it owns every output it configured, and Hyprland ignores an
// `hl.monitor` eval for them for the whole session (survey section 0, point
// 3; checked live on samsung-ablo). There the window writes kanshi's position
// defaults to ~/.local/state/kanshi/positions, which the dotfiles' kanshi
// config includes, and runs `kanshictl reload`; that is also what keeps it
// across replugs and reboots. Without that file (the pc) it is a live
// `hl.monitor` eval, gone on the next reload.
PanelWindow {
    id: root

    property bool open: false
    // Layout in Hyprland logical px: {name, crit, x, y, w, h, mode, scale, transform}.
    property var mons: []
    property var live: []      // as read when the window opened; Revert target
    property string status: ""

    visible: root.open
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "displays"
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }

    function show() {
        root.status = "";
        root.live = [];
        positions.reload();
        reader.running = true;
        root.open = true;
        card.forceActiveFocus();
    }

    function hide() {
        root.open = false;
    }

    function bounds(list) {
        if (!list.length)
            return { x: 0, y: 0, w: 1920, h: 1080 };
        const x = Math.min(...list.map(m => m.x)), y = Math.min(...list.map(m => m.y));
        return { x, y, w: Math.max(...list.map(m => m.x + m.w)) - x, h: Math.max(...list.map(m => m.y + m.h)) - y };
    }

    function overlaps(a, b) {
        return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
    }

    // Glue r onto the nearest side of another screen, then align the free axis
    // (start, end, centre) within t. Never an overlapping spot, never a gap.
    function glue(r, others, t) {
        let best = null;
        for (const o of others) {
            const sides = [ // [xMin, xMax, yMin, yMax] for r's top-left
                [o.x - r.w + 1, o.x + o.w - 1, o.y - r.h, o.y - r.h], // above
                [o.x - r.w + 1, o.x + o.w - 1, o.y + o.h, o.y + o.h], // below
                [o.x - r.w, o.x - r.w, o.y - r.h + 1, o.y + o.h - 1], // left
                [o.x + o.w, o.x + o.w, o.y - r.h + 1, o.y + o.h - 1]  // right
            ];
            for (const s of sides) {
                let x = Math.max(s[0], Math.min(r.x, s[1]));
                let y = Math.max(s[2], Math.min(r.y, s[3]));
                if (s[0] !== s[1])
                    for (const a of [o.x, o.x + o.w - r.w, o.x + (o.w - r.w) / 2])
                        if (Math.abs(x - a) < t) x = a;
                if (s[2] !== s[3])
                    for (const a of [o.y, o.y + o.h - r.h, o.y + (o.h - r.h) / 2])
                        if (Math.abs(y - a) < t) y = a;
                const c = { x: Math.round(x), y: Math.round(y), w: r.w, h: r.h };
                const d = Math.hypot(c.x - r.x, c.y - r.y);
                if ((!best || d < best.d) && !others.some(q => root.overlaps(c, q)))
                    best = { x: c.x, y: c.y, d };
            }
        }
        return best;
    }

    function move(i, x, y, t) {
        const others = root.mons.filter((_, j) => j !== i);
        const p = others.length ? root.glue({ x, y, w: root.mons[i].w, h: root.mons[i].h }, others, t) : { x, y };
        if (!p)
            return;
        const next = root.mons.slice();
        next[i] = Object.assign({}, root.mons[i], { x: p.x, y: p.y });
        root.mons = next;
    }

    function apply(list) {
        const b = root.bounds(list);
        if (positions.loaded) {
            // One `output "<criteria>" position X,Y` line per screen; lines of
            // screens not plugged in now stay as they were.
            const lines = {};
            for (const l of positions.text().split("\n")) {
                const m = l.match(/^output "(.*)" position/);
                if (m)
                    lines[m[1]] = l;
            }
            for (const m of list)
                lines[m.crit] = `output "${m.crit}" position ${m.x - b.x},${m.y - b.y}`;
            positions.setText(Object.values(lines).join("\n") + "\n");
            applier.command = ["kanshictl", "reload"];
        } else {
            applier.command = ["hyprctl", "eval", list.map(m =>
                `hl.monitor({ output = "${m.name}", mode = "${m.mode}", position = "${m.x - b.x}x${m.y - b.y}", `
                + `scale = ${m.scale}, transform = ${m.transform} })`).join("; ")];
        }
        root.status = "";
        applier.running = true;
    }

    // Absent on the pc, and that absence is what picks the eval road.
    FileView {
        id: positions
        path: Quickshell.env("HOME") + "/.local/state/kanshi/positions"
        blockLoading: true
        printErrors: false
    }

    Process {
        id: reader
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                // An empty description is a headless output (AGENT-1).
                const list = JSON.parse(text)
                    .filter(o => !o.disabled && o.description !== "" && o.mirrorOf === "none")
                    .map(o => {
                        const rot = o.transform % 2 === 1;
                        return {
                            name: o.name,
                            label: `${o.make} ${o.model.trim()}`,
                            // How the kanshi profiles name it; kanshi matches defaults by the exact string.
                            crit: o.name.startsWith("eDP") ? o.name : `${o.make} ${o.model.trim()} *`,
                            x: o.x, y: o.y,
                            w: Math.round((rot ? o.height : o.width) / o.scale),
                            h: Math.round((rot ? o.width : o.height) / o.scale),
                            mode: `${o.width}x${o.height}@${o.refreshRate.toFixed(3)}`,
                            scale: o.scale, transform: o.transform
                        };
                    });
                root.mons = list;
                if (!root.live.length)
                    root.live = list;
            }
        }
    }

    Process {
        id: applier
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "ok" && text.trim() !== "") root.status = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.status = text.trim()
        }
        onExited: reread.restart()
    }

    // Show what the compositor really did, once kanshi has applied.
    Timer { id: reread; interval: 800; onTriggered: reader.running = true }

    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(900, parent.width - 120)
        height: Math.min(600, parent.height - 120)
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.line
        focus: true
        Keys.onEscapePressed: root.hide()

        MouseArea { anchors.fill: parent } // keep clicks off the dismiss layer

        Text {
            id: title
            anchors { left: parent.left; top: parent.top; margins: 18 }
            text: "Displays"
            color: Theme.fg
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        Item {
            id: view
            anchors { fill: parent; margins: 28; topMargin: 60; bottomMargin: 76 }
            // Fitted to the layout, and frozen while a tile is held or the
            // zoom and origin move under the pointer.
            property var heldBox: null
            readonly property var box: heldBox ?? root.bounds(root.mons)
            readonly property real zoom: Math.min(width / box.w, height / box.h)
            readonly property real ox: (width - box.w * zoom) / 2 - box.x * zoom
            readonly property real oy: (height - box.h * zoom) / 2 - box.y * zoom

            Repeater {
                model: root.mons.length // an int: a new array keeps the delegates, and the drag, alive

                Rectangle {
                    id: tile
                    required property int index
                    readonly property var m: root.mons[index]
                    x: view.ox + m.x * view.zoom
                    y: view.oy + m.y * view.zoom
                    width: m.w * view.zoom
                    height: m.h * view.zoom
                    radius: Theme.radiusS
                    color: grip.pressed ? Theme.bgHi : Theme.bgAlt
                    border.width: grip.pressed ? 2 : 1
                    border.color: grip.pressed ? Theme.accent : Theme.line

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        color: Theme.fg
                        text: `${tile.m.label}\n${tile.m.name}  ${tile.m.w}×${tile.m.h}`
                    }

                    MouseArea {
                        id: grip
                        anchors.fill: parent
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        property point start
                        property point press
                        onPressed: mouse => {
                            view.heldBox = view.box;
                            start = Qt.point(tile.m.x, tile.m.y);
                            press = mapToItem(view, mouse.x, mouse.y);
                        }
                        onPositionChanged: mouse => {
                            const p = mapToItem(view, mouse.x, mouse.y);
                            root.move(tile.index, start.x + (p.x - press.x) / view.zoom,
                                      start.y + (p.y - press.y) / view.zoom, 16 / view.zoom);
                        }
                        onReleased: view.heldBox = null
                        onCanceled: view.heldBox = null
                    }
                }
            }
        }

        Text {
            anchors { left: parent.left; right: buttons.left; bottom: parent.bottom; margins: 24 }
            elide: Text.ElideRight
            color: Theme.bad
            text: root.status
        }

        component TextBtn: Rectangle {
            property string label
            signal clicked
            width: 96
            height: 32
            radius: Theme.radiusS
            color: area.containsMouse ? Theme.line : Theme.bgAlt
            Text { anchors.centerIn: parent; text: parent.label; color: Theme.fg }
            MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
        }

        Row {
            id: buttons
            anchors { right: parent.right; bottom: parent.bottom; margins: 20 }
            spacing: 8
            TextBtn { label: "Revert"; onClicked: { root.mons = root.live; root.apply(root.live); } }
            TextBtn { label: "Apply"; onClicked: root.apply(root.mons) }
        }
    }
}
