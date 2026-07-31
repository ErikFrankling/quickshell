//@ pragma ShellId pillbounds

// Contact sheet. Eighteen ways to say where one workspace pill ends and the
// next begins, every one of them drawn at the rail's true 58px width, on the
// real Theme.bgHi ground the pills actually stand on, with the content that is
// actually in his rail: a focused pill with two icons, an idle pill with one,
// an idle pill with two, the empty workspace 9, and a two-digit "10" — five
// rows, so four boundaries between adjacent pills are visible in every column.
//
// Nothing here is asserted. Under each column the sheet prints:
//
//   h    the pill's measured height
//   gap  the measured distance between two adjacent pills
//   dL   the perceptual lightness step (CIE L*) between that design's boundary
//        mark and the group's ground, computed from the live Theme singleton,
//        so switching theme re-measures the whole sheet
//   ink  dL x the number of pixels the mark actually covers, which is the only
//        way a 140px outline and a 1232px fill can be compared at all
//
// dL rather than a WCAG ratio because a WCAG ratio compresses badly at the
// light end: Theme.line on Gruvbox Light reads 1.15 and on Kanagawa 1.62, a
// 1.4x spread, while the same two are 4.7 and 13.4 in dL — a 3.6x spread, and
// the second pair is the one that matches what the eye does with a hairline.
// The .md carries both, and the file:line citations.
//
// Harness only. Nothing here ships.
//
//   quickshell -p docs/surveys/pill-bounds.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "file:///home/erikf/projects/personal/quickshell" as Shell

ShellRoot {
    id: root

    // ---- colour maths, on the live palette ------------------------------

    function rgb(c) { return [c.r, c.g, c.b]; }
    function lin(v) { return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
    function lum(c) {
        const p = root.rgb(c).map(root.lin);
        return 0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2];
    }
    // CIE L*, 0-100. The perceptually even lightness scale.
    function lstar(c) {
        const y = root.lum(c);
        return y <= 216 / 24389 ? y * 24389 / 27 : Math.pow(y, 1 / 3) * 116 - 16;
    }
    // An alpha mark composited on the ground it is drawn over, because that is
    // the colour the eye is given — never the mark's own unblended value.
    function over(fg, a, bg) {
        return Qt.rgba(fg.r * a + bg.r * (1 - a),
                       fg.g * a + bg.g * (1 - a),
                       fg.b * a + bg.b * (1 - a), 1);
    }
    function step(mark, ground) {
        return Math.abs(root.lstar(mark) - root.lstar(ground ?? Shell.Theme.bgHi));
    }
    function wcag(mark, ground) {
        const x = root.lum(mark), y = root.lum(ground ?? Shell.Theme.bgHi);
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
    }

    // Theme.qml's own slot names over a raw base16 palette, so the sweep below
    // can be run against a scheme without loading it. Kept in step with
    // Theme.qml:26-49 by hand; there are seven names and they have not moved.
    function pal(p) {
        const q = c => Qt.color(c);
        return {
            bg: q(p.base00), bgAlt: q(p.base01), bgHi: q(p.base02), dim: q(p.base04),
            fg: q(p.base05), line: q(p.line ?? p.base03),
            accent: q(p.accent ?? p.base0D)
        };
    }

    // ---- the marks, one per design --------------------------------------
    //
    // The colour each design draws its boundary in, already composited, plus
    // how many pixels of a 44 x Theme.slot pill that mark covers. A 1px
    // outline is w*h - (w-2)*(h-2); a fill is w*h; a rule is its own width.
    readonly property int pw: 44
    readonly property int ph: Shell.Theme.slot
    readonly property int outline: root.pw * root.ph - (root.pw - 2) * (root.ph - 2)

    function markOf(d, theme) {
        const T = theme ?? Shell.Theme, g = T.bgHi;
        switch (d) {
        case "bline":   return T.line;
        case "bfg":     return root.over(T.fg, 0.12, g);
        case "bdim":    return root.over(T.dim, 0.25, g);
        case "bidle":   return root.over(T.dim, 0.25, g);
        case "bloud":   return root.over(T.dim, 0.45, g);
        case "gdim":    return root.over(T.dim, 0.10, g);
        case "gline":   return root.over(T.line, 0.5, g);
        case "gbgalt":  return T.bgAlt;
        case "gbg":     return T.bg;
        case "rline":   return T.line;
        case "rdim":    return root.over(T.dim, 0.25, g);
        case "rfull":   return root.over(T.dim, 0.25, g);
        case "rlayout": return root.over(T.dim, 0.25, g);
        case "alt":     return root.over(T.dim, 0.10, g);
        case "left":    return root.over(T.dim, 0.45, g);
        case "round":   return root.over(T.dim, 0.10, g);
        case "inset":   return root.over(T.fg, 0.06, g);
        case "bboth":   return root.over(T.dim, 0.25, g);
        default:        return g;
        }
    }

    function areaOf(d) {
        switch (d) {
        case "bline": case "bfg": case "bdim": case "bloud": case "bboth":
            return root.outline;
        case "bidle":   return root.outline;
        case "gdim": case "gline": case "gbgalt": case "gbg": case "alt": case "round":
            return root.pw * root.ph;
        case "rline": case "rdim":   return 24;
        case "rfull": case "rlayout": return root.pw;
        case "left":    return 2 * Math.round(root.ph * 0.55);
        case "inset":   return root.pw * 2;
        default:        return 0;
        }
    }

    readonly property var designs: [
        { d: "ship",    n: "1. shipped",        t: "idle is alpha(line,0) — the hue at zero alpha. nothing marks an idle pill at all. this is the complaint." },
        { d: "bline",   n: "2. border line",    t: "1px Theme.line on every pill. the obvious answer, and line is 3.7 dL from bgHi on Tokyo Night." },
        { d: "bfg",     n: "3. border fg .12",  t: "1px alpha(fg,0.12). even across themes but a whole step weaker on the two light ones." },
        { d: "bdim",    n: "4. border dim .25", t: "1px alpha(dim,0.25) on every pill. dim is the idle number's own colour, so box and label are one ink." },
        { d: "bidle",   n: "5. idle only",      t: "same border, dropped on the focused pill. the focused pill then sits 1px larger than its neighbours." },
        { d: "bloud",   n: "6. border dim .45", t: "the same border nearly twice as strong. rivals the focused fill on the light schemes." },
        { d: "gdim",    n: "7. ground dim .10", t: "a filled ground on every pill instead of an outline. what nine of fifteen surveyed shells do." },
        { d: "gline",   n: "8. ground line .5", t: "noctalia's idiom — alpha of the empty colour. capped by how close line is to bgHi." },
        { d: "gbgalt",  n: "9. ground bgAlt",   t: "an opaque step. wrong direction on dark schemes: bgAlt is below bgHi, so the pill sinks." },
        { d: "gbg",     n: "10. ground bg",     t: "the rail's own colour, punched through the group. reads as a hole, not a pill." },
        { d: "rline",   n: "11. rule line",     t: "one hairline over the gutter instead of four round each pill. one line where a border is four." },
        { d: "rdim",    n: "12. rule dim .25",  t: "the same rule at the visible strength. still says nothing about how wide a pill is." },
        { d: "rfull",   n: "13. rule full",     t: "the rule run the pill's full 44px. now it is a ladder of rungs with no stiles." },
        { d: "rlayout", n: "14. rule in layout", t: "the same rule as a real column item rather than an overlay. every boundary costs 1+slotGap." },
        { d: "alt",     n: "15. alternating",   t: "ground on every other pill. adjacent pills differ, but which pill is marked changes as workspaces come and go." },
        { d: "left",    n: "16. left marker",   t: "a bar at the left edge of each idle pill, mirroring the focused one's. two marks now mean two things." },
        { d: "round",   n: "17. round + ground", t: "ground plus radius = height/2. the shape reads as a discrete object; the radius alone does not." },
        { d: "inset",   n: "18. inset",         t: "1px light top, 1px dark bottom. an embossed edge at 6% is under 2 dL on the light schemes." },
        { d: "bboth",   n: "19. border + ground", t: "both channels at once. the boundary is unmistakable and the column is two tones louder than it was." }
    ]

    // ---- the cross-theme sweep -------------------------------------------
    //
    // The drawn sheet can only be in one theme at a time — a survey harness
    // has its own ShellId and therefore its own empty theme.json, so it draws
    // in Theme.qml's fallback. The numbers that decide the thing are the ones
    // across every scheme he actually wears, so they are computed here from
    // Themes.qml's own curated list rather than from a second copy of the
    // palettes: nine schemes, seven of them dark and two light.
    function sweep(rows) {
        let head = "".padEnd(22);
        for (const r of rows) head += r.name.substr(0, 12).padStart(14);
        console.log("SWEEP dL " + head);
        for (const design of root.designs) {
            let line = design.n.padEnd(22), lo = 999, hi = 0;
            for (const r of rows) {
                const p = root.pal(r.p);
                const v = design.d === "ship" ? 0 : root.step(root.markOf(design.d, p), p.bgHi);
                lo = Math.min(lo, v);
                hi = Math.max(hi, v);
                line += v.toFixed(1).padStart(14);
            }
            console.log("SWEEP dL " + line + "  | min " + lo.toFixed(1)
                + " max " + hi.toFixed(1) + " spread " + (hi / lo).toFixed(2) + "x");
        }
        for (const design of root.designs) {
            let line = design.n.padEnd(22);
            for (const r of rows) {
                const p = root.pal(r.p);
                const v = design.d === "ship" ? 1 : root.wcag(root.markOf(design.d, p), p.bgHi);
                line += v.toFixed(2).padStart(14);
            }
            console.log("SWEEP wcag " + line);
        }
        // What the boundary has to stay under: the focused pill's own fill,
        // which is the one thing on the rail that must keep winning.
        let f = "focused fill a(acc,.34)".padEnd(22), h = "hover fill line".padEnd(22);
        for (const r of rows) {
            const p = root.pal(r.p);
            f += root.step(root.over(p.accent, 0.34, p.bgHi), p.bgHi).toFixed(1).padStart(14);
            h += root.step(p.line, p.bgHi).toFixed(1).padStart(14);
        }
        console.log("SWEEP dL " + f);
        console.log("SWEEP dL " + h);
    }

    PanelWindow {
        anchors { top: true; left: true }
        margins { left: 12; top: 30 }
        implicitWidth: 1900
        implicitHeight: 430

        // Themes.qml's curated list is the one place the nine hand-picked
        // palettes exist; instantiated unseen so the sweep reads them rather
        // than carrying a second copy that can drift.
        Shell.Themes {
            id: schemes
            visible: false
            Component.onCompleted: root.sweep(schemes.curated)
        }
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "pill-bounds"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: Shell.Theme.bg
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                Text {
                    text: "Where does one workspace pill end? Eighteen designs at the rail's true 58px, on the real bgHi ground, with his real workspace set — theme: " + Shell.Theme.name
                    color: Shell.Theme.fg
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "h and gap are measured off the mocks; dL is the CIE L* step between the mark and the ground, computed from the live palette; ink is dL x the pixels the mark covers"
                    color: Shell.Theme.dim
                    font.pixelSize: 9
                }

                RowLayout {
                    spacing: 0
                    Layout.fillHeight: true

                    Repeater {
                        model: root.designs

                        ColumnLayout {
                            id: cell
                            required property var modelData
                            Layout.preferredWidth: 98
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 4

                            readonly property bool mine: modelData.d === "bdim"
                            readonly property color mark: root.markOf(modelData.d)
                            readonly property real dL: modelData.d === "ship" ? 0 : root.step(cell.mark)
                            readonly property real ratio: modelData.d === "ship" ? 1 : root.wcag(cell.mark)
                            readonly property real ink: cell.dL * root.areaOf(modelData.d)

                            // the strip, at the rail's true width, on the
                            // group's real ground
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 58
                                implicitHeight: 176
                                color: Shell.Theme.bgHi
                                radius: 4

                                ColumnLayout {
                                    id: col
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: 8
                                    spacing: Shell.Theme.slotGap

                                    Repeater {
                                        model: [
                                            { l: "4",  i: 2, f: true },
                                            { l: "5",  i: 1, f: false },
                                            { l: "8",  i: 2, f: false },
                                            { l: "9",  i: 0, f: false },
                                            { l: "10", i: 1, f: false }
                                        ]

                                        ColumnLayout {
                                            id: slot
                                            required property var modelData
                                            required property int index
                                            spacing: Shell.Theme.slotGap

                                            Pill {
                                                id: pill
                                                d: cell.modelData.d
                                                label: slot.modelData.l
                                                icons: slot.modelData.i
                                                focused: slot.modelData.f
                                                idx: slot.index
                                                last: slot.index === 4
                                            }

                                            // Design 14 alone puts its rule in
                                            // the column rather than over the
                                            // gutter, which is what makes it
                                            // cost height.
                                            Rectangle {
                                                visible: cell.modelData.d === "rlayout" && !pill.last
                                                Layout.preferredWidth: 44
                                                Layout.preferredHeight: visible ? 1 : 0
                                                color: cell.mark
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "h " + Math.round(col.children[0].children[0].height)
                                    + "   gap " + Math.round(col.children[1].y - col.children[0].y
                                        - col.children[0].children[0].height)
                                    + "   col " + Math.round(col.implicitHeight)
                                color: Math.round(col.implicitHeight) > 156 ? Shell.Theme.bad
                                     : cell.mine ? Shell.Theme.good : Shell.Theme.dim
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.dL.toFixed(1) + " dL   " + cell.ratio.toFixed(2) + ":1"
                                color: cell.dL < 4 ? Shell.Theme.bad
                                     : cell.mine ? Shell.Theme.good : Shell.Theme.fg
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "ink " + Math.round(cell.ink)
                                color: Shell.Theme.dim
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.modelData.n
                                color: cell.mine ? Shell.Theme.accent : Shell.Theme.fg
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.leftMargin: 3
                                Layout.rightMargin: 3
                                text: cell.modelData.t
                                color: Shell.Theme.dim
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Item { Layout.fillHeight: true }

                            Component.onCompleted: console.log("PILLBOUNDS "
                                + Shell.Theme.name + " | " + cell.modelData.n.padEnd(18)
                                + " h=" + Math.round(col.children[0].children[0].height)
                                + " gap=" + Math.round(col.children[1].y - col.children[0].y
                                    - col.children[0].children[0].height)
                                + " col=" + Math.round(col.implicitHeight)
                                + " dL=" + cell.dL.toFixed(2)
                                + " wcag=" + cell.ratio.toFixed(2)
                                + " ink=" + Math.round(cell.ink))
                        }
                    }
                }
            }
        }

        // ---- the mock -----------------------------------------------------
        //
        // One pill, every design switched inside it, built from the shipped
        // Workspaces.qml delegate so a number measured here is a number the
        // rail would have.
        component Pill: Rectangle {
            id: p

            required property string d
            required property string label
            required property int icons
            required property bool focused
            required property int idx
            required property bool last

            readonly property bool bordered:
                d === "bline" || d === "bfg" || d === "bdim" || d === "bloud"
                || d === "bboth" || (d === "bidle" && !focused)
            readonly property bool grounded:
                d === "gdim" || d === "gline" || d === "gbgalt" || d === "gbg"
                || d === "round" || d === "bboth" || (d === "alt" && idx % 2 === 1)

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 44
            implicitHeight: Shell.Theme.slot
            radius: d === "round" ? implicitHeight / 2 : Shell.Theme.radiusS

            color: p.focused ? Qt.alpha(Shell.Theme.accent, 0.34)
                 : !p.grounded ? Qt.alpha(Shell.Theme.line, 0)
                 : d === "gline" ? Qt.alpha(Shell.Theme.line, 0.5)
                 : d === "gbgalt" ? Shell.Theme.bgAlt
                 : d === "gbg" ? Shell.Theme.bg
                 : Qt.alpha(Shell.Theme.dim, 0.10)

            border.width: p.bordered ? 1 : 0
            border.color: d === "bline" ? Shell.Theme.line
                        : d === "bfg" ? Qt.alpha(Shell.Theme.fg, 0.12)
                        : d === "bloud" ? Qt.alpha(Shell.Theme.dim, 0.45)
                        : Qt.alpha(Shell.Theme.dim, 0.25)

            // the focused pill's accent bar, shipped, unchanged
            Rectangle {
                visible: p.focused
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 2
                height: parent.height * 0.55
                radius: 1
                color: Shell.Theme.accent
            }

            // designs 16: an idle pill's own left edge marker
            Rectangle {
                visible: p.d === "left" && !p.focused
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 2
                height: parent.height * 0.55
                radius: 1
                color: Qt.alpha(Shell.Theme.dim, 0.45)
            }

            // designs 11-13: a rule over the gutter above this pill, which
            // costs the column no height at all
            Rectangle {
                visible: (p.d === "rline" || p.d === "rdim" || p.d === "rfull") && p.idx > 0
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: Math.floor(Shell.Theme.slotGap / 2)
                width: p.d === "rfull" ? 44 : 24
                height: 1
                color: p.d === "rline" ? Shell.Theme.line : Qt.alpha(Shell.Theme.dim, 0.25)
            }

            // design 18: an embossed edge
            Rectangle {
                visible: p.d === "inset"
                anchors { top: parent.top; left: parent.left; right: parent.right }
                anchors.margins: 1
                height: 1
                color: Qt.alpha(Shell.Theme.fg, 0.06)
            }
            Rectangle {
                visible: p.d === "inset"
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                anchors.margins: 1
                height: 1
                color: Qt.alpha(Shell.Theme.bg, 0.55)
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 3

                Text {
                    text: p.label
                    color: p.focused ? Shell.Theme.accent : Shell.Theme.dim
                    font.pixelSize: 13
                    font.weight: p.focused ? Font.Bold : Font.Normal
                    Layout.maximumWidth: 20
                }

                Repeater {
                    model: p.icons
                    Image {
                        required property int index
                        source: Quickshell.iconPath(index === 0 ? "firefox" : "utilities-terminal",
                                                    "application-x-executable")
                        sourceSize.width: 13
                        sourceSize.height: 13
                        Layout.preferredWidth: 13
                        Layout.preferredHeight: 13
                        opacity: p.focused ? 1 : 0.62
                        smooth: true
                    }
                }
            }
        }
    }
}
