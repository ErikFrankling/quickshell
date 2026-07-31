//@ pragma ShellId metriccentred

// Contact sheet, round two. `metric-fraction.qml` asked where a third fact
// goes on a ring that has room for two, and the answer it recommended — the
// name stood on its side in the 9px flank a 28px ring leaves inside a 46px
// ground — shipped in a01a930 and was rejected on looks. Nothing about the
// measurement was wrong. It was the wrong thing to measure alone.
//
// So this sheet has one rule the last one did not:
//
//     NOTHING IS ROTATED AND NOTHING SITS IN THE FLANK.
//
// Every element on it is vertically stacked and horizontally centred on the
// ring. Twenty-three of them, drawn at the rail's true 58px with the real ring
// at real size, rendering this host's actual worst case:
//
//     ram    13 /   31 GB   (42%, no wash)
//     root  845 /  947 GB   (95%, critical wash + blink)
//     data  480 / 1968 GB   (26%, no wash)
//
// Seven are carried over from the last sheet unchanged, because they were
// already centred and their numbers should not be re-derived: designs 2, 3, 4,
// 5, 9, 12 and 21 there are 2, 3, 4, 5, 6, 7 and 8 here. The rest are new.
//
// FIVE NUMBERS PER DESIGN, all measured off the built items, none asserted:
//
//   claim  what one element hands the ColumnLayout, and therefore what it
//          costs the rail. Today's ring claims 28: its caption is anchored to
//          the ring's *bottom edge* and hangs outside the box entirely.
//   ink    the actual extent of what is drawn. Today that is 38, and the 10px
//          of overhang is paid out of the 9px gap between rings — which is why
//          the rings group's spacing is 9 and every other rail group's is 5.
//   width  the widest row's ink. > 46 leaves the group's ground, > 58 leaves
//          the rail.
//   min    the smallest pixelSize any Text in the design actually renders at,
//          read off the item rather than off the model.
//   rail   stack3 - 102, where stack3 is three of these elements at the group's
//          real 9px spacing and 102 is what the three metrics stack today.
//
// A design collides when ink > claim + 10, because 10 is the overhang the
// shipped ring already has and reads fine at.
//
// TWO HARD CONSTRAINTS, both learned the expensive way.
//
// 1. NOTHING BELOW 8px. That is the floor the ring captions already use.
//    Designs 21, 22 and 23 are under it. They are drawn in red, with their
//    measurements, rather than deleted — the last sheet caught the trap and it
//    is worth catching again: a 7px caption *fits* the 58px rail and costs the
//    rail nothing, and fitting is not the test.
//
// 2. IT HAS TO SURVIVE THE WASH. A ring tints its own ground 18% of Theme.warn
//    at the warning threshold and 24% of Theme.bad at the critical one, and the
//    disks blink, so that wash breathes down to 0.15 of itself and back
//    (Ring.qml:76-92, 109-114). `root` is at 95% on this host right now, so it
//    is drawn in that state, and every Text on the sheet is measured for WCAG
//    contrast against the ground it is *actually* standing on — the composited
//    wash if its centre falls inside the washed circle, the plain group ground
//    if it does not. That distinction is most of the difference between these
//    designs: a caption under the ring is never washed, a number inside it
//    always is.
//
// The contrast is computed twice: once on the palette this harness draws in
// (its own ShellId, so its own empty theme.json, so Theme.qml's fallback), and
// once across all nine of Themes.qml's curated palettes, which is where the
// floor actually lives. warning-states.md put that floor at 3.3:1 for a 10px
// DemiBold number under the critical wash; anything on this sheet that goes
// below it is spending contrast the shell has already decided it cannot spare.
//
// Everything prints to stdout as a TSV as well as being drawn, because a number
// that can only be read off a screenshot cannot be checked.
//
// Harness only. Nothing here ships.
//
//   quickshell -p docs/surveys/metric-centred.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "file:///home/erikf/projects/personal/quickshell" as Shell

ShellRoot {
    id: root

    // ---- colour maths, on the live palette ------------------------------
    //
    // The same three functions pill-bounds.qml uses, for the same reason: a
    // mark drawn at an alpha has to be composited over what is behind it before
    // it is compared to anything, because the composite is the colour the eye
    // is given.

    function lin(v) { return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
    function lum(c) {
        return 0.2126 * root.lin(c.r) + 0.7152 * root.lin(c.g) + 0.0722 * root.lin(c.b);
    }
    function over(fg, a, bg) {
        return Qt.rgba(fg.r * a + bg.r * (1 - a),
                       fg.g * a + bg.g * (1 - a),
                       fg.b * a + bg.b * (1 - a), 1);
    }
    function wcag(a, b) {
        const x = root.lum(a), y = root.lum(b);
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
    }

    // Theme.qml's slot names over a raw base16 palette, so the sweep below can
    // be run against a scheme without loading it. Kept in step with
    // Theme.qml:26-49 by hand, the way pill-bounds.qml does.
    function pal(p) {
        const q = c => Qt.color(c);
        return {
            bg: q(p.base00), bgAlt: q(p.base01), bgHi: q(p.base02), dim: q(p.base04),
            fg: q(p.base05), line: q(p.line ?? p.base03), bad: q(p.base08),
            warn: q(p.base0A), accent: q(p.accent ?? p.base0D)
        };
    }

    // Every distinct (ink, ground) pair any design on this sheet puts type on.
    // There are only nine of them, and which ones a design uses is the whole
    // of what the wash does to it.
    readonly property var pairs: [
        { n: "fg 10px  on critical wash", ink: "fg",  tone: "bad",  a: 0.24 },
        { n: "fg 10px  on warning wash",  ink: "fg",  tone: "warn", a: 0.18 },
        { n: "dim 8px  on critical wash", ink: "dim", tone: "bad",  a: 0.24 },
        { n: "fg 8px   on critical wash", ink: "fg",  tone: "bad",  a: 0.24 },
        { n: "fg 10px  on blink floor",   ink: "fg",  tone: "bad",  a: 0.036 },
        { n: "fg 10px  on plain ground",  ink: "fg",  tone: "bad",  a: 0 },
        { n: "dim 8px  on plain ground",  ink: "dim", tone: "bad",  a: 0 },
        { n: "fg 8px   on a full bar",    ink: "fg",  tone: "barfill", a: 1 },
        { n: "dim 8px  on a full bar",    ink: "dim", tone: "barfill", a: 1 }
    ]

    function groundOf(p, spec) {
        if (spec.tone === "barfill")
            return root.over(p.bad, 0.45, root.over(p.line, 1, p.bgHi));
        return root.over(p[spec.tone], spec.a, p.bgHi);
    }

    // The cross-scheme sweep. The drawn sheet can only ever be in one palette,
    // and the number that decides a design is the worst palette's, not this
    // one's — so the nine curated schemes are read out of Themes.qml itself
    // rather than out of a second copy that can drift.
    function sweep(rows) {
        let head = "CONTRAST-SWEEP\tpair";
        for (const r of rows) head += "\t" + r.name;
        console.log(head + "\tmin");
        for (const spec of root.pairs) {
            let line = "CONTRAST-SWEEP\t" + spec.n, lo = 999;
            for (const r of rows) {
                const p = root.pal(r.p);
                const v = root.wcag(p[spec.ink], root.groundOf(p, spec));
                lo = Math.min(lo, v);
                line += "\t" + v.toFixed(2);
            }
            console.log(line + "\t" + lo.toFixed(2));
        }
    }

    PanelWindow {
        id: sheet
        anchors { top: true; left: true }
        margins { left: 8; top: 8 }
        implicitWidth: 1900
        implicitHeight: 800
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "metric-centred"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        // Themes.qml's curated list, instantiated unseen. pill-bounds.qml's
        // move: the palettes live in one place and the sweep reads that place.
        Shell.Themes {
            id: schemes
            visible: false
        }

        // The three metrics, in one place, so no design wins by quietly showing
        // less than the others. Real numbers off this host: df -B1 on / and
        // /mnt/data, and /proc/meminfo for the memory.
        //
        // `root` rather than `/` because that is what ships and what he reads;
        // note that with nothing rotated a bare "/" would now be legal again
        // (it was spelled out because a lone slash turned -90 is a backslash)
        // and would save 4px of caption. Every width here is the safe one.
        readonly property var metrics: [
            { n: "ram",  n3: "ram", used: "13",  tot: "31",   pct: 42,
              frac: "13/31",    abbr: "13/31",   aTot: "31",   crit: false, warn: false },
            { n: "root", n3: "rot", used: "845", tot: "947",  pct: 95,
              frac: "845/947",  abbr: "845/947", aTot: "947",  crit: true,  warn: false },
            { n: "data", n3: "dat", used: "480", tot: "1968", pct: 26,
              frac: "480/1968", abbr: "480/2.0T", aTot: "2.0T", crit: false, warn: false }
        ]
        readonly property var blank: ({ n: "", n3: "", used: "", tot: "", pct: 0,
            frac: "", abbr: "", aTot: "", crit: false, warn: false })

        // Every cell registers itself here so the measuring pass can walk them
        // without reaching into the Repeater.
        property var cells: []

        Timer {
            interval: 1500
            running: true
            onTriggered: {
                for (const c of sheet.cells)
                    c.remeasure();

                console.log("\nCENTRED\tdesign\tclaim\tink\twidth\tsmallest\tcollides"
                    + "\trail\tstack3\tminContrast\tverdict");
                for (const c of sheet.cells)
                    console.log("CENTRED\t" + c.modelData.n + "\t" + c.claim + "\t"
                        + c.ink + "\t" + c.w + "\t" + c.smallest
                        + "\t" + (c.collides ? "YES" : "no")
                        + "\t" + (c.railDelta > 0 ? "+" : "") + c.railDelta
                        + "\t" + c.stack + "\t" + c.minContrast.toFixed(2)
                        + "\t" + c.verdict);

                // Every Text on the sheet, with the ground it actually stands
                // on. This is the table the wash question is answered from:
                // "845" is inside the washed circle and "root" under it is not,
                // and no summary number can tell you which.
                console.log("\nCENTRED-INK\tdesign\tmetric\ttext\tsize\tink\tground\tcontrast");
                for (const c of sheet.cells)
                    for (const r of c.rows)
                        console.log("CENTRED-INK\t" + c.modelData.n + "\t" + r.metric
                            + "\t" + r.text + "\t" + r.size + "\t" + r.ink
                            + "\t" + r.ground + "\t" + r.contrast.toFixed(2));

                console.log("");
                root.sweep(schemes.curated);
                console.log("\nCENTRED\tdrawn in " + Shell.Theme.name
                    + "; the sweep above is the number that decides.\n");
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
                    text: "Centred only — twenty-three ways to put a name, a used value and a total on a 28px ring in a 58px rail with nothing rotated and nothing in the flank"
                    color: "#d3c6aa"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "measured, not claimed. CLAIM is what the element hands the layout (28 today, and what the rail pays); INK is what is drawn (38 today — the caption hangs into the 9px gap). "
                        + "ink > claim+10 collides with the next ring. width > 46 leaves the group's ground, width > 58 leaves the rail. "
                        + "the root ring carries its real 95% critical wash, so nothing here is measured on a clean background, and every Text is scored for WCAG contrast against the ground it actually stands on — washed inside the ring, plain outside it. "
                        + "legibility floor is what ships: 8px caption, 10px centre, 3.3:1 under the wash. below 8px is rejected and kept in red."
                    color: "#859289"
                    font.pixelSize: 9
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                GridLayout {
                    columns: 12
                    columnSpacing: 0
                    rowSpacing: 4
                    Layout.fillHeight: true

                    Repeater {
                        model: [
                            { n: "1. Baseline — today, unturned", k: "base", ok: 1,
                              t: "the shipped ring with the flank label taken off: used value in the centre at 10px, /total as the caption at 8px. two facts. this is the zero every rail delta below is against." },
                            { n: "2. Name over, fraction under", k: "over", ok: 1,
                              t: "a caption above the ring and a caption below it. all three facts, upright, centred, nothing abbreviated — and two full line-heights of new ink. Brainitech's Speedometer." },
                            { n: "3. Name inside the ring", k: "inring", ok: 1,
                              t: "the name takes the centre and the fraction becomes the caption. free, but the middle is 20px: three characters at 10px, so root becomes rot and the number is demoted." },
                            { n: "4. Two-line caption: name, fraction", k: "two", ok: 1,
                              t: "used in the centre, name and fraction stacked under it. nothing rotated, nothing abbreviated, nothing under 8px. Ricelin's stack, and the last sheet's runner-up." },
                            { n: "5. Two-line caption, tucked -3", k: "twot", ok: 1,
                              t: "the same with the lines pulled together, spending the slack digits leave under their baseline the way caelestia's clock does." },
                            { n: "6. Used over total inside the ring", k: "stackin", ok: 1,
                              t: "both numbers in the middle with a hairline between them, name as the caption. two 8px lines is exactly the 20px the middle has — and both of them are in the wash." },
                            { n: "7. Abbreviated fraction caption", k: "abbrev", ok: 1,
                              t: "the caption carries the whole fraction with the total compressed to terabytes: 480/2.0T. no name, so the two disks still read alike." },
                            { n: "8. Name only — the null answer", k: "nameonly", ok: 1,
                              t: "the ring exactly as it is with the name as its caption and the total simply not shown, the way cpu, °c and fan already work. the design to beat." },
                            { n: "9. One caption line: name total", k: "nametot", ok: 1,
                              t: "the used value in the ring and 'ram 31' as a single caption line — the name and the total sharing the one row the ring already pays for. no slash, no second line." },
                            { n: "10. Two-line caption: name, total", k: "twotot", ok: 1,
                              t: "design 4 with the used value dropped out of the caption, since it is already in the ring. same two lines, half the width — 'root' over '947'." },
                            { n: "11. Name, total, tucked -3", k: "twotott", ok: 1,
                              t: "design 10 pulled together the same way design 5 pulls design 4. the narrowest two-line caption on the sheet." },
                            { n: "12. Total inside, under the used value", k: "totin", ok: 1,
                              t: "the used value keeps its 10px in the middle and the total goes under it at 8px, no rule between them; the name becomes the caption. two type sizes in a 20px hole." },
                            { n: "13. Percent only, name as caption", k: "pctonly", ok: 1,
                              t: "the total is not shown and neither are the gigabytes: the arc's own number in the middle, the name underneath. the null answer for a disk." },
                            { n: "14. Name above, /total below", k: "above", ok: 1,
                              t: "today's ring with the name added as a second caption above it. the smallest possible stacked answer that still says all three things." },
                            { n: "15. Name above, nothing below", k: "abovebare", ok: 1,
                              t: "the name above the ring and the caption line given up entirely. three facts become two, and the ink stops at the claim for once." },
                            { n: "16. Both captions hung outside", k: "hung", ok: 1,
                              t: "design 14 with the name anchored to the ring's top edge the way the caption is anchored to its bottom, so the layout is told 28. free on paper. measure the ink." },
                            { n: "17. Labelled bar", k: "bar", ok: 1,
                              t: "not a ring. name left, percent right, a 3px track under them, the full 46px of the ground — the shape panels/Monitor.qml already uses for exactly this." },
                            { n: "18. Labelled bar, two rows", k: "bar2", ok: 1,
                              t: "the same with the fraction on its own row under the name. all three facts, upright, at full width, and still cheaper than a ring." },
                            { n: "19. Bar with text inside", k: "barin", ok: 1,
                              t: "name and used value laid over a 13px track rather than above it. the shortest element on the sheet that says all three things — and text on the fill." },
                            { n: "20. Rings for ram, bars for disks", k: "mix", ok: 1,
                              t: "a ring where the metric is a rate and a bar where it is a capacity. drawn as one stack, because the rail has to hold both at once." },
                            { n: "21. Name, total at 7px", k: "micro7", ok: 0,
                              t: "design 10 shrunk until it stops costing the rail anything. it fits the ground with room to spare, which is exactly the trap." },
                            { n: "22. Two-line caption at 6px", k: "micro6", ok: 0,
                              t: "design 4 shrunk the same way. 6px is not small type, it is texture — and it collides as well." },
                            { n: "23. Fraction inside at 7px", k: "in7", ok: 0,
                              t: "used over total inside the ring at 7px, under the wash a disk at 95% is actually wearing. spends contrast and glyph size in the same place." }
                        ]

                        ColumnLayout {
                            id: cell
                            required property var modelData

                            readonly property int claim: mock.item ? mock.item.claim : 0
                            readonly property int ink: mock.item ? mock.item.inkH : 0
                            readonly property int w: mock.item ? mock.item.inkW : 0
                            readonly property int smallest: mock.item ? mock.item.smallest : 0
                            readonly property real minContrast: mock.item ? mock.item.minContrast : 0
                            readonly property var rows: mock.item ? mock.item.rows : []
                            readonly property int stack: mock.item ? Math.round(mock.item.height) : 0
                            // Today's ring hangs 10px of caption into a 9px gap
                            // and reads fine, because a text box carries a pixel
                            // or two of leading above its glyphs. So 10 is the
                            // measured overhang the rail already tolerates, and
                            // anything past it is a collision rather than a tuck.
                            readonly property bool collides: ink > claim + 10
                            readonly property bool fitsGround: w <= 46
                            readonly property bool fitsRail: w <= 58
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

                            Layout.preferredWidth: 155
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
                                        case "stackin": return cStackin;
                                        case "abbrev": return cAbbrev;
                                        case "nametot": return cNametot;
                                        case "twotot": return cTwotot;
                                        case "twotott": return cTwotott;
                                        case "totin": return cTotin;
                                        case "pctonly": return cPctonly;
                                        case "above": return cAbove;
                                        case "abovebare": return cAboveBare;
                                        case "hung": return cHung;
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
                                text: "smallest type " + cell.smallest + "px"
                                color: cell.smallest < 8 ? "#f7768e" : "#859289"
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "worst contrast " + cell.minContrast.toFixed(2) + ":1"
                                color: cell.minContrast < 3.3 ? "#f7768e" : "#859289"
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.verdict
                                color: !cell.modelData.ok || !cell.fitsRail || cell.collides ? "#f7768e"
                                     : cell.verdict === "free" ? "#9ece6a" : "#e0af68"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.modelData.n
                                color: cell.modelData.k === "base" ? Shell.Theme.accent : "#d3c6aa"
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

        // Any tinted ground a Text can end up standing on, marked so the
        // measuring pass can find it by geometry rather than by being told.
        // `under` is what the tint is composited over — bgHi for a ring's wash,
        // the track's own colour for the fill inside a bar.
        component Wash: Rectangle {
            property color tone: Shell.Theme.bad
            property real amount: 0
            property color under: Shell.Theme.bgHi
            objectName: "wash"
            color: Qt.alpha(tone, amount)
        }

        // The ring, drawn exactly as Ring.qml draws it: 28px box, 3px stroke,
        // radius w/2 - 2.5, arc from 12 o'clock, and the two-level ground wash
        // the warning states added. Copied rather than imported because every
        // design below changes what stands in the middle of it, which is the
        // one thing Ring.qml does not parameterise past a single string.
        component Arc: Item {
            id: arc
            property real pct: 0
            property bool crit: false
            property bool warn: false
            implicitWidth: 28
            implicitHeight: 28

            readonly property color tone: crit ? Shell.Theme.bad
                                        : warn ? Shell.Theme.warn : Shell.Theme.accent

            Wash {
                anchors.fill: parent
                radius: width / 2
                tone: arc.crit ? Shell.Theme.bad : Shell.Theme.warn
                // Ring.qml:109-114 exactly. The blink drops this to 0.15 of
                // itself and back; full wash is the worse end for contrast in
                // every palette, light or dark, so full wash is what is drawn.
                amount: arc.crit ? 0.24 : arc.warn ? 0.18 : 0
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

        // A bar the width of the group's ground, the shape panels/Monitor.qml
        // already draws its per-core and per-disk meters with. The track and
        // its fill are both marked as grounds, because design 19 stands text on
        // them and a bar's text is on the fill wherever the fill has reached.
        component Track: Item {
            id: tr
            property real pct: 0
            property bool crit: false
            implicitWidth: 42
            implicitHeight: 3
            Wash {
                anchors.fill: parent
                radius: 1.5
                tone: Shell.Theme.line
                amount: 1
            }
            Wash {
                width: parent.width * Math.max(0, Math.min(1, tr.pct / 100))
                height: parent.height
                radius: 1.5
                tone: tr.crit ? Shell.Theme.bad : Shell.Theme.accent
                under: Shell.Theme.line
                amount: 1
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

        // Three of one design, at the rings group's real 9px spacing, with all
        // three kept and every number read back off the built items.
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
            property int claim: 0
            property int smallest: 0
            property real minContrast: 99
            property var rows: []

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

            // Every tinted ground inside one element, in draw order, with its
            // box in the element's own coordinates. Later ones are on top, so
            // the walk below takes the last match.
            function grounds(item: Item, el: Item, out: var): void {
                for (const ch of item.children) {
                    if (!ch.visible)
                        continue;
                    if (ch.objectName === "wash" && ch.amount > 0) {
                        const p = ch.mapToItem(el, 0, 0);
                        out.push({ x: p.x, y: p.y, w: ch.width, h: ch.height,
                                   c: root.over(ch.tone, ch.amount, ch.under) });
                    }
                    st.grounds(ch, el, out);
                }
            }

            // Every Text inside one element, scored against the ground its own
            // centre falls on. This is the only honest way to do it: a caption
            // anchored under the ring is outside the wash and a number anchored
            // in the middle of it is not, and no property on the design says so
            // — the geometry does.
            function scoreTexts(item: Item, el: Item, gs: var, metric: string): void {
                for (const ch of item.children) {
                    if (!ch.visible)
                        continue;
                    if (ch.font !== undefined && ch.text !== undefined
                            && String(ch.text).length > 0) {
                        const p = ch.mapToItem(el, ch.width / 2, ch.height / 2);
                        let g = Shell.Theme.bgHi, name = "plain bgHi";
                        for (const q of gs)
                            if (p.x >= q.x && p.x <= q.x + q.w
                                    && p.y >= q.y && p.y <= q.y + q.h) {
                                g = q.c;
                                name = "washed";
                            }
                        const v = root.wcag(ch.color, g);
                        st.rows.push({
                            metric: metric, text: String(ch.text),
                            size: ch.font.pixelSize, ink: String(ch.color),
                            ground: name, contrast: v
                        });
                        st.smallest = Math.min(st.smallest, ch.font.pixelSize);
                        st.minContrast = Math.min(st.minContrast, v);
                    }
                    st.scoreTexts(ch, el, gs, metric);
                }
            }

            // Both height numbers are the worst of the three rows, not the
            // first one. The first row is ram — the shortest strings on the
            // sheet — and a design measured on it alone reports 13/31 and never
            // learns what 845/947 does to it.
            function measure(): void {
                if (!a)
                    return;
                inkH = Math.max(extent(a).h, b ? extent(b).h : 0, c ? extent(c).h : 0);
                inkW = Math.max(extent(a).w, b ? extent(b).w : 0, c ? extent(c).w : 0);
                claim = Math.round(Math.max(a.implicitHeight,
                                            b ? b.implicitHeight : 0,
                                            c ? c.implicitHeight : 0));
                rows = [];
                smallest = 99;
                minContrast = 99;
                const names = ["ram", "root", "data"];
                const items = [a, b, c];
                for (let i = 0; i < 3; i++) {
                    if (!items[i])
                        continue;
                    const gs = [];
                    grounds(items[i], items[i], gs);
                    scoreTexts(items[i], items[i], gs, names[i]);
                }
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

        // 1. What ships, with the turned name taken off. The caption is
        // anchored to the ring's bottom edge with a -1 margin, so it is outside
        // the 28px box the layout is told about and lives in the 9px gap
        // instead (Ring.qml:154-161). Two facts, and the zero for every delta.
        Component {
            id: cBase
            Stack {
                el: Component {
                    El {
                        id: e1
                        implicitHeight: 28
                        Arc {
                            id: a1
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e1.m.pct
                            crit: e1.m.crit
                        }
                        Mid { anchors.centerIn: a1; text: e1.m.used }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a1.bottom
                            anchors.topMargin: -1
                            text: "/" + e1.m.tot
                        }
                    }
                }
            }
        }

        // 2. A caption over and a caption under. Every fact upright and
        // centred, nothing abbreviated, and two line-heights of new ink for it.
        // Brainitech's Speedometer.qml:4-7 puts the name above the arc exactly
        // this way. (Design 2 on the last sheet; numbers carried across.)
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
        // three characters, so "root" has to become "rot" and the number the
        // ring exists to show is demoted to the caption.
        Component {
            id: cInring
            Stack {
                el: Component {
                    El {
                        id: e3
                        implicitHeight: 28
                        Arc {
                            id: a3
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e3.m.pct
                            crit: e3.m.crit
                        }
                        Mid { anchors.centerIn: a3; text: e3.m.n3 }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a3.bottom
                            anchors.topMargin: -1
                            text: e3.m.frac
                        }
                    }
                }
            }
        }

        // 4. Two lines of caption. Nothing rotated, nothing shortened, nothing
        // below the floor — and the element grows by a whole line. Ricelin's
        // stack (SysmonSurface.qml:244-250) and the last sheet's runner-up.
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
        // (caelestia-shell/modules/bar/components/Clock.qml:96).
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

        // 6. Both numbers inside, with a hairline for the slash. Two 8px lines
        // is 20px, which is exactly the clear middle — and the hairline has to
        // come out of the same 20px. Both numbers are inside the wash.
        // (Design 9 on the last sheet.)
        Component {
            id: cStackin
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
                            Column {
                                anchors.centerIn: parent
                                spacing: -2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: e6.m.used
                                    color: Shell.Theme.fg
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.features: ({ tnum: 1 })
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: e6.m.tot
                                    color: Shell.Theme.dim
                                    font.pixelSize: 8
                                    font.features: ({ tnum: 1 })
                                }
                            }
                        }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a6.bottom
                            anchors.topMargin: -1
                            text: e6.m.n
                        }
                    }
                }
            }
        }

        // 7. The caption carries the whole fraction, with the total compressed
        // to terabytes where that is shorter. Still no name, so the two disks
        // still read alike. (Design 12 on the last sheet.)
        Component {
            id: cAbbrev
            Stack {
                el: Component {
                    El {
                        id: e7
                        implicitHeight: 28
                        Arc {
                            id: a7
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e7.m.pct
                            crit: e7.m.crit
                        }
                        Mid { anchors.centerIn: a7; text: e7.m.used }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a7.bottom
                            anchors.topMargin: -1
                            text: e7.m.abbr
                        }
                    }
                }
            }
        }

        // 8. The null answer, and the one to beat: the ring exactly as it is,
        // with the name as its caption and the total not shown at all. This is
        // already how cpu, °c and fan work. (Design 21 on the last sheet.)
        Component {
            id: cNameonly
            Stack {
                el: Component {
                    El {
                        id: e8
                        implicitHeight: 28
                        Arc {
                            id: a8
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e8.m.pct
                            crit: e8.m.crit
                        }
                        Mid { anchors.centerIn: a8; text: e8.m.used }
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

        // 9. The name and the total sharing the one caption row the ring
        // already pays for: "ram 31". No slash — the slash was only ever there
        // because the caption had nothing else in it to separate the total from
        // — and no second line, so the claim does not move.
        Component {
            id: cNametot
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
                        }
                        Mid { anchors.centerIn: a9; text: e9.m.used }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a9.bottom
                            anchors.topMargin: -1
                            text: e9.m.n + " " + e9.m.aTot
                        }
                    }
                }
            }
        }

        // 10. Design 4 with the used value taken out of the caption, since the
        // ring is already showing it. Two lines, but half the width: "root"
        // over "947" rather than "root" over "845/947".
        Component {
            id: cTwotot
            Stack {
                el: Component {
                    El {
                        id: e10
                        implicitHeight: 38
                        Arc {
                            id: a10
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e10.m.pct
                            crit: e10.m.crit
                            Mid { anchors.centerIn: parent; text: e10.m.used }
                        }
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a10.bottom
                            anchors.topMargin: -1
                            spacing: -2
                            Cap { anchors.horizontalCenter: parent.horizontalCenter; text: e10.m.n }
                            Cap { anchors.horizontalCenter: parent.horizontalCenter; text: "/" + e10.m.aTot }
                        }
                    }
                }
            }
        }

        // 11. Design 10 tucked the way design 5 tucks design 4.
        Component {
            id: cTwotott
            Stack {
                el: Component {
                    El {
                        id: e11
                        implicitHeight: 35
                        Arc {
                            id: a11
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e11.m.pct
                            crit: e11.m.crit
                            Mid { anchors.centerIn: parent; text: e11.m.used }
                        }
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a11.bottom
                            anchors.topMargin: -2
                            spacing: -3
                            Cap { anchors.horizontalCenter: parent.horizontalCenter; text: e11.m.n }
                            Cap { anchors.horizontalCenter: parent.horizontalCenter; text: "/" + e11.m.aTot }
                        }
                    }
                }
            }
        }

        // 12. The used value keeps its 10px in the middle and the total goes
        // under it at 8px with no rule between them; the name becomes the
        // caption. Design 6 without the demotion — but 10px over 8px is 18px of
        // a 20px hole, and both lines are in the wash.
        Component {
            id: cTotin
            Stack {
                el: Component {
                    El {
                        id: e12
                        implicitHeight: 28
                        Arc {
                            id: a12
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e12.m.pct
                            crit: e12.m.crit
                            Column {
                                anchors.centerIn: parent
                                spacing: -3
                                Mid {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: e12.m.used
                                }
                                Cap {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: e12.m.aTot
                                }
                            }
                        }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a12.bottom
                            anchors.topMargin: -1
                            text: e12.m.n
                        }
                    }
                }
            }
        }

        // 13. The total is not shown and neither are the gigabytes: the arc's
        // own number in the middle, the name underneath. Two facts, always two
        // glyphs in the hole whatever the disk is, and the name is the fact you
        // need first when a ring has gone red. noctalia's bar string is
        // literally "{percent}%" (Assets/Translations/en.json:1892).
        Component {
            id: cPctonly
            Stack {
                el: Component {
                    El {
                        id: e13
                        implicitHeight: 28
                        Arc {
                            id: a13
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e13.m.pct
                            crit: e13.m.crit
                        }
                        Mid { anchors.centerIn: a13; text: e13.m.pct }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a13.bottom
                            anchors.topMargin: -1
                            text: e13.m.n
                        }
                    }
                }
            }
        }

        // 14. Today's ring with the name added above it as a second caption and
        // "/total" left where it is. The smallest stacked answer that still
        // says all three things: design 2 with the used value not repeated in
        // the lower caption, so it is 15px narrower.
        Component {
            id: cAbove
            Stack {
                el: Component {
                    El {
                        id: e14
                        implicitHeight: 38
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: -1
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: e14.m.n
                            }
                            Arc {
                                id: a14
                                anchors.horizontalCenter: parent.horizontalCenter
                                pct: e14.m.pct
                                crit: e14.m.crit
                                Mid { anchors.centerIn: parent; text: e14.m.used }
                            }
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "/" + e14.m.aTot
                            }
                        }
                    }
                }
            }
        }

        // 15. The name above and the caption line given up entirely. Three
        // facts become two — and for once the ink stops at the claim, because
        // there is nothing hanging below the box.
        Component {
            id: cAboveBare
            Stack {
                el: Component {
                    El {
                        id: e15
                        implicitHeight: 38
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: -1
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: e15.m.n
                            }
                            Arc {
                                anchors.horizontalCenter: parent.horizontalCenter
                                pct: e15.m.pct
                                crit: e15.m.crit
                                Mid { anchors.centerIn: parent; text: e15.m.used }
                            }
                        }
                    }
                }
            }
        }

        // 16. Design 14 with the name anchored to the ring's *top* edge the way
        // the caption is anchored to its bottom, so the layout is still told 28
        // and the rail is told the design is free. It is not: the ring already
        // spends the whole 9px gap on the caption below it, and a second label
        // hanging above spends a gap that is not there. Kept because "hang it
        // outside the box like the caption does" is the first idea anyone has.
        Component {
            id: cHung
            Stack {
                el: Component {
                    El {
                        id: e16
                        implicitHeight: 28
                        Arc {
                            id: a16
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e16.m.pct
                            crit: e16.m.crit
                        }
                        Mid { anchors.centerIn: a16; text: e16.m.used }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: a16.top
                            anchors.bottomMargin: -1
                            text: e16.m.n
                        }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a16.bottom
                            anchors.topMargin: -1
                            text: "/" + e16.m.aTot
                        }
                    }
                }
            }
        }

        // 17. Not a ring at all. Name and percent on one row over a 3px track,
        // using the full 46px of the ground instead of the ring's 28. The row
        // is left and right aligned inside itself, which is what a bar is; the
        // element is still centred and nothing is turned.
        // (Design 14 on the last sheet.)
        Component {
            id: cBar
            Stack {
                el: Component {
                    El {
                        id: e17
                        implicitHeight: 16
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Item {
                                width: 42
                                height: 10
                                Cap { anchors.left: parent.left; text: e17.m.n }
                                Cap {
                                    anchors.right: parent.right
                                    text: e17.m.pct + "%"
                                    color: Shell.Theme.fg
                                }
                            }
                            Track { pct: e17.m.pct; crit: e17.m.crit }
                        }
                    }
                }
            }
        }

        // 18. The same with the fraction on its own row. Three facts, upright,
        // at the widest the ground allows. (Design 15 on the last sheet.)
        Component {
            id: cBar2
            Stack {
                el: Component {
                    El {
                        id: e18
                        implicitHeight: 27
                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            Item {
                                width: 42
                                height: 10
                                Cap { anchors.left: parent.left; text: e18.m.n }
                                Cap {
                                    anchors.right: parent.right
                                    text: e18.m.pct + "%"
                                    color: Shell.Theme.fg
                                }
                            }
                            Cap {
                                text: e18.m.frac
                                color: Shell.Theme.fg
                            }
                            Track { pct: e18.m.pct; crit: e18.m.crit }
                        }
                    }
                }
            }
        }

        // 19. The text laid over the track rather than above it. The shortest
        // element on the sheet that still carries all three facts — and the
        // only one that stands 8px type on a filled bar, which is why the
        // contrast column is the one to read on it. (Design 16 last time.)
        Component {
            id: cBarin
            Stack {
                el: Component {
                    El {
                        id: e19
                        implicitHeight: 13
                        Wash {
                            anchors.centerIn: parent
                            width: 42
                            height: 13
                            radius: 4
                            tone: Shell.Theme.line
                            amount: 1
                            Wash {
                                width: parent.width * Math.max(0, Math.min(1, e19.m.pct / 100))
                                height: parent.height
                                radius: parent.radius
                                tone: e19.m.crit ? Shell.Theme.bad : Shell.Theme.accent
                                under: Shell.Theme.line
                                amount: 0.45
                            }
                            Cap {
                                anchors.left: parent.left
                                anchors.leftMargin: 3
                                anchors.verticalCenter: parent.verticalCenter
                                text: e19.m.n
                                color: Shell.Theme.fg
                            }
                            Cap {
                                anchors.right: parent.right
                                anchors.rightMargin: 3
                                anchors.verticalCenter: parent.verticalCenter
                                text: e19.m.used
                            }
                        }
                    }
                }
            }
        }

        // 20. A ring where the metric is a rate and a bar where it is a
        // capacity. Drawn as one stack, because the rail carries both at once
        // and a mixed column is the thing that has to look deliberate.
        // (Design 17 on the last sheet.)
        Component {
            id: cMix
            Stack {
                el: Component {
                    El {
                        id: e20
                        implicitHeight: e20.m.n === "ram" ? 28 : 16
                        Arc {
                            id: a20
                            visible: e20.m.n === "ram"
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e20.m.pct
                            crit: e20.m.crit
                            Mid { anchors.centerIn: parent; text: e20.m.used }
                        }
                        Cap {
                            visible: e20.m.n === "ram"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a20.bottom
                            anchors.topMargin: -1
                            text: "/" + e20.m.tot
                        }
                        Column {
                            visible: e20.m.n !== "ram"
                            anchors.centerIn: parent
                            spacing: 2
                            Item {
                                width: 42
                                height: 10
                                Cap { anchors.left: parent.left; text: e20.m.n }
                                Cap {
                                    anchors.right: parent.right
                                    text: e20.m.abbr
                                    color: Shell.Theme.fg
                                }
                            }
                            Track { pct: e20.m.pct; crit: e20.m.crit }
                        }
                    }
                }
            }
        }

        // 21. REJECTED. Design 10 shrunk until it stops costing the rail
        // anything: two 7px lines fit under the ring inside the overhang the
        // rail already tolerates. It fits, it is free, and it is a point below
        // anything else on this bar. This is the sheet's trap and it is a new
        // one — the last sheet's version of it was wider, this one is not.
        Component {
            id: cMicro7
            Stack {
                el: Component {
                    El {
                        id: e21
                        implicitHeight: 28
                        Arc {
                            id: a21
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e21.m.pct
                            crit: e21.m.crit
                            Mid { anchors.centerIn: parent; text: e21.m.used }
                        }
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a21.bottom
                            anchors.topMargin: -2
                            spacing: -3
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: e21.m.n
                                font.pixelSize: 7
                            }
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "/" + e21.m.aTot
                                font.pixelSize: 7
                            }
                        }
                    }
                }
            }
        }

        // 22. REJECTED. Design 4 shrunk the same way. 6px is not small type, it
        // is texture. (Design 19 on the last sheet.)
        Component {
            id: cMicro6
            Stack {
                el: Component {
                    El {
                        id: e22
                        implicitHeight: 28
                        Arc {
                            id: a22
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e22.m.pct
                            crit: e22.m.crit
                            Mid { anchors.centerIn: parent; text: e22.m.used }
                        }
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a22.bottom
                            anchors.topMargin: -2
                            spacing: -2
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: e22.m.n
                                font.pixelSize: 6
                            }
                            Cap {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: e22.m.frac
                                font.pixelSize: 6
                            }
                        }
                    }
                }
            }
        }

        // 23. REJECTED. Both numbers inside the ring at 7px, under the wash a
        // disk at 95% is actually wearing — so this spends contrast and glyph
        // size in the same place, on the one ring that goes critical.
        // (Design 20 on the last sheet.)
        Component {
            id: cIn7
            Stack {
                el: Component {
                    El {
                        id: e23
                        implicitHeight: 28
                        Arc {
                            id: a23
                            anchors.horizontalCenter: parent.horizontalCenter
                            pct: e23.m.pct
                            crit: e23.m.crit
                            Column {
                                anchors.centerIn: parent
                                spacing: -2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: e23.m.used
                                    color: Shell.Theme.fg
                                    font.pixelSize: 7
                                    font.features: ({ tnum: 1 })
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: e23.m.tot
                                    color: Shell.Theme.dim
                                    font.pixelSize: 7
                                    font.features: ({ tnum: 1 })
                                }
                            }
                        }
                        Cap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: a23.bottom
                            anchors.topMargin: -1
                            text: e23.m.n
                        }
                    }
                }
            }
        }
    }
}
