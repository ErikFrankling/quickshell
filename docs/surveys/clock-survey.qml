//@ pragma ShellId clocksurvey

// Contact sheet. Thirteen real clock/date widgets, each redrawn at this rail's
// actual 58px width so they can be compared as one problem — fit hours,
// minutes and a date into a narrow vertical strip — rather than as screenshots
// at thirteen different scales.
//
// The number under each is its *measured* height at that width, content plus
// whatever padding its own project wraps it in. Nothing is asserted: the mock
// is built to the source's own numbers and then asked how tall it came out.
// Point sizes have been converted at 96dpi (pt x 1.333).
//
// clock-survey.md carries the file:line citations and the details that do not
// survive being drawn — what each one shows on hover, what it opens on click,
// which fields it drops when the bar turns vertical.
//
// Harness only. Nothing here ships.
//
//   quickshell -p docs/surveys/clock-survey.qml

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "file:///home/erikf/projects/personal/quickshell" as Shell

ShellRoot {
    PanelWindow {
        anchors { top: true; left: true }
        margins { left: 20; top: 40 }
        implicitWidth: 1560
        implicitHeight: 420
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "clock-survey"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        SystemClock { id: clock; precision: SystemClock.Seconds }

        Rectangle {
            anchors.fill: parent
            color: "#11141a"
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Text {
                    text: "Hours, minutes, day and month in a 58px vertical rail — thirteen real implementations, redrawn at true width"
                    color: "#d3c6aa"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "height is measured, not claimed: each mock is built to its source's own sizes and padding, then asked how tall it is"
                    color: "#859289"
                    font.pixelSize: 10
                }

                RowLayout {
                    spacing: 0
                    Layout.fillHeight: true

                    Repeater {
                        model: [
                            { n: "1. noctalia Clock",     k: "noct", d: "dd MM", t: "the ancestor of this shell's. one format string, HH mm - dd MM, split on spaces into five lines at one size, spacing -2." },
                            { n: "2. THIS, before",       k: "old",  d: "dd MM", t: "noctalia's, retuned: 15px time, 11px date dimmed, the dash promoted to a 16px hairline. 92px until the rail lost its rounded groups this session." },
                            { n: "3. end-4 ii",           k: "end4", d: "dd/MM", t: "17px HH/mm tucked -4 into one block, dd/MM at 10px under it. no rule — size alone carries the hierarchy." },
                            { n: "4. caelestia bar",      k: "cael", d: "ddd d", t: "icon, weekday, day, a hairline bleeding 4px past the column, then HH/mm pulled up 8. hour and minute width-matched on the wdth axis." },
                            { n: "5. DankMaterialShell",  k: "dms",  d: "dd MM", t: "every digit its own 7px cell so the columns align in any font. date drawn in the accent instead of dimmed." },
                            { n: "6. omarchy-quattro",    k: "omq",  d: "none",  t: "the format is literally HH\\n—\\nmm: the em dash is a line of text with a whole 27px slot to itself. date only if you cycle the format." },
                            { n: "7. iNiR vertical",      k: "inir", d: "dd MM", t: "colon-split HH/mm at zero spacing, a rule, then the date as a typographic fraction — dd and MM across a drawn diagonal." },
                            { n: "8. Whisker TimeLabel",  k: "whsk", d: "dd/MM", t: "lineHeight 0.1 on every line, so each Text reports a tenth of its own box and the three collapse into each other." },
                            { n: "9. bjarneo Bar",        k: "bjar", d: "none",  t: "HH anchored above verticalCenter and mm below it, 1px each — a 2px optical gap with no layout at all. no date anywhere." },
                            { n: "10. nucleus-shell",     k: "nuc",  d: "none",  t: "one Text, hh\\nmm\\nAP. the only project that really rotates: the whole row turns 90 and the clock turns 270 back." },
                            { n: "11. Keystone",          k: "keys", d: "dd MMM", t: "each digit a 24px window onto a drum of 0-9 that springs into place, each on its own tilt. a panel, not a rail widget." },
                            { n: "12. noctalia binary",   k: "bin",  d: "none",  t: "binary coded decimal, one dot column per digit. the most compact thing here and the least readable." },
                            { n: "13. THIS — RailClock",  k: "mine", d: "dd MMM", t: "time stacked, date turned into the margin it leaves free. the date costs no height at all, and the rule runs down instead of across." }
                        ]

                        ColumnLayout {
                            id: cell
                            required property var modelData
                            Layout.preferredWidth: 116
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 5

                            // the strip, at the real rail width
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 58
                                implicitHeight: 152
                                color: Shell.Theme.bg
                                radius: 4

                                Loader {
                                    id: shape
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 8
                                    sourceComponent: {
                                        switch (cell.modelData.k) {
                                        case "noct": return cNoct;
                                        case "old": return cOld;
                                        case "end4": return cEnd4;
                                        case "cael": return cCael;
                                        case "dms": return cDms;
                                        case "omq": return cOmq;
                                        case "inir": return cInir;
                                        case "whsk": return cWhisker;
                                        case "bjar": return cBjarneo;
                                        case "nuc": return cNuc;
                                        case "keys": return cKeys;
                                        case "bin": return cBin;
                                        default: return cMine;
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: Math.round(shape.height) + "px"
                                color: cell.modelData.k === "mine" ? "#9ece6a"
                                     : Math.round(shape.height) > 80 ? "#f7768e" : "#d3c6aa"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "date: " + cell.modelData.d
                                color: cell.modelData.d === "none" ? "#f7768e" : "#859289"
                                font.pixelSize: 9
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.modelData.n
                                color: cell.modelData.k === "mine" ? Shell.Theme.accent : "#d3c6aa"
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
                        }
                    }
                }
            }
        }

        // ---- mocks -------------------------------------------------------

        // A stack of centred lines, which is what nine of the thirteen are.
        component Line: Text {
            color: Shell.Theme.fg
            font.pixelSize: 15
            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        }

        component Rule: Rectangle {
            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
            width: 16
            height: 1
            color: Shell.Theme.line
        }

        // 1 noctalia — Modules/Bar/Widgets/Clock.qml:120,125. The vertical
        // format string "HH mm - dd MM" split on spaces into five lines at one
        // size, spacing -2, inside a capsule with margin2S of padding.
        Component {
            id: cNoct
            Item {
                implicitWidth: 58
                implicitHeight: col.implicitHeight + 8
                Column {
                    id: col
                    anchors.centerIn: parent
                    spacing: -2
                    Line { text: Qt.formatDateTime(clock.date, "HH") }
                    Line { text: Qt.formatDateTime(clock.date, "mm") }
                    Line { text: "-" }
                    Line { text: Qt.formatDateTime(clock.date, "dd") }
                    Line { text: Qt.formatDateTime(clock.date, "MM") }
                }
            }
        }

        // 2 this shell, before — shell.qml. noctalia's five lines with the dash
        // promoted to a 16px hairline and the date dropped to 11px and dimmed.
        // Measured bare: it sat on a rounded group worth another 12px until the
        // rail lost its groups, which is where the 92px in the brief comes from.
        Component {
            id: cOld
            Item {
                implicitWidth: 58
                implicitHeight: col.implicitHeight
                Column {
                    id: col
                    anchors.centerIn: parent
                    spacing: 0
                    Line {
                        text: Qt.formatDateTime(clock.date, "HH")
                        font.weight: Font.DemiBold
                    }
                    Line { text: Qt.formatDateTime(clock.date, "mm") }
                    Item { width: 1; height: 5 }
                    Rule {}
                    Item { width: 1; height: 4 }
                    Line {
                        text: Qt.formatDateTime(clock.date, "dd")
                        color: Shell.Theme.dim; font.pixelSize: 11
                    }
                    Line {
                        text: Qt.formatDateTime(clock.date, "MM")
                        color: Shell.Theme.dim; font.pixelSize: 11
                    }
                }
            }
        }

        // 3 end-4 ii — verticalBar/VerticalClockWidget.qml:27. The formatted
        // time is split on /[: ]/ so one delegate draws 24h and 12h alike, the
        // two lines are tucked -4 into one block, and dd/MM sits under it at
        // 10px in the same colour. BarGroup pads it 8 top and bottom.
        Component {
            id: cEnd4
            Item {
                implicitWidth: 58
                implicitHeight: col.implicitHeight + 16
                Column {
                    id: col
                    anchors.centerIn: parent
                    spacing: 0
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: -4
                        Line { text: Qt.formatDateTime(clock.date, "HH"); font.pixelSize: 17 }
                        Line { text: Qt.formatDateTime(clock.date, "mm"); font.pixelSize: 17 }
                    }
                    Line { text: Qt.formatDateTime(clock.date, "dd/MM"); font.pixelSize: 10 }
                }
            }
        }

        // 4 caelestia — modules/bar/components/Clock.qml. Calendar icon,
        // weekday, unpadded day, a 1px rule that bleeds 4px past the column each
        // side, then hour and minute pulled together by 8. Everything one
        // colour. Drawn with showDate on; off, which is the default, it is the
        // icon and the time alone and about 70px.
        Component {
            id: cCael
            Item {
                implicitWidth: 58
                implicitHeight: col.implicitHeight + 8
                Column {
                    id: col
                    anchors.centerIn: parent
                    spacing: 4
                    Line { text: "󰸗"; color: Shell.Theme.accent; font.pixelSize: 15 }
                    Line {
                        text: Qt.formatDateTime(clock.date, "ddd")
                        color: Shell.Theme.accent; font.pixelSize: 13
                    }
                    Line {
                        text: Qt.formatDateTime(clock.date, "d")
                        color: Shell.Theme.accent; font.pixelSize: 19
                    }
                    Rule { width: 34 }
                    Line {
                        text: Qt.formatDateTime(clock.date, "HH")
                        color: Shell.Theme.accent; font.pixelSize: 17
                    }
                    Line {
                        text: Qt.formatDateTime(clock.date, "mm")
                        color: Shell.Theme.accent; font.pixelSize: 17
                        topPadding: -8
                    }
                }
            }
        }

        // 5 DankMaterialShell — Modules/DankBar/Widgets/Clock.qml:24-197. Every
        // digit is its own Text in a cell of round(size * 0.6), so the columns
        // align whatever the font does. The rule is 60% of an already narrow
        // column, and the date is drawn in the accent rather than dimmed — the
        // inverse of everybody else. 12px digits, 12px of padding each end.
        Component {
            id: cDms
            Item {
                implicitWidth: 58
                implicitHeight: col.implicitHeight + 24

                component Digits: Row {
                    property string value: ""
                    property color tint: Shell.Theme.fg
                    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                    spacing: 0
                    Repeater {
                        model: value.split("")
                        Text {
                            required property string modelData
                            width: 7
                            text: modelData
                            color: tint
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Column {
                    id: col
                    anchors.centerIn: parent
                    spacing: 0
                    Digits { value: Qt.formatDateTime(clock.date, "HH") }
                    Digits { value: Qt.formatDateTime(clock.date, "mm") }
                    Item {
                        width: 1; height: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        Rule { anchors.centerIn: parent; width: 9 }
                    }
                    Digits { value: Qt.formatDateTime(clock.date, "dd"); tint: Shell.Theme.accent }
                    Digits { value: Qt.formatDateTime(clock.date, "MM"); tint: Shell.Theme.accent }
                }
            }
        }

        // 6 omarchy-quattro — plugins/panels/clock/BarWidget.qml:154, formats
        // in Model.js:20. The vertical format is the literal string "HH\n—\nmm":
        // the em dash is a line of text, not a rule, and it gets a whole 27px
        // icon slot to itself like every other line. Right-clicking cycles to a
        // date format instead, so you get the time or the date, never both.
        Component {
            id: cOmq
            Item {
                implicitWidth: 58
                implicitHeight: col.implicitHeight + 18
                Column {
                    id: col
                    anchors.centerIn: parent
                    component Slot: Item {
                        property alias text: t.text
                        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                        implicitWidth: 30
                        implicitHeight: 27
                        Text {
                            id: t
                            anchors.centerIn: parent
                            color: Shell.Theme.fg
                            font.pixelSize: 12
                        }
                    }
                    Slot { text: Qt.formatDateTime(clock.date, "HH") }
                    Slot { text: "—" }
                    Slot { text: Qt.formatDateTime(clock.date, "mm") }
                }
            }
        }

        // 7 iNiR — verticalBar/VerticalClockWidget.qml:18-28 over
        // verticalBar/VerticalDateWidget.qml:20-63, assembled by
        // VerticalBarContent.qml:265-300 with a rule and 12px between them.
        // The clock is a colon-split repeater at zero spacing; the date is the
        // best idea in the survey — dd top-left and MM bottom-right of a drawn
        // diagonal, a typographic fraction with no slash glyph in it.
        Component {
            id: cInir
            Item {
                implicitWidth: 58
                implicitHeight: col.implicitHeight + 16
                Column {
                    id: col
                    anchors.centerIn: parent
                    spacing: 12
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0
                        Line { text: Qt.formatDateTime(clock.date, "HH"); font.pixelSize: 17 }
                        Line { text: Qt.formatDateTime(clock.date, "mm"); font.pixelSize: 17 }
                    }
                    Rule { width: 19 }
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 24; height: 30
                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                const c = getContext("2d"); c.reset();
                                c.strokeStyle = Shell.Theme.dim;
                                c.lineWidth = 1.2;
                                c.beginPath();
                                c.moveTo(width - 4, 4);
                                c.lineTo(4, height - 4);
                                c.stroke();
                            }
                        }
                        Text {
                            anchors { top: parent.top; left: parent.left }
                            text: Qt.formatDateTime(clock.date, "dd")
                            color: Shell.Theme.fg; font.pixelSize: 13
                        }
                        Text {
                            anchors { bottom: parent.bottom; right: parent.right }
                            text: Qt.formatDateTime(clock.date, "MM")
                            color: Shell.Theme.fg; font.pixelSize: 13
                        }
                    }
                }
            }
        }

        // 8 Whisker — modules/bar/TimeLabel.qml:21-40. Three lines at 18px
        // ExtraBold, every one of them given lineHeight 0.1 so it reports a
        // tenth of its own box, then negative spacing on top of that. The
        // glyphs overflow their items and the block collapses to a fraction of
        // what three lines should cost. Time full strength, date dimmed.
        Component {
            id: cWhisker
            Item {
                implicitWidth: 58
                implicitHeight: col.implicitHeight
                Column {
                    id: col
                    anchors.centerIn: parent
                    spacing: -2
                    component Crushed: Text {
                        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                        color: Shell.Theme.fg
                        font.pixelSize: 18
                        font.weight: Font.ExtraBold
                        lineHeight: 0.1
                    }
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: -2
                        Crushed { text: Qt.formatDateTime(clock.date, "HH") }
                        Crushed { text: Qt.formatDateTime(clock.date, "mm") }
                    }
                    Crushed {
                        text: Qt.formatDateTime(clock.date, "dd/MM")
                        color: Shell.Theme.dim
                        font.pixelSize: 12
                        font.weight: Font.Normal
                    }
                }
            }
        }

        // 9 bjarneo — desktop/Bar.qml:147-202. No layout at all: HH is anchored
        // to the bottom of verticalCenter with a 1px margin and mm to the top
        // of it with another, so the two blocks meet on the axis with a 2px
        // optical gap. 11px Light mono, and the letterSpacing the horizontal
        // variant uses is dropped so the two columns stay flush. No date on the
        // bar at all — hovering says "Calendar", clicking opens one.
        Component {
            id: cBjarneo
            Item {
                implicitWidth: 58
                implicitHeight: hh.implicitHeight + mm.implicitHeight + 6
                Text {
                    id: hh
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: 1
                    text: Qt.formatDateTime(clock.date, "HH")
                    color: Shell.Theme.fg
                    font.pixelSize: 11
                    font.weight: Font.Light
                }
                Text {
                    id: mm
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.verticalCenter
                    anchors.topMargin: 1
                    text: Qt.formatDateTime(clock.date, "mm")
                    color: Shell.Theme.fg
                    font.pixelSize: 11
                    font.weight: Font.Light
                }
            }
        }

        // 10 nucleus-shell — bar/content/ClockModule.qml, placed by
        // BarContent.qml:144-177. One Text whose format is "hh\nmm\nAP", and
        // the only project on disk that really rotates: the whole row is turned
        // 90 so its children stack down the screen, and the clock is turned 270
        // back so it lands upright. No date in vertical mode, and at 16px plus a
        // hardcoded 40px of width it is the one design that does not fit 58px.
        Component {
            id: cNuc
            Item {
                implicitWidth: 58
                implicitHeight: t.implicitHeight
                Text {
                    id: t
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(clock.date, "hh") + "\n"
                        + Qt.formatDateTime(clock.date, "mm") + "\n"
                        + Qt.formatDateTime(clock.date, "AP")
                    color: Shell.Theme.fg
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // 11 Keystone — Modules/Keystone/ClockContent/ClockContent.qml:45-120.
        // Each digit is a 24px window onto a column of 0-9 that springs to the
        // right row, and each has its own tilt and vertical offset so the four
        // sit like loose type. Drawn stacked here to be comparable; in Keystone
        // it is a wide panel, which is the point — it was never a rail widget.
        Component {
            id: cKeys
            Item {
                implicitWidth: 58
                implicitHeight: col.implicitHeight + 20

                component Drum: Item {
                    property int value: 0
                    property real tilt: 0
                    property real drop: 0
                    width: 13
                    height: 24
                    clip: true
                    rotation: tilt
                    y: drop
                    Text {
                        text: "0\n1\n2\n3\n4\n5\n6\n7\n8\n9"
                        color: Shell.Theme.fg
                        font.pixelSize: 22
                        font.weight: Font.Black
                        lineHeight: 24
                        lineHeightMode: Text.FixedHeight
                        y: -parent.value * 24
                        Behavior on y { SpringAnimation { spring: 3.5; damping: 0.75 } }
                    }
                }

                Column {
                    id: col
                    anchors.centerIn: parent
                    spacing: 3
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: -1
                        Drum { value: clock.hours / 10 | 0; tilt: -3; drop: -2 }
                        Drum { value: clock.hours % 10; tilt: 2; drop: 1 }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: -1
                        Drum { value: clock.minutes / 10 | 0; tilt: 3; drop: 0 }
                        Drum { value: clock.minutes % 10; tilt: -2; drop: -1 }
                    }
                    Rule { width: 20 }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dd MMM")
                        color: Shell.Theme.accent
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
        }

        // 12 noctalia NClock, binary style — Widgets/NClock.qml:316-380. Binary
        // coded decimal: one column of dots per digit, lit bits reading up. The
        // most compact thing in the survey and the least readable in it.
        Component {
            id: cBin
            Item {
                implicitWidth: 58
                implicitHeight: bits.implicitHeight + 8

                component Bits: Column {
                    property int value: 0
                    property int bits: 4
                    spacing: 3
                    Repeater {
                        model: bits
                        Rectangle {
                            required property int index
                            width: 5; height: 5; radius: 2.5
                            color: (value >> (bits - 1 - index)) & 1
                                 ? Shell.Theme.accent : Shell.Theme.line
                        }
                    }
                }

                Row {
                    id: bits
                    anchors.centerIn: parent
                    spacing: 4
                    Bits { value: clock.hours / 10 | 0; bits: 2 }
                    Bits { value: clock.hours % 10; bits: 4 }
                    Bits { value: clock.minutes / 10 | 0; bits: 3 }
                    Bits { value: clock.minutes % 10; bits: 4 }
                }
            }
        }

        // 13 this shell, after — RailClock.qml. caelestia's tuck for the two
        // lines of time; the date turned into the margin they leave free, so it
        // costs no height at all; and the rule that used to separate them
        // running down instead of across, for the same reason.
        Component {
            id: cMine
            Item {
                implicitWidth: 58
                implicitHeight: c.implicitHeight
                Shell.RailClock { id: c; anchors.centerIn: parent }
            }
        }
    }
}
