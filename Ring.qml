import QtQuick
import QtQuick.Layouts

// A metric as a filled ring: fuller and hotter the closer to the limit.
Item {
    id: root

    // The caption under the ring, and the only place a ring says anything in
    // words. A ring with one thing to say puts one word here — "cpu", "°c",
    // "fan". A ring with two puts both on the same row, separated by a space:
    // "ram 31", "root 947", "data 2.0T".
    //
    // That second word is the whole of what shipped from
    // docs/surveys/metric-centred.md, design 9, and it replaces the previous
    // answer to the same question — the metric's name turned −90° into the
    // 9px flank, which a01a930 shipped and Erik rejected on sight: "i hate how
    // you did this, they should be centralised." So nothing here is rotated
    // and nothing sits beside the ring. Twenty-three centred layouts were
    // drawn and measured against this one; sixteen of them survived the 8px
    // type floor, the contrast floor and the overhang budget, and design 9 is
    // the only survivor that says all three facts for **zero** extra rail
    // height: claim 28 and ink 38, which is exactly what a two-fact ring
    // already costs. The row it uses is the row the ring was already paying
    // for.
    //
    // The slash the caption used to begin with is gone with the flank, and
    // that is a choice rather than a saving — measured, "ram/31" and "ram 31"
    // are both 29px, because the font is monospaced and a slash and a space
    // are the same cell. It goes because the caption is no longer a fraction.
    // The numerator is inside the ring; a slash between a *name* and a total
    // asserts a ratio between two things that are not in one, and the battery
    // says "bat 87" in the same grammar, where a slash would be a plain lie.
    // One caption row, one reading: a name, then its second number.
    property string label: ""
    property real value: 0        // 0..100
    property string text: ""      // centre text; defaults to rounded value

    // A mark that stands in the middle instead of a number.
    //
    // Empty on every ring but one. The battery's charge is the one reading on
    // this rail where *which way it is going* matters as much as the number,
    // and the ring had nowhere to say so: the clear middle is 20px across and
    // the number is already in it, the arc is already spoken for by the charge
    // and the ground by the warning level.
    //
    // So while it is charging the two swap places — the bolt takes the middle
    // at 14px and the charge drops into the caption's second word, which
    // design 9 has just taught every ring on this rail to read. Nothing else
    // about the ring changes: the arc still runs on the charge, the ground
    // still washes on the warning level, and the blink is still gated off by
    // the same !Sys.charging it always was.
    //
    // Three reasons this is a glyph and not a colour. His own waybar answered
    // this exact question with a glyph and nothing else — the bolt is hard
    // coded into the AC-side format string (config.jsonc:55) and there is no
    // #battery.charging rule anywhere in style.css — so this is the affordance
    // he had for years, not a new opinion. A hue would be unreadable on two of
    // the nine palettes he wears: Theme.good and Theme.accent are the *same
    // colour* on Everforest (#a7c080 both) and 1.02:1 apart on Nord, so a ring
    // that said "charging" by turning its arc green would say nothing at all
    // there. And drawn in Theme.fg the mark introduces no new (ink, ground)
    // pair to score — it is the same ink at the same place as the number it
    // replaces, so it holds the number's own 5.14 plain / 3.98 warning / 3.37
    // critical across the curated nine and the wash question does not reopen.
    //
    // Prior art puts the bolt in the same place: noctalia overlays it dead
    // centre on the battery body (Modules/Bar/Widgets/NBattery.qml:187-204)
    // and tripathiji1312 the same (modules/bar/components/Battery.qml:182-197).
    // noctalia has to *alternate* it with the percentage on a 4s timer
    // (:104-110) because a 22×14 body holds one or the other. This ring does
    // not: it has a caption row, and design 9 just gave that row a second word.
    property string glyph: ""

    // What the colour is keyed off, when that is not the fill. Battery is the
    // one metric here where a full ring is the good news, so it hands over
    // 100 - charge and goes red on the way to empty rather than on the way up.
    property real heat: value

    // Where the metric stops being fine and where it stops being survivable,
    // in heat's terms — so a ring that names neither lights exactly where
    // Theme.heat already turned the arc, and a ring that means something else
    // by "full" says so once, at the call site, in the units it is read in.
    property real warnAt: 70
    property real critAt: 90

    // Waybar's `states`, which is where this whole idea comes from: a pair of
    // thresholds in the module config puts a .warning or .critical class on the
    // widget, and the stylesheet then colours *the module* rather than only its
    // text (his config.jsonc:50-53 for the battery, style.css:101-107 for what
    // that does). Here that is a wash over the ring's own ground.
    readonly property int level: heat >= critAt ? 2 : heat >= warnAt ? 1 : 0
    readonly property color tone: level === 2 ? Theme.bad
                                : level === 1 ? Theme.warn : Theme.accent

    // Blinking is opt-in and only two rings ask for it. His waybar is the same:
    // #battery is given an animation-name and #memory is not — it carries the
    // timing properties and never gets a keyframe to run (style.css:135-147) —
    // so memory colours and holds still. The reason is his: a flash he cannot
    // answer is a flash he teaches himself to ignore.
    property bool blink: false

    // And waybar's period, exactly: animation-duration 3s warning, 2s critical,
    // animation-direction alternate (style.css:109-117), so one full breath is
    // six seconds and four. The animation drives a plain scalar rather than the
    // colour, because an animation attached to a property owns it — binding the
    // wash to `pulse` instead keeps the colour a binding, and lets the ring go
    // back to a steady wash the instant the blinking stops.
    property real pulse: 1

    SequentialAnimation on pulse {
        id: breath

        running: root.blink && root.level > 0
        loops: Animation.Infinite
        NumberAnimation {
            to: 0.15
            duration: root.level === 2 ? 2000 : 3000
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 1
            duration: root.level === 2 ? 2000 : 3000
            easing.type: Easing.InOutSine
        }
    }

    Layout.alignment: Qt.AlignHCenter
    // One rail slot, like every other control on the rail. The caption below is
    // the one thing on the rail that lives outside its slot: it is a label on
    // the ring rather than a control of its own, so it hangs into the gap under
    // it and the rings group is given a wider gap to carry it. Under the last
    // ring there is no gap, only the group's bottom pad, so the group adds
    // `overhang` to it — see the bottom of this file and rail.ringPad.
    implicitWidth: Theme.slot
    implicitHeight: Theme.slot

    // The wash. 18% and 24% are as much of it as the number standing on top can
    // afford: measured across all 335 schemes the shell ships, the median cost
    // to the number's contrast is 22%, and on the three he actually uses it
    // lands at 3.7/4.3 (Gruvbox dark, from 5.1), 3.5/3.7 (Everforest, from 4.8)
    // and 7.7/6.1 (One Light, from 9.0). A previous attempt at this washed hard
    // enough to leave the number at 1.3:1, which is not dim, it is gone.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Qt.alpha(root.tone, root.level === 0 ? 0
            : (root.level === 2 ? 0.24 : 0.18) * (breath.running ? root.pulse : 1))
    }

    Canvas {
        id: c
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            const w = width, r = w / 2 - 2.5;
            ctx.reset();
            ctx.lineWidth = 3;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.arc(w / 2, w / 2, r, 0, Math.PI * 2);
            ctx.strokeStyle = Theme.line;
            ctx.stroke();

            const frac = Math.max(0, Math.min(1, root.value / 100));
            if (frac > 0) {
                ctx.beginPath();
                // start at 12 o'clock
                ctx.arc(w / 2, w / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * frac);
                ctx.strokeStyle = root.tone;
                ctx.stroke();
            }
        }
    }

    // Canvas does not repaint on property change by itself.
    onValueChanged: c.requestPaint()
    onToneChanged: c.requestPaint()

    // The middle. 14px for a mark, 10px DemiBold for a number, because a glyph
    // has to carry across a desk on its shape where a number is read up close
    // and only has to fit: the bolt lays out 11px of ink across and 14 down,
    // which clears the 20px hole by three pixels on its tight axis and reads
    // as a shape rather than as a character at arm's length.
    //
    // alignWhenCentered off for the same reason Btn.qml turns it off
    // (Btn.qml:119-162): Qt's hcenter() rounds an odd-width item half a pixel
    // left to snap it to the grid, and this font lays the bolt out 9px wide
    // and every digit string even, so the flag moves the mark and moves no
    // number.
    Text {
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        text: root.glyph !== "" ? root.glyph
            : root.text !== "" ? root.text : Math.round(root.value)
        color: Theme.fg
        font.pixelSize: root.glyph !== "" ? 14 : 10
        font.weight: root.glyph !== "" ? Font.Normal : Font.DemiBold
    }

    // Anchored to the ring's bottom *edge*, so it hangs outside the 28px box
    // the layout is told about and costs the rail nothing. It is also the
    // widest thing the ring draws — 44px for "data 2.0T" against the ring's
    // own 28 — and it is the reason the rings group's spacing is 9 where every
    // other group on the rail uses Theme.slotGap.
    //
    // Sideways it is now inside its ground with room to spare: Theme.groupWidth
    // went 46 → 50 so the widest of these has 3px of ground on its left and 4
    // on its right instead of 1 and 2, which is what Erik was pointing at when
    // he said the caption was going too far.
    //
    // Downwards it was not, and that was the open half of the same complaint.
    // The caption reaches 10px below the ring while a group pads Theme.groupPad
    // = 6 under its last child, so the *last* ring in the group — the battery
    // on a laptop, the last disk on this desktop — drew its caption over the
    // group's bottom edge, and once that group learned to clip it lost the ends
    // outright: ink on rows y666..672 against a ground that stopped at y670.
    // Erik on seeing it: "there is just empty space but things are getting cut
    // off", and there were 70 pixels of it under the block.
    //
    // The block pays for it now. `overhang` below is what it asks, rail.ringPad
    // in shell.qml is where it is added, and the 10px comes out of the slack
    // that was sitting empty. The alternative was to take it off the 9px
    // spacing between rings, which buys the same pixels by pushing every
    // caption harder into the ring under it — a real cost, paid to protect a
    // budget that had 70px going spare. See docs/surveys/metric-centred.md.
    Text {
        id: cap

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: -1
        text: root.label
        color: Theme.dim
        font.pixelSize: 8
    }

    // How far the caption reaches below the slot the layout was told about.
    // The ring hands this out rather than leaving every caller to rediscover
    // it: a column of rings carries the overhang in the gap between them, but
    // whoever is *last* in that column hangs over the bottom of whatever
    // contains it, and a container that does not add this to its own bottom
    // padding will cut a caption it is itself drawing.
    //
    // Measured off the caption rather than written down as a number, so it
    // follows the font and cannot go stale — the last number written down for
    // this said 6 and it measures 10. Off the caption's own box and not its
    // ink: the box is what QML can answer for, and it is the larger of the two,
    // so the ground it buys clears the ink on every string and every font.
    readonly property real overhang: cap.height + cap.anchors.topMargin
}
