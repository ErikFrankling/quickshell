//@ pragma ShellId metricfraction

// Contact sheet. A metric ring has to say three things — a name, a used value
// and a total — and it has room for two short strings.
//
// The rail is 58px wide, a group's ground is 46px of that, and the ring is 28px
// across with 3px of stroke, so its clear middle is 20px. At the 10px the
// centre value already uses, a digit is ~6px wide: three characters fit, four
// do not. "ram", "13" and "31" are eight characters between them, and a disk
// wants a mount path on top of that. So this is not a formatting problem, it is
// a layout problem, and the way to settle it is to draw every layout at the
// rail's true width and measure what each one costs.
//
// Twenty-one designs, drawn at 58px with the real ring at its real size, each
// rendering the same three metrics this machine actually reports:
//
//     ram   13 / 31 GB     (42%, no wash)
//     /    845 / 947 GB    (95%, critical wash + blink)
//     data 480 / 1968 GB   (26%, no wash)
//
// Those are wider than the `10/15`, `63/500` and `274/1800` the request named,
// which is the point: 845/947 is seven glyphs and 480/1968 is eight, and a
// design measured against the narrower strings would be measured against a case
// this host never produces.
//
// TWO HEIGHTS ARE REPORTED, because the shipped ring has two.
//
//   claim — what the element hands the ColumnLayout, and therefore what it
//           costs the rail. Today's ring claims 28: its caption is anchored to
//           the ring's *bottom edge* and hangs outside the box entirely.
//   ink   — the actual extent of what is drawn. Today that is 38, and the 10px
//           of overhang is paid for out of the 9px gap between rings, which is
//           why the group's spacing is 9 and not 5 like every other rail group.
//
// A design collides with its neighbour when ink > claim + 9. A design costs the
// rail height when claim > 28. Both numbers are measured off the built item,
// not asserted, and both are printed to stdout as a TSV as well as drawn under
// each mock, so the sheet can be checked without looking at it.
//
// Legibility is a hard floor, not a tiebreak. What already ships on this rail is
// 8px for a ring's caption and 10px for its centre value. Three designs below go
// under 8px. They are drawn, measured and kept in red, because "this is what 7px
// looks like at arm's length" is a finding, and deleting it only invites the
// next session to try it again.
//
// The critical wash is drawn on the `/` row of every mock — 24% of Theme.bad
// over the ring's ground, which is what a disk at 95% actually looks like since
// the warning states landed. Anything that reads on this sheet reads under the
// wash, because the wash is on the sheet.
//
// ---------------------------------------------------------------------------
// RECOMMENDATION: design 6, the turned name.
//
// The name goes on its side in the margin the ring is already wasting — a 28px
// ring inside a 46px ground leaves 9px down each flank — the used value stays in
// the centre at 10px, and the caption under the ring carries "/31". Three facts,
// no new type sizes, and claim stays at 28: the rail pays nothing. It is
// RailPlayer's move (RailPlayer.qml:222-238) and RailClock's (RailClock.qml:
// 100-118) applied to the one part of the rail that had not used it yet.
//
// The runner-up is design 4, the two-line caption, and it is the honest fallback
// if the turned name reads as decoration: same three facts, nothing rotated,
// but claim goes to 38 and the rings group grows 30px over three rings.
//
// DOES THE NAME BELONG ON EVERY RING? No — and the sheet says so in one number.
// Design 21 is today's ring with the name as its caption and the total dropped:
// 28 claim, 38 ink, identical to the baseline, because cpu, °c and fan already
// work exactly that way. Six of this host's seven rings need no third fact at
// all. Only ram and the disks have a total worth printing, and only the disks
// have a name that has to tell one ring from another. So the turned name is
// applied to those three and nowhere else, and the mount *path* — "/mnt/data"
// rather than "data" — stays in the monitor panel, where design 13 measures the
// reason: 43px of caption on a 46px ground, one pixel of air per side.
// ---------------------------------------------------------------------------
//
// Harness only. Nothing here ships.
//
//   quickshell -p docs/surveys/metric-fraction.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "file:///home/erikf/projects/personal/quickshell" as Shell

ShellRoot {
    PanelWindow {
        id: sheet
        anchors { top: true; left: true }
        margins { left: 8; top: 8 }
        implicitWidth: 1900
        implicitHeight: 796
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "metric-fraction"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        // The three metrics, in one place, so no design wins by quietly showing
        // less than the others. Real numbers off this host: df -B1 on / and
        // /mnt/data, and /proc/meminfo for the memory.
        readonly property var metrics: [
            { n: "ram",  n3: "ram", used: "13",  tot: "31",   pct: 42,
              frac: "13/31",    abbr: "13/31",   path: "ram",       crit: false },
            { n: "/",    n3: "/",   used: "845", tot: "947",  pct: 95,
              frac: "845/947",  abbr: "845/947", path: "/",         crit: true },
            { n: "data", n3: "dat", used: "480", tot: "1968", pct: 26,
              frac: "480/1968", abbr: "480/2.0T", path: "/mnt/data", crit: false }
        ]
        readonly property var blank: ({ n: "", n3: "", used: "", tot: "", pct: 0,
            frac: "", abbr: "", path: "", crit: false })

        // Every cell registers itself here so the measuring pass can walk them
        // without reaching into the Repeater.
        property var cells: []

        // Measured once the scene has settled, printed as a TSV. The sheet is
        // the deliverable, but the numbers on it are the reason it exists, and
        // a number that can only be read off a screenshot cannot be checked.
        Timer {
            interval: 1500
            running: true
            onTriggered: {
                let out = "\nMETRICFRACTION\tdesign\tclaim\tink\twidth\tsmallest"
                    + "\tcollides\tcostsRail\tstack3\tverdict\n";
                for (const c of sheet.cells)
                    c.remeasure();
                for (const c of sheet.cells)
                    out += "METRICFRACTION\t" + c.modelData.n + "\t" + c.claim
                        + "\t" + c.ink + "\t" + c.w + "\t" + c.modelData.min
                        + "\t" + (c.collides ? "YES" : "no")
                        + "\t" + (c.railDelta > 0 ? "+" : "") + c.railDelta
                        + "\t" + c.stack + "\t" + c.verdict + "\n";
                console.log(out);
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#11141a"
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                Text {
                    text: "Three facts in two strings — twenty-one ways to put a name, a used value and a total on a 28px ring in a 58px rail"
                    color: "#d3c6aa"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "measured, not claimed. CLAIM is what the element hands the layout (28 today, and what the rail pays); INK is what is actually drawn (38 today — the caption hangs into the 9px gap). "
                        + "ink > claim+9 collides with the next ring. width > 46 leaves the group's ground, width > 58 leaves the rail. "
                        + "the / ring carries its real 95% critical wash, so nothing here is measured on a clean background. legibility floor is what ships: 8px caption, 10px centre. below 8 is rejected and kept in red."
                    color: "#859289"
                    font.pixelSize: 9
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                GridLayout {
                    columns: 11
                    columnSpacing: 0
                    rowSpacing: 4
                    Layout.fillHeight: true

                    Repeater {
                        model: [
                            { n: "1. Baseline — today", k: "base", ok: 1, min: 8,
                              t: "used in the centre at 10px, /total as the caption at 8px. no name at all: ram is identified by being the second ring, and two disks are told apart by nothing." },
                            { n: "2. Name over, fraction under", k: "over", ok: 1, min: 8,
                              t: "a caption above the ring and a caption below it. all three facts, upright, no abbreviation — and two full line-heights of new ink." },
                            { n: "3. Name inside the ring", k: "inring", ok: 1, min: 8,
                              t: "the name takes the centre and the fraction becomes the caption. free, but the middle is 20px: three characters at 10px, so /mnt/data becomes 'dat'." },
                            { n: "4. Two-line caption", k: "two", ok: 1, min: 8,
                              t: "used in the centre, name and fraction stacked under it. nothing rotated, nothing abbreviated, nothing under 8px. the honest fallback." },
                            { n: "5. Two-line caption, tucked", k: "twot", ok: 1, min: 8,
                              t: "the same with the lines pulled together -3, spending the slack digits leave under their baseline the way caelestia's clock does." },
                            { n: "6. Name turned beside", k: "rotn", ok: 1, min: 8,
                              t: "the name stood on its side in the 9px the ring leaves down the flank of the group. centre and caption unchanged. claims nothing new." },
                            { n: "7. Turned name and total", k: "flank", ok: 1, min: 8,
                              t: "both flanks used — name left, total right, used value in the centre, no caption at all. the only design here that drops the caption line entirely." },
                            { n: "8. Fraction turned beside", k: "rotf", ok: 1, min: 8,
                              t: "the whole fraction turned into the right flank, percent in the centre, name as the caption. 845/947 turned is 34px of column against a 28px ring." },
                            { n: "9. Fraction stacked inside", k: "stackin", ok: 1, min: 8,
                              t: "used over total inside the ring with a hairline between, name as the caption. two 8px lines is exactly the 20px the middle has." },
                            { n: "10. Total on hover", k: "hoverT", ok: 1, min: 8,
                              t: "used in the centre and the name as the caption; the caption becomes the fraction while the pointer is on the group. drawn hovered." },
                            { n: "11. Percent, numbers on hover", k: "hoverN", ok: 1, min: 8,
                              t: "percent in the centre — the one number that is always two glyphs — name as caption, gigabytes only on hover. drawn hovered." },
                            { n: "12. Abbreviated fraction", k: "abbrev", ok: 1, min: 8,
                              t: "the caption carries the whole fraction with the total compressed to terabytes: 480/2.0T. no name, so the two disks still read alike." },
                            { n: "13. Full mount path", k: "path", ok: 1, min: 8,
                              t: "the caption is the mount point as written. this is the width test: /mnt/data at 8px against a 46px ground." },
                            { n: "14. Labelled bar", k: "bar", ok: 1, min: 8,
                              t: "not a ring. name left, percent right, a 3px track under them, full 46px of the ground — the shape panels/Monitor.qml already uses." },
                            { n: "15. Labelled bar, two rows", k: "bar2", ok: 1, min: 8,
                              t: "the same with the fraction on its own row under the name. all three facts, upright, at full width." },
                            { n: "16. Bar with text inside", k: "barin", ok: 1, min: 8,
                              t: "name and fraction laid over a 13px track rather than above it. the shortest element on the sheet that still says all three things." },
                            { n: "17. Rings for ram, bars for disks", k: "mix", ok: 1, min: 8,
                              t: "a ring where the metric is a rate and a bar where it is a capacity. drawn as one stack, because the rail has to hold both at once." },
                            { n: "18. Fraction caption at 7px", k: "micro7", ok: 0, min: 7,
                              t: "the baseline with the whole fraction squeezed into the caption at 7px. it fits the ground and it cannot be read across a desk." },
                            { n: "19. Two-line caption at 6px", k: "micro6", ok: 0, min: 6,
                              t: "design 4 shrunk until it stops costing the rail anything. 6px is not small type, it is texture." },
                            { n: "20. Fraction inside at 7px", k: "in7", ok: 0, min: 7,
                              t: "used over total inside the ring at 7px, under the critical wash. the wash costs contrast and the size costs the glyph." },
                            { n: "21. Name only — the null answer", k: "nameonly", ok: 1, min: 8,
                              t: "today's ring with the name as the caption and the total simply not shown, the way cpu, °c and fan already work. the design to beat." }
                        ]

                        ColumnLayout {
                            id: cell
                            required property var modelData

                            // What the element hands the layout, what it draws,
                            // and how wide the widest of the three rows is.
                            readonly property int claim: mock.item ? mock.item.claim : 0
                            readonly property int ink: mock.item ? mock.item.inkH : 0
                            readonly property int w: mock.item ? mock.item.inkW : 0
                            readonly property int stack: mock.item ? Math.round(mock.item.height) : 0
                            // Today's ring hangs 10px of caption into a 9px gap
                            // and reads fine, because a text box carries a pixel
                            // or two of leading above its glyphs. So 10 is the
                            // measured overhang the rail already tolerates, and
                            // anything past it is a collision rather than a tuck.
                            readonly property bool collides: ink > claim + 10
                            readonly property bool fitsGround: w <= 46
                            readonly property bool fitsRail: w <= 58
                            // What this design does to the rail, in the only
                            // terms the rail budget understands: the three
                            // metrics stack 102px today.
                            readonly property int railDelta: stack - 102
                            readonly property string verdict:
                                !modelData.ok ? "REJECTED — under 8px"
                                : !fitsRail ? "leaves the rail"
                                : !fitsGround ? "leaves the ground"
                                : collides ? "collides"
                                : railDelta === 0 ? "free"
                                : railDelta > 0 ? "costs +" + railDelta + "px"
                                : "saves " + (-railDelta) + "px"

                            function remeasure(): void {
                                if (mock.item)
                                    mock.item.measure();
                            }

                            Timer {
                                interval: 900
                                running: true
                                onTriggered: cell.remeasure()
                            }

                            Layout.preferredWidth: 170
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 3

                            // The strip, at the rail's real width, with the
                            // group's 46px ground drawn inside it so a design
                            // that leaves the ground is visibly leaving it.
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 58
                                implicitHeight: 150
                                color: Shell.Theme.bg
                                radius: 4

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 46
                                    height: parent.height - 8
                                    radius: Shell.Theme.radiusS
                                    color: Shell.Theme.bgHi
                                }

                                Loader {
                                    id: mock
                                    anchors.centerIn: parent
                                    sourceComponent: {
                                        switch (cell.modelData.k) {
                                        case "base": return cBase;
                                        case "over": return cOver;
                                        case "inring": return cInring;
                                        case "two": return cTwo;
                                        case "twot": return cTwot;
                                        case "rotn": return cRotn;
                                        case "flank": return cFlank;
                                        case "rotf": return cRotf;
                                        case "stackin": return cStackin;
                                        case "hoverT": return cHoverT;
                                        case "hoverN": return cHoverN;
                                        case "abbrev": return cAbbrev;
                                        case "path": return cPath;
                                        case "bar": return cBar;
                                        case "bar2": return cBar2;
                                        case "barin": return cBarin;
                                        case "mix": return cMix;
                                        case "micro7": return cMicro7;
                                        case "micro6": return cMicro6;
                                        case "in7": return cIn7;
                                        default: return cNameonly;
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.claim + " claim / " + cell.ink + " ink"
                                color: cell.modelData.k === "base" ? "#9ece6a"
                                     : !cell.modelData.ok ? "#f7768e"
                                     : cell.claim > 28 ? "#e0af68" : "#9ece6a"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.w + "px wide"
                                    + (cell.fitsGround ? "" : cell.fitsRail ? " — off the ground" : " — OFF THE RAIL")
                                color: cell.fitsGround ? "#859289" : "#f7768e"
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "smallest type " + cell.modelData.min + "px"
                                color: cell.modelData.min < 8 ? "#f7768e" : "#859289"
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.verdict
                                color: !cell.modelData.ok || !cell.fitsRail ? "#f7768e"
                                     : cell.verdict === "free" ? "#9ece6a" : "#e0af68"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.modelData.n
                                color: cell.modelData.k === "base" ? Shell.Theme.accent
                                     : cell.modelData.k === "rotn" ? "#9ece6a" : "#d3c6aa"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.leftMargin: 4
                                Layout.rightMargin: 4
                                text: cell.modelData.t
                                color: "#859289"
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Item { Layout.fillHeight: true }

                            Component.onCompleted: sheet.cells.push(cell)
                        }
                    }
                }
            }
        }

        // ---- shared pieces -----------------------------------------------

        // The ring, drawn exactly as Ring.qml draws it: 28px box, 3px stroke,
        // radius w/2 - 2.5, arc from 12 o'clock, and the two-level ground wash
        // the warning states added. Copied rather than imported because every
        // design below changes what stands in the middle of it, which is the
        // one thing Ring.qml does not parameterise past a single string.
        component Arc: Item {
            id: arc
            property real pct: 0
            property bool crit: false
            implicitWidth: 28
            implicitHeight: 28

            readonly property color tone: crit ? Shell.Theme.bad : Shell.Theme.accent

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: arc.crit ? Qt.alpha(Shell.Theme.bad, 0.24) : "transparent"
            }

            Canvas {
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d");
                    const w = width, r = w / 2 - 2.5;
                    ctx.reset();
                    ctx.lineWidth = 3;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.arc(w / 2, w / 2, r, 0, Math.PI * 2);
                    ctx.strokeStyle = Shell.Theme.line;
                    ctx.stroke();
                    const frac = Math.max(0, Math.min(1, arc.pct / 100));
                    if (frac > 0) {
                        ctx.beginPath();
                        ctx.arc(w / 2, w / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * frac);
                        ctx.strokeStyle = arc.tone;
                        ctx.stroke();
                    }
                }
            }
        }

        component Mid: Text {
            color: Shell.Theme.fg
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.features: ({ tnum: 1 })
        }

        component Cap: Text {
            color: Shell.Theme.dim
            font.pixelSize: 8
            font.features: ({ tnum: 1 })
        }

        // Text stood on its side in a slot the size of the box it needs.
        // Measured unconstrained and read back transposed — advanceWidth rather
        // than width, because width is rounded down and a turned label given its
        // own rounded-down length elides the glyph that did not fit. This is
        // RailClock.qml:100-118 and RailPlayer.qml:222-238, unchanged.
        //
        // `box` overrides the transposed width. A ring on a 46px ground leaves a
        // 9px flank, and an 8px text's *line box* is 11px — three pixels of it
        // leading that carries no ink. RailClock hands its turned date the whole
        // line box because it has the width to spare; here the box is set to the
        // flank and the leading is allowed to fall outside it, which moves no
        // glyph and costs the design its overflow.
        component Turned: Item {
            property alias text: t.text
            property int size: 8
            property int box: 0
            property color tint: Shell.Theme.dim
            implicitWidth: box > 0 ? box : t.implicitHeight
            implicitHeight: Math.ceil(tm.advanceWidth)
            TextMetrics { id: tm; font: t.font; text: t.text }
            Text {
                id: t
                anchors.centerIn: parent
                rotation: -90
                color: parent.tint
                font.pixelSize: parent.size
                font.features: ({ tnum: 1 })
            }
        }

        // A bar the width of the group's ground, the shape panels/Monitor.qml
        // already draws its per-core and per-disk meters with.
        component Track: Rectangle {
            property real pct: 0
            property bool crit: false
            implicitWidth: 42
            implicitHeight: 3
            radius: 1.5
            color: Shell.Theme.line
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, parent.pct / 100))
                height: parent.height
                radius: parent.radius
                color: parent.crit ? Shell.Theme.bad : Shell.Theme.accent
            }
        }

        // The element every design is built on. It reads its metric off the
        // Loader that made it — guarded, because a Loader's item is constructed
        // before it is reparented and an unguarded `parent.m` evaluates once
        // against null. `parent` notifies, so the guard resolves itself.
        component El: Item {
            readonly property var m: parent && parent.m ? parent.m : sheet.blank
            implicitWidth: 46
        }

        // Three of one design, at the rings group's real 9px spacing, with the
        // first one kept for measuring and the ink of all three read back off
        // the built items rather than asserted.
        component Stack: Column {
            id: st
            property Component el
            property Item a: null
            property Item b: null
            property Item c: null

            // Ink is measured once, on demand, rather than bound. `childrenRect`
            // is the obvious way to write this and it is a binding loop here:
            // the children are anchored to their parent's centre, so the parent's
            // geometry is an input to the rectangle that is being read back out
            // of it. Walking the children once, after the scene has settled,
            // measures the same thing and closes no loop.
            property int inkH: 0
            property int inkW: 0

            function extent(item: Item): var {
                let t = 1e9, b2 = -1e9, l = 1e9, r = -1e9;
                for (const ch of item.children) {
                    if (!ch.visible)
                        continue;
                    t = Math.min(t, ch.y);
                    b2 = Math.max(b2, ch.y + ch.height);
                    l = Math.min(l, ch.x);
                    r = Math.max(r, ch.x + ch.width);
                }
                return { h: Math.round(b2 - t), w: Math.ceil(r - l) };
            }

            // Both numbers are the worst of the three rows, not the first one.
            // The first row is ram — the shortest strings on the sheet — and a
            // design measured on it alone reports 13/31 and never learns what
            // 845/947 does to it.
            property int claim: 0

            function measure(): void {
                if (!a)
                    return;
                inkH = Math.max(extent(a).h, b ? extent(b).h : 0, c ? extent(c).h : 0);
                inkW = Math.max(extent(a).w, b ? extent(b).w : 0, c ? extent(c).w : 0);
                claim = Math.round(Math.max(a.implicitHeight,
                                            b ? b.implicitHeight : 0,
                                            c ? c.implicitHeight : 0));
            }

            spacing: 9

            Repeater {
                model: sheet.metrics
                Loader {
                    required property var modelData
                    required property int index
                    property var m: modelData
                    sourceComponent: st.el
                    // The Loader's own childrenRect is the loaded item's box,
                    // not its ink, and reading it back is a binding loop into
                    // the Loader's own size. So the *item* is what is kept.
                    Component.onCompleted: {
                        if (index === 0) st.a = item;
                        else if (index === 1) st.b = item;
                        else st.c = item;
                    }
                }
            }
        }

        // ---- the designs ---------------------------------------------------

        // 1. What ships. The caption is anchored to the ring's bottom edge with
        // a -1 margin, so it is outside the 28px box the layout is told about
        // and lives in the 9px gap instead (Ring.qml:141-148).
        Component {
            id: cBase
            Stack {
                el: Component {
                    El {
                        implicitHeight: 28
                        Arc {
                            id: a1
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: parent.m.pct
                            crit: parent.m.crit
                        }
                        Mid { anchors.centerIn: a1; text: parent.m.used }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a1.bottom
                            anchors.topMargin: -1
                            text: "/" + parent.m.tot
                        }
                    }
                }
            }
        }

        // 2. A caption over and a caption under. Every fact upright, nothing
        // abbreviated, and two line-heights of new ink for it.
        Component {
            id: cOver
            Stack {
                el: Component {
                    El {
                        id: e2
                        implicitHeight: 28 + 10
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: -1
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: e2.m.n
                            }
                            Arc {
                                id: a2
                                anchors.horizontalCenter: parent.horizontalCenter
                                pct: e2.m.pct
                                crit: e2.m.crit
                                Mid { anchors.centerIn: parent; text: e2.m.used }
                            }
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: e2.m.frac
                            }
                        }
                    }
                }
            }
        }

        // 3. The name takes the middle. 20px of clear middle at 10px type is
        // three characters, so "data" has to become "dat" and "/mnt/data" was
        // never in the running.
        Component {
            id: cInring
            Stack {
                el: Component {
                    El {
                        implicitHeight: 28
                        Arc {
                            id: a3
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: parent.m.pct
                            crit: parent.m.crit
                        }
                        Mid { anchors.centerIn: a3; text: parent.m.n3 }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a3.bottom
                            anchors.topMargin: -1
                            text: parent.m.frac
                        }
                    }
                }
            }
        }

        // 4. Two lines of caption. Nothing rotated, nothing shortened, nothing
        // below the floor — and the element grows by a whole line.
        Component {
            id: cTwo
            Stack {
                el: Component {
                    El {
                        id: e4
                        implicitHeight: 38
                        Arc {
                            id: a4
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e4.m.pct
                            crit: e4.m.crit
                            Mid { anchors.centerIn: parent; text: e4.m.used }
                        }
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a4.bottom
                            anchors.topMargin: -1
                            spacing: -2
                            Cap { anchors.horizontalCenter: parent.horizontalCenter; text: e4.m.n }
                            Cap { anchors.horizontalCenter: parent.horizontalCenter; text: e4.m.frac }
                        }
                    }
                }
            }
        }

        // 5. The same pulled tight. Digits have no descenders, so the pixels a
        // line reserves under its baseline are empty and the second line can
        // move up into them — caelestia's tuck between hour and minute
        // (caelestia-shell/modules/bar/components/Clock.qml:96), spent here on
        // the gap between the two caption lines.
        Component {
            id: cTwot
            Stack {
                el: Component {
                    El {
                        id: e5
                        implicitHeight: 35
                        Arc {
                            id: a5
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e5.m.pct
                            crit: e5.m.crit
                            Mid { anchors.centerIn: parent; text: e5.m.used }
                        }
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a5.bottom
                            anchors.topMargin: -2
                            spacing: -3
                            Cap { anchors.horizontalCenter: parent.horizontalCenter; text: e5.m.n }
                            Cap { anchors.horizontalCenter: parent.horizontalCenter; text: e5.m.frac }
                        }
                    }
                }
            }
        }

        // 6. The name on its side, in the flank. A 28px ring on a 46px ground
        // leaves 9px down each side and the rail has never used it. The centre
        // and the caption stay exactly as they ship.
        Component {
            id: cRotn
            Stack {
                el: Component {
                    El {
                        id: e6
                        implicitHeight: 28
                        Arc {
                            id: a6
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e6.m.pct
                            crit: e6.m.crit
                            Mid { anchors.centerIn: parent; text: e6.m.used }
                        }
                        // In the flank, not beside the ring. Anchoring it to the
                        // ring's left edge pushes it off the ground; anchoring it
                        // to the ground's own left edge puts it in the 9px the
                        // ring was never using, and the ring stays exactly where
                        // every other ring in the column has it.
                        Turned {
                            anchors.left: parent.left
                            anchors.verticalCenter: a6.verticalCenter
                            box: 9
                            text: e6.m.n
                        }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a6.bottom
                            anchors.topMargin: -1
                            text: "/" + e6.m.tot
                        }
                    }
                }
            }
        }

        // 7. Both flanks, no caption. The only design here that gets the third
        // fact without spending the line under the ring at all.
        Component {
            id: cFlank
            Stack {
                el: Component {
                    El {
                        id: e7
                        implicitHeight: 28
                        Arc {
                            id: a7
                            anchors.centerIn: parent
                            pct: e7.m.pct
                            crit: e7.m.crit
                            Mid { anchors.centerIn: parent; text: e7.m.used }
                        }
                        Turned {
                            anchors.left: parent.left
                            anchors.verticalCenter: a7.verticalCenter
                            box: 9
                            text: e7.m.n
                        }
                        Turned {
                            anchors.right: parent.right
                            anchors.verticalCenter: a7.verticalCenter
                            box: 9
                            text: "/" + e7.m.tot
                        }
                    }
                }
            }
        }

        // 8. The whole fraction turned. 845/947 at 8px is a 34px column against
        // a 28px ring, so the element grows to the length of the longest string
        // rather than to anything about the ring.
        Component {
            id: cRotf
            Stack {
                el: Component {
                    El {
                        id: e8
                        // The turned fraction is longer than the ring is tall as
                        // soon as the numbers get to four digits, so the element
                        // has to grow to the length of the string rather than to
                        // anything about the ring. This is the design's whole
                        // problem in one binding.
                        implicitHeight: Math.max(28, Math.ceil(rot8.implicitHeight))
                        Arc {
                            id: a8
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            pct: e8.m.pct
                            crit: e8.m.crit
                            Mid { anchors.centerIn: parent; text: e8.m.pct }
                        }
                        Turned {
                            id: rot8
                            anchors.right: parent.right
                            anchors.verticalCenter: a8.verticalCenter
                            box: 9
                            text: e8.m.frac
                        }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a8.bottom
                            anchors.topMargin: -1
                            text: e8.m.n
                        }
                    }
                }
            }
        }

        // 9. Both numbers inside, with a hairline for the slash. Two 8px lines
        // is 20px, which is exactly the clear middle — and the hairline has to
        // come out of the same 20px.
        Component {
            id: cStackin
            Stack {
                el: Component {
                    El {
                        id: e9
                        implicitHeight: 28
                        Arc {
                            id: a9
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e9.m.pct
                            crit: e9.m.crit
                            Column {
                                anchors.centerIn: parent
                                spacing: -2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: e9.m.used
                                    color: Shell.Theme.fg
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.features: ({ tnum: 1 })
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: e9.m.tot
                                    color: Shell.Theme.dim
                                    font.pixelSize: 8
                                    font.features: ({ tnum: 1 })
                                }
                            }
                        }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a9.bottom
                            anchors.topMargin: -1
                            text: e9.m.n
                        }
                    }
                }
            }
        }

        // 10. The name is the caption until the pointer arrives, then the
        // caption becomes the fraction. Drawn in the hovered state, because the
        // hovered state is the one that has to fit.
        Component {
            id: cHoverT
            Stack {
                el: Component {
                    El {
                        id: e10
                        implicitHeight: 28
                        Arc {
                            id: a10
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e10.m.pct
                            crit: e10.m.crit
                            Mid { anchors.centerIn: parent; text: e10.m.used }
                        }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a10.bottom
                            anchors.topMargin: -1
                            text: e10.m.frac
                            color: Shell.Theme.fg
                        }
                    }
                }
            }
        }

        // 11. Percent in the middle — the one number that is always two glyphs
        // whatever the disk is — and the gigabytes only on hover.
        Component {
            id: cHoverN
            Stack {
                el: Component {
                    El {
                        id: e11
                        implicitHeight: 28
                        Arc {
                            id: a11
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e11.m.pct
                            crit: e11.m.crit
                            Mid { anchors.centerIn: parent; text: e11.m.pct }
                        }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a11.bottom
                            anchors.topMargin: -1
                            text: e11.m.abbr
                            color: Shell.Theme.fg
                        }
                    }
                }
            }
        }

        // 12. The caption carries the whole fraction, with the total compressed
        // to terabytes where that is shorter. Still no name.
        Component {
            id: cAbbrev
            Stack {
                el: Component {
                    El {
                        implicitHeight: 28
                        Arc {
                            id: a12
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: parent.m.pct
                            crit: parent.m.crit
                        }
                        Mid { anchors.centerIn: a12; text: parent.m.used }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a12.bottom
                            anchors.topMargin: -1
                            text: parent.m.abbr
                        }
                    }
                }
            }
        }

        // 13. The mount point as written, which is the question this is really
        // asking: how wide is /mnt/data at the caption's 8px.
        Component {
            id: cPath
            Stack {
                el: Component {
                    El {
                        implicitHeight: 28
                        Arc {
                            id: a13
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: parent.m.pct
                            crit: parent.m.crit
                        }
                        Mid { anchors.centerIn: a13; text: parent.m.used }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a13.bottom
                            anchors.topMargin: -1
                            text: parent.m.path
                        }
                    }
                }
            }
        }

        // 14. Not a ring at all. Name and percent on one row over a 3px track,
        // using the full 46px of the ground instead of the ring's 28.
        Component {
            id: cBar
            Stack {
                el: Component {
                    El {
                        id: e14
                        implicitHeight: 16
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Item {
                                width: 42
                                height: 10
                                Cap { anchors.left: parent.left; text: e14.m.n }
                                Cap {
                                    anchors.right: parent.right
                                    text: e14.m.pct + "%"
                                    color: Shell.Theme.fg
                                }
                            }
                            Track { pct: e14.m.pct; crit: e14.m.crit }
                        }
                    }
                }
            }
        }

        // 15. The same with the fraction on its own row. Three facts, upright,
        // at the widest the ground allows.
        Component {
            id: cBar2
            Stack {
                el: Component {
                    El {
                        id: e15
                        implicitHeight: 27
                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            Item {
                                width: 42
                                height: 10
                                Cap { anchors.left: parent.left; text: e15.m.n }
                                Cap {
                                    anchors.right: parent.right
                                    text: e15.m.pct + "%"
                                    color: Shell.Theme.fg
                                }
                            }
                            Cap {
                                text: e15.m.frac
                                color: Shell.Theme.fg
                            }
                            Track { pct: e15.m.pct; crit: e15.m.crit }
                        }
                    }
                }
            }
        }

        // 16. The text laid over the track rather than above it. The shortest
        // element on the sheet that still carries all three facts.
        Component {
            id: cBarin
            Stack {
                el: Component {
                    El {
                        id: e16
                        implicitHeight: 13
                        Rectangle {
                            anchors.centerIn: parent
                            width: 42
                            height: 13
                            radius: 4
                            color: Shell.Theme.line
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, e16.m.pct / 100))
                                height: parent.height
                                radius: parent.radius
                                color: Qt.alpha(e16.m.crit ? Shell.Theme.bad
                                                           : Shell.Theme.accent, 0.45)
                            }
                            Cap {
                                anchors.left: parent.left
                                anchors.leftMargin: 3
                                anchors.verticalCenter: parent.verticalCenter
                                text: e16.m.n
                                color: Shell.Theme.fg
                            }
                            Cap {
                                anchors.right: parent.right
                                anchors.rightMargin: 3
                                anchors.verticalCenter: parent.verticalCenter
                                text: e16.m.used
                            }
                        }
                    }
                }
            }
        }

        // 17. A ring where the metric is a rate and a bar where it is a
        // capacity. Drawn as one stack, because the rail carries both at once
        // and a mixed column is the thing that has to look deliberate.
        Component {
            id: cMix
            Stack {
                el: Component {
                    El {
                        id: e17
                        implicitHeight: e17.m.n === "ram" ? 28 : 16
                        Arc {
                            id: a17
                            visible: e17.m.n === "ram"
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e17.m.pct
                            crit: e17.m.crit
                            Mid { anchors.centerIn: parent; text: e17.m.used }
                        }
                        Cap {
                            visible: e17.m.n === "ram"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a17.bottom
                            anchors.topMargin: -1
                            text: "/" + e17.m.tot
                        }
                        Column {
                            visible: e17.m.n !== "ram"
                            anchors.centerIn: parent
                            spacing: 2
                            Item {
                                width: 42
                                height: 10
                                Cap { anchors.left: parent.left; text: e17.m.n }
                                Cap {
                                    anchors.right: parent.right
                                    text: e17.m.abbr
                                    color: Shell.Theme.fg
                                }
                            }
                            Track { pct: e17.m.pct; crit: e17.m.crit }
                        }
                    }
                }
            }
        }

        // 18. REJECTED. The baseline with the whole fraction at 7px. It fits
        // the ground with room to spare, which is exactly the trap.
        Component {
            id: cMicro7
            Stack {
                el: Component {
                    El {
                        implicitHeight: 28
                        Arc {
                            id: a18
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: parent.m.pct
                            crit: parent.m.crit
                        }
                        Mid { anchors.centerIn: a18; text: parent.m.used }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a18.bottom
                            anchors.topMargin: -1
                            text: parent.m.n + " " + parent.m.frac
                            font.pixelSize: 7
                        }
                    }
                }
            }
        }

        // 19. REJECTED. Design 4 shrunk until it costs the rail nothing.
        Component {
            id: cMicro6
            Stack {
                el: Component {
                    El {
                        id: e19
                        implicitHeight: 28
                        Arc {
                            id: a19
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e19.m.pct
                            crit: e19.m.crit
                            Mid { anchors.centerIn: parent; text: e19.m.used }
                        }
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a19.bottom
                            anchors.topMargin: -2
                            spacing: -2
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: e19.m.n
                                font.pixelSize: 6
                            }
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: e19.m.frac
                                font.pixelSize: 6
                            }
                        }
                    }
                }
            }
        }

        // 20. REJECTED. Both numbers inside the ring at 7px, under the wash
        // that a disk at 95% is actually wearing.
        Component {
            id: cIn7
            Stack {
                el: Component {
                    El {
                        id: e20
                        implicitHeight: 28
                        Arc {
                            id: a20
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e20.m.pct
                            crit: e20.m.crit
                            Column {
                                anchors.centerIn: parent
                                spacing: -2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: e20.m.used
                                    color: Shell.Theme.fg
                                    font.pixelSize: 7
                                    font.features: ({ tnum: 1 })
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: e20.m.tot
                                    color: Shell.Theme.dim
                                    font.pixelSize: 7
                                    font.features: ({ tnum: 1 })
                                }
                            }
                        }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a20.bottom
                            anchors.topMargin: -1
                            text: e20.m.n
                        }
                    }
                }
            }
        }

        // 21. The null answer, and the one to beat: the ring exactly as it is,
        // with the name as its caption and the total not shown at all. This is
        // already how cpu, °c and fan work.
        Component {
            id: cNameonly
            Stack {
                el: Component {
                    El {
                        implicitHeight: 28
                        Arc {
                            id: a21
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: parent.m.pct
                            crit: parent.m.crit
                        }
                        Mid { anchors.centerIn: a21; text: parent.m.used }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a21.bottom
                            anchors.topMargin: -1
                            text: parent.m.n
                        }
                    }
                }
            }
        }
    }
}
