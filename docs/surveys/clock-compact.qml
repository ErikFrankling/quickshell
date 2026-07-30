//@ pragma ShellId clockcompact

// Contact sheet, second pass. Can hours, minutes, day and month go *below*
// 36px in a 58px rail — and what does each attempt actually cost?
//
// The first sheet (clock-survey.qml) measured thirteen shells as they are
// written. Every one of them stacks: the time is two lines down the rail and
// the date is more lines under it. RailClock won that survey at 36px by
// turning the date on its side into the margin the stacked time leaves free.
//
// So this sheet attacks the thing the first one left alone: the stack itself.
// The rail is 58px wide and the shell's font is JetBrains Mono, ~0.6em per
// glyph. That is 9 characters of room at 10px and 6 at 15px — "17:47" fits
// across the rail with a third of the width still spare. A clock that goes
// across costs one line instead of two, and the width was free the whole time.
//
// Fifteen designs, none of them in the first sheet, plus RailClock as the
// baseline. The number under each is measured, not claimed: the mock is built
// and then asked how tall and how wide it came out. Width matters here in a
// way it did not before — the shortest design here fails at 67px wide, not by
// being tall, and a design that overflows the rail is not a design.
//
// Legibility is a hard floor, not a tiebreak. The floor is what already ships:
// nothing smaller than 9px, and nothing dimmer than Theme.dim, which is what
// RailClock's rotated date already uses. Four designs below break it. They are
// drawn and measured anyway, marked in red, because "this is what 7px looks
// like at arm's length" is a finding and deleting it just invites someone to
// try it again next year.
//
// ---------------------------------------------------------------------------
// RECOMMENDATION: design 1, the row with the date under it. 28px against the
// baseline's 36, and — this is the part that matters — it is the only design
// here that gets shorter while getting *easier* to read. HH:mm on one line at
// 15px is a time; HH over mm is two numbers you assemble into a time. The date
// is the same 9px Theme.dim it already is, but upright instead of turned.
// Nothing was traded for the 8px.
//
// Design 7 is shorter still at 18px and should not be taken: it pays for the
// record with a 12px colonless time, which shrinks the one element on the rail
// that has to be read rather than recognised.
//
// And the date does belong in the rail. Design 4 is the same clock with the
// date deleted and measures 20px, so the whole date costs 8px — while the move
// to a row saves 8px on its own. Keeping the date is free relative to today.
// The full argument and the file:line citations are in clock-compact.md.
// ---------------------------------------------------------------------------
//
// Harness only. Nothing here ships.
//
//   quickshell -p docs/surveys/clock-compact.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "file:///home/erikf/projects/personal/quickshell" as Shell

ShellRoot {
    PanelWindow {
        id: sheet
        anchors { top: true; left: true }
        margins { left: 16; top: 24 }
        implicitWidth: 1856
        implicitHeight: 500
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "clock-compact"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        SystemClock { id: clock; precision: SystemClock.Seconds }

        // The strings, in one place, so every mock says the same thing and no
        // design wins by quietly showing less than the others.
        readonly property string hh: Qt.formatDateTime(clock.date, "HH")
        readonly property string mm: Qt.formatDateTime(clock.date, "mm")
        readonly property string hhmm: Qt.formatDateTime(clock.date, "HH:mm")
        readonly property string dmon: Qt.formatDateTime(clock.date, "dd MMM").toUpperCase()
        readonly property string dnum: Qt.formatDateTime(clock.date, "dd/MM")
        readonly property string dd: Qt.formatDateTime(clock.date, "dd")
        readonly property string mon: Qt.formatDateTime(clock.date, "MMM").toUpperCase()

        Rectangle {
            anchors.fill: parent
            color: "#11141a"
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Text {
                    text: "Below 36px? Fifteen new attempts at hours, minutes, day and month in a 58px rail — plus RailClock, the 36px to beat"
                    color: "#d3c6aa"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "measured, not claimed. width is measured too: the rail is 58px, and the shortest design on the sheet is disqualified by width rather than height. "
                        + "legibility floor is what already ships — 9px, Theme.dim. below it is rejected, drawn in red, and kept so the number is on the record."
                    color: "#859289"
                    font.pixelSize: 10
                }

                RowLayout {
                    spacing: 0
                    Layout.fillHeight: true

                    Repeater {
                        model: [
                            { n: "1. Row, date under",       k: "row1", ok: 1, t: "the stack laid on its side. HH:mm at 15px across the rail, dd MMM at 9px under it, tucked -4 into the slack digits leave below the baseline." },
                            { n: "2. Row, date under, big",  k: "row2", ok: 1, t: "the same, spending some of what it saved on type: 16px time, 10px date. the easiest read on the sheet, and still under the baseline." },
                            { n: "3. Row, no date",          k: "bare", ok: 1, t: "18px HH:mm and nothing else — the largest digits the rail can hold. the date lives on the calendar the clock already opens." },
                            { n: "4. Row, no date, small",   k: "bare2", ok: 1, t: "the same at 15px, matching every other label on the rail. the floor of the whole problem: one line of time, nothing more." },
                            { n: "5. Hairline colon",        k: "hair", ok: 1, t: "the colon promoted to a 1px rule between the digit pairs, the way the old vertical design's dash was. date under at 9px." },
                            { n: "6. Split flank",           k: "flank", ok: 1, t: "date cut in half and stood up either side — 30 left, JUL right, 15px time between. the shortest column here, and too wide for the rail." },
                            { n: "7. Split flank, to fit",   k: "flank2", ok: 1, t: "the same squeezed into 58px: colon dropped, time down to 12px. it fits, it is the shortest thing on the sheet, and the time is now the smallest type on the rail." },
                            { n: "8. Row, date turned",      k: "turn", ok: 1, t: "horizontal time, RailClock's rotated date beside it. the turned date is itself 36px tall, so laying the time down under it buys nothing." },
                            { n: "9. Row, turned digits",    k: "turn2", ok: 1, t: "the same with 30/07 instead of 30 JUL — five glyphs instead of six, so the turned column is shorter. two numbers, either order." },
                            { n: "10. Time turned",          k: "rot", ok: 1, t: "the whole clock as one turned line, HH:mm reading up the rail. nobody in either survey does this, and the measurement says why." },
                            { n: "11. Time+date turned",     k: "rot2", ok: 1, t: "the same taken to its conclusion: everything on one turned line. the most compact idea on paper and the tallest thing on the sheet." },
                            { n: "12. Watermark",            k: "wash", ok: 0, t: "date drawn inside the time's own box at low alpha — zero pixels, and below Theme.dim by construction. rejected on contrast." },
                            { n: "13. Micro date",           k: "micro", ok: 0, t: "the row with the date at 7px. it measures well and cannot be read at a desk. rejected on type size." },
                            { n: "14. Sandwich",             k: "sand", ok: 0, t: "AsteroidOS digital-outfit: date on its own line between the hour and the minute. drawn at rail scale the date lands at 8px." },
                            { n: "15. Analog",               k: "dial", ok: 0, t: "a 24px face with the date under it. shortest of all, and you cannot read a minute off a 24px dial. rejected on precision." },
                            { n: "16. RailClock — baseline", k: "base", ok: 1, t: "what ships today. stacked time, date turned into the margin it leaves free. the height is set by the turned date, not by the time." }
                        ]

                        ColumnLayout {
                            id: cell
                            required property var modelData
                            readonly property int h: Math.round(shape.height)
                            readonly property int w: Math.round(shape.width)
                            readonly property bool fits: w <= 58
                            readonly property bool wins: modelData.ok && fits && h < 36

                            Layout.preferredWidth: 113
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 5

                            // The strip, at the rail's real width. Anything the
                            // design does past 58px hangs out of it visibly.
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 58
                                implicitHeight: 132
                                color: Shell.Theme.bg
                                radius: 4

                                Loader {
                                    id: shape
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 10
                                    sourceComponent: {
                                        switch (cell.modelData.k) {
                                        case "row1": return cRow1;
                                        case "row2": return cRow2;
                                        case "bare": return cBare;
                                        case "bare2": return cBare2;
                                        case "hair": return cHair;
                                        case "flank": return cFlank;
                                        case "flank2": return cFlank2;
                                        case "turn": return cTurn;
                                        case "turn2": return cTurn2;
                                        case "rot": return cRot;
                                        case "rot2": return cRot2;
                                        case "wash": return cWash;
                                        case "micro": return cMicro;
                                        case "sand": return cSand;
                                        case "dial": return cDial;
                                        default: return cBase;
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.h + "px"
                                color: cell.modelData.k === "base" ? "#9ece6a"
                                     : !cell.modelData.ok ? "#f7768e"
                                     : cell.wins ? "#9ece6a" : "#d3c6aa"
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.fits ? cell.w + "px wide" : cell.w + "px wide — OVERFLOWS"
                                color: cell.fits ? "#859289" : "#f7768e"
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: !cell.modelData.ok ? "REJECTED"
                                    : !cell.fits ? "too wide"
                                    : cell.h < 36 ? "beats 36" : "no gain"
                                color: !cell.modelData.ok || !cell.fits ? "#f7768e"
                                     : cell.h < 36 ? "#9ece6a" : "#859289"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.modelData.n
                                color: cell.modelData.k === "base" ? Shell.Theme.accent
                                     : cell.modelData.k === "row1" ? "#9ece6a" : "#d3c6aa"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.leftMargin: 3
                                Layout.rightMargin: 3
                                text: cell.modelData.t
                                color: "#859289"
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }
        }

        // ---- shared pieces -----------------------------------------------

        // A line of time. DemiBold, because at these sizes the digits are the
        // only thing on the rail that has to be read rather than recognised.
        component Time: Text {
            color: Shell.Theme.fg
            font.pixelSize: 15
            font.weight: Font.DemiBold
            // Tabular figures. In a fixed-width slot proportional digits make a
            // centred clock shuffle sideways every minute — noctalia sets this
            // on both its bar clocks for exactly that reason
            // (noct4/Modules/Bar/Widgets/Clock.qml:108,135).
            font.features: ({ tnum: 1 })
        }

        component Date: Text {
            color: Shell.Theme.dim
            font.pixelSize: 9
            font.letterSpacing: 0.5
            font.features: ({ tnum: 1 })
        }

        // Text stood on its side, in a slot the size of the box it needs.
        // Measured unconstrained and read back transposed, the way RailClock
        // and RailPlayer size their turned labels. advanceWidth, not width:
        // width is rounded down, and a turned label given its own rounded-down
        // length elides the glyph that did not fit. shub39 writes the same
        // swap as Layout.preferredWidth: t.implicitHeight / preferredHeight:
        // t.implicitWidth (shub39_dotfiles/quickshell/bar/PlayingMedia.qml:66-85).
        component Turned: Item {
            property alias text: t.text
            property alias font: t.font
            property color tint: Shell.Theme.dim
            implicitWidth: t.implicitHeight
            implicitHeight: Math.ceil(tm.advanceWidth)
            TextMetrics { id: tm; font: t.font; text: t.text }
            Text {
                id: t
                anchors.centerIn: parent
                rotation: -90
                color: parent.tint
                font.pixelSize: 9
                font.letterSpacing: 0.5
                font.features: ({ tnum: 1 })
            }
        }

        // ---- the designs ---------------------------------------------------

        // 1. The stack laid on its side. HH:mm reads across the rail in one
        // line, dd MMM sits under it, and the two are tucked together the way
        // caelestia tucks its hour and minute
        // (caelestia-shell/modules/bar/components/Clock.qml:96). Nothing here
        // is new except the direction: this is tripathiji1312's horizontal bar
        // clock — 12px time, 10px date *beside* it, one Row
        // (clones/tripathiji1312_quickshell/modules/bar/components/Clock.qml:17-78)
        // — folded so the date goes under instead of alongside, because a rail
        // has 58px of width and no more.
        Component {
            id: cRow1
            Column {
                // -4, not -2. Digits have no descenders, so the four pixels a
                // 15px line reserves below its baseline are empty; the date
                // moves up into them and nothing collides. This is caelestia's
                // tuck (caelestia-shell/modules/bar/components/Clock.qml:96)
                // spent on the gap between time and date rather than between
                // hour and minute.
                spacing: -4
                Time {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: sheet.hhmm
                }
                Date {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: sheet.dmon
                }
            }
        }

        // 2. The same, spending some of what it saved on type. 16px and 10px is
        // the largest this design goes before dd MMM runs out of rail.
        Component {
            id: cRow2
            Column {
                spacing: -2
                Time {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: sheet.hhmm
                    font.pixelSize: 16
                }
                Date {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: sheet.dmon
                    font.pixelSize: 10
                }
            }
        }

        // 3. Time alone, as big as the rail will take. 18px x 5 monospace
        // glyphs is 54px of the 58. bjarneo does this vertically and hangs the
        // date off a tooltip and a click (bjarneo_quickshell/desktop/Bar.qml:147-202);
        // Brainitech swaps the date into the same Text on right-click, so it
        // costs no pixels at all (clones/Brainitech_Brain_Shell/src/modules/Right/Clock.qml:15-51).
        Component {
            id: cBare
            Time { text: sheet.hhmm; font.pixelSize: 18 }
        }

        // 4. The same at the rail's own 15px. This is the floor of the problem:
        // one line of time, nothing else, no tricks.
        Component {
            id: cBare2
            Time { text: sheet.hhmm }
        }

        // 5. The colon promoted to a rule, which is what this shell already did
        // to noctalia's dash when the clock ran down the rail — there it had to
        // run vertically to cost nothing, here it runs vertically because that
        // is simply what a separator between two side-by-side things looks
        // like. Ambxst flips one separator component between the two
        // orientations for the same reason
        // (repos/Axenide_Ambxst/modules/components/Separator.qml).
        Component {
            id: cHair
            Column {
                spacing: -2
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3
                    Time { text: sheet.hh; font.pixelSize: 16 }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 11
                        color: Shell.Theme.line
                    }
                    Time { text: sheet.mm; font.pixelSize: 16 }
                }
                Date {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: sheet.dmon
                }
            }
        }

        // 6. The date cut in half and stood up on both sides, so neither turned
        // column is longer than the one line of time between them. On height
        // this is the best answer on the sheet. On width it is two rotated
        // slots plus a whole clock, and the rail is 58px — the time has to come
        // down to 13px to fit, which is smaller than anything else the rail
        // shows, and it still only just makes it.
        Component {
            id: cFlank
            Row {
                spacing: 2
                Turned {
                    anchors.verticalCenter: parent.verticalCenter
                    text: sheet.dd
                }
                Time {
                    anchors.verticalCenter: parent.verticalCenter
                    text: sheet.hhmm
                    font.pixelSize: 13
                }
                Turned {
                    anchors.verticalCenter: parent.verticalCenter
                    text: sheet.mon
                }
            }
        }

        // 7. The same idea forced to fit. The colon goes, which costs a glyph
        // of width, and the time comes down to 12px, which costs three more.
        // It fits, and it is the shortest thing on the sheet — but look at what
        // paid for it. The time is now smaller than every other label on the
        // rail, and the time is the one thing on a clock that has to be read
        // rather than recognised. This is the design that proves the height
        // record is not worth having.
        Component {
            id: cFlank2
            Row {
                spacing: 1
                Turned {
                    anchors.verticalCenter: parent.verticalCenter
                    text: sheet.dd
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Time { text: sheet.hh; font.pixelSize: 12 }
                    Time { text: sheet.mm; font.pixelSize: 12 }
                }
                Turned {
                    anchors.verticalCenter: parent.verticalCenter
                    text: sheet.mon
                }
            }
        }

        // 8. Horizontal time with RailClock's own turned date beside it. The
        // point of the measurement: the baseline's 36px is not the cost of the
        // stacked time, it is the cost of the turned date — six glyphs at 9px
        // is 36px whichever way the time is laid out. Turning the clock
        // sideways underneath it changes nothing.
        Component {
            id: cTurn
            Row {
                spacing: 3
                Time {
                    anchors.verticalCenter: parent.verticalCenter
                    text: sheet.hhmm
                    font.pixelSize: 14
                }
                Turned {
                    anchors.verticalCenter: parent.verticalCenter
                    text: sheet.dmon
                }
            }
        }

        // 9. The same with a five-glyph date instead of a six-glyph one, which
        // is the only lever the turned column has. It buys 6px and costs the
        // month its letters: 30/07 and 07/30 are the same picture, which is why
        // RailClock spells the month in the first place.
        Component {
            id: cTurn2
            Row {
                spacing: 3
                Time {
                    anchors.verticalCenter: parent.verticalCenter
                    text: sheet.hhmm
                    font.pixelSize: 14
                }
                Turned {
                    anchors.verticalCenter: parent.verticalCenter
                    text: sheet.dnum
                }
            }
        }

        // 10. The whole clock as one turned line. nucleus-shell is the only
        // project in either survey that really rotates a clock — it turns the
        // row 90 and the clock 270 back, so the text lands upright
        // (repos/nucleus-shell, bar/content/ClockModule.qml) — and nobody turns
        // the *reading direction*. The measurement is why: five glyphs of 15px
        // monospace is 45px of rail whichever axis you spend it on, and it is
        // 45px you now have to tilt your head to read.
        Component {
            id: cRot
            Turned {
                text: sheet.hhmm
                tint: Shell.Theme.fg
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
        }

        // 11. And its conclusion. One turned line carrying everything is the
        // most compact idea on paper — no leading, no separator, no second
        // column — and it is the tallest thing on the sheet, taller than the
        // 92px design this whole exercise started from.
        Component {
            id: cRot2
            Turned {
                text: sheet.hhmm + "  " + sheet.dmon
                tint: Shell.Theme.fg
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
        }

        // 12. REJECTED — contrast. The date drawn inside the time's own
        // bounding box, so it costs no pixels at all. It cannot work: the only
        // way two strings share one box is for one of them to get out of the
        // way, and the way it gets out of the way is alpha. Drawn here at the
        // 0.2 that noctalia uses for an *unlit* binary dot
        // (noct4/Widgets/NClock.qml:316-426) — that is the alpha of something
        // deliberately reading as off.
        Component {
            id: cWash
            Item {
                implicitWidth: t.implicitWidth
                implicitHeight: t.implicitHeight
                Text {
                    anchors.centerIn: parent
                    text: sheet.dmon
                    color: Qt.alpha(Shell.Theme.fg, 0.2)
                    font.pixelSize: 13
                    font.letterSpacing: 1
                }
                Time { id: t; text: sheet.hhmm; font.pixelSize: 17 }
            }
        }

        // 13. REJECTED — type size. Design 1 with the date at 7px. It measures
        // 2px better and it is a smudge at arm's length. Every project in both
        // surveys that shrinks a date stops at 9 or 10: end-4 at 10
        // (repos/snowarch_iNiR and end-4 verticalBar), noctalia at 8pt which is
        // 11px, DankMaterialShell at 12. Nothing ships a 7px date.
        Component {
            id: cMicro
            Column {
                spacing: -2
                Time {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: sheet.hhmm
                }
                Date {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: sheet.dmon
                    font.pixelSize: 7
                }
            }
        }

        // 14. REJECTED — type size, and it is not compact anyway. AsteroidOS's
        // digital-outfit watchface puts the date on its own line *between* the
        // hour and the minute — hour at 0.4 of the face, minute at 0.4, date at
        // 0.1 in the gap, all centred
        // (AsteroidOS/asteroid-launcher src/watchfaces/007-digital-outfit.qml).
        // It is a lovely face. Held to its own proportions on a rail whose time
        // is 15px, the date lands at 4px; drawn at 8 here to be visible at all,
        // it is still under the floor, and three lines is three lines.
        Component {
            id: cSand
            Column {
                spacing: -3
                Time { anchors.horizontalCenter: parent.horizontalCenter; text: sheet.hh }
                Date {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: sheet.dmon
                    font.pixelSize: 8
                }
                Time { anchors.horizontalCenter: parent.horizontalCenter; text: sheet.mm }
            }
        }

        // 15. REJECTED — precision. A 24px dial with a date under it. noctalia
        // ships an analog style (noct4/Widgets/NClock.qml:133-231) but as a
        // square panel widget, never in the bar. At 24px the minute hand moves
        // about a third of a pixel a minute at its tip: you can see that it is
        // roughly quarter past, which is not what a clock is for.
        Component {
            id: cDial
            Column {
                spacing: 0
                Canvas {
                    id: dial
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 24
                    height: 24
                    Connections {
                        target: clock
                        function onDateChanged() { dial.requestPaint(); }
                    }
                    onPaint: {
                        const c = getContext("2d");
                        c.reset();
                        const r = width / 2;
                        c.translate(r, r);
                        c.strokeStyle = Shell.Theme.line;
                        c.lineWidth = 1;
                        c.beginPath();
                        c.arc(0, 0, r - 1, 0, Math.PI * 2);
                        c.stroke();
                        c.strokeStyle = Shell.Theme.fg;
                        c.lineCap = "round";
                        const hand = (a, len, w) => {
                            c.save();
                            c.rotate(a);
                            c.lineWidth = w;
                            c.beginPath();
                            c.moveTo(0, 0);
                            c.lineTo(0, -len);
                            c.stroke();
                            c.restore();
                        };
                        const m = clock.date.getMinutes();
                        const h = clock.date.getHours() % 12 + m / 60;
                        hand(h * Math.PI / 6, r * 0.5, 2);
                        hand(m * Math.PI / 30, r * 0.8, 1.5);
                    }
                }
                Date {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: sheet.dmon
                }
            }
        }

        // 16. The baseline — RailClock.qml as it ships. Imported rather than
        // redrawn, so this number cannot drift away from the real one.
        Component {
            id: cBase
            Shell.RailClock {}
        }
    }
}
