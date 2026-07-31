import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell

// The clock, as a time and a date side by side.
//
// It has been three things. Five lines and 92px — noctalia's vertical-bar clock
// split out of its `HH mm - dd MM` format string (noctalia Modules/Bar/Widgets/
// Clock.qml:120,125), the tallest single thing on a rail that overflows on a
// laptop. Then 36px, by turning `30 JUL` −90° into the margin a stacked time
// leaves free. Then 30px, by laying `HH:mm` across the rail on one line with
// the date under it, which is the shortest of the sixteen designs measured in
// docs/surveys/clock-compact.md.
//
// 30px was too short in the one direction nobody had a number for. `HH:mm` at
// 15px is 45px of glyph and the ground a rail group draws is Theme.groupWidth,
// 46 — half a pixel of air either side. Erik read that as the clock almost
// overflowing, and he is right: the shortest design on the sheet was also the
// widest thing on the rail bar the workspaces.
//
// So this is the survey's runner-up, iNiR's (verticalBar/VerticalClockWidget
// .qml:18-28 over verticalBar/VerticalDateWidget.qml:20-63, assembled by
// VerticalBarContent.qml:265-300). Two ideas, and they pay for each other:
//
//   - The time stacks. `HH` over `mm`, tucked, is 18px wide instead of 45 and
//     costs one extra line — 36px tall, the same as the turned-date design it
//     replaces, in 42px of the 46px ground instead of 45.
//   - The date is a typographic fraction. `dd` sits top-left and `MM`
//     bottom-right of a drawn diagonal, with no slash glyph anywhere: the rule
//     *is* the separator. clock-survey.md calls it the best single idea in the
//     survey, and it goes in the 21px of width the stacked time just freed.
//
// That width is the whole reason it works here. The fraction was tried once
// before, shrunk to sit beside a one-line `HH:mm`, and at the ~9px that margin
// allowed the diagonal and the digits collided into mush (clock-survey.md:140).
// Beside a stacked time it gets 21x30 and 12px digits against iNiR's own 24x30
// and 13px — a 29.4px diagonal where iNiR draws 27.2. It is the same drawing at
// nine-tenths the width, not a miniature of it: rendered and counted, each pair
// of date digits puts down 9px of ink with 3px of ground between them.
//
// The cost is that the date is two numbers again. The one-line version wrote
// `30 JUL` on purpose — two numbers one above the other can be read in either
// order, and `30` over `07` is a date in one country and nonsense in the next.
// The diagonal is what buys that back: a fraction has a top and a bottom, so
// day-above-month is a reading direction and not a convention you have to know.
// It is thinner ice than three letters were. If it ever reads wrong, the answer
// is `MMM` in the bottom slot, which fits — 12px `JUL` is 22px against the 21px
// the box is drawn at — and not a return to one line.
//
// It is also the control centre's button. There was an arrow one group above it
// whose whole job was to be pressable, sitting over a clock that is already the
// largest press target on the rail and was spending it on a month grid nobody
// wanted. Windows puts the notifications behind the clock, GNOME puts the whole
// shell menu behind it, and Plasma's digital clock opens its calendar-and-
// notifications applet; a clock is the one thing on a bar everybody already
// aims at.
Item {
    id: root

    // Whether the control centre is the page showing, like every Btn on the
    // rail.
    property bool active: false

    // Unread notifications. It reads on the date rather than as a dot in a
    // corner, because a dot on a rail button is what Erik had just finished
    // reading as "there is a notification here" on a button where there could
    // not be one. On this button there can be, and the cue is the date going
    // from dim to the accent.
    property int badge: 0

    signal activated

    // The date's one colour, in one place: the digits and nothing else move,
    // so the diagonal stays the hairline it is and the tint stays a message.
    //
    // All three still read on the wash the ground takes while the panel is open.
    // Theme.fg is 7.79 on his Gruvbox, 4.52 on Everforest, 8.35 on Tokyo Night
    // and 4.44 on Gruvbox Light, against 9.57 / 5.57 / 10.34 / 5.14 unwashed.
    // The accent is the one to watch, because it is being drawn on a 12% wash of
    // itself: 4.31, 3.82, 4.67 and 3.32, against 5.29 / 4.70 / 5.78 / 3.85. It
    // stays the loudest of the three on every scheme, which is what the unread
    // count needs of it, and it never approaches the 1.3:1 that the solid accent
    // fill this replaces would have put it at.
    readonly property color dateFg: root.badge > 0 ? Theme.accent
        : root.active ? Theme.fg : Theme.dim

    Layout.alignment: Qt.AlignHCenter
    // 3px between the two, which is what keeps the whole thing to 42px on a
    // 46px ground. The height is the time's; the fraction is shorter and rides
    // in the middle of it.
    implicitWidth: time.implicitWidth + 3 + frac.width
    implicitHeight: Math.max(time.implicitHeight, frac.height)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // The ground that says the control centre is up, the same one every other
    // rail control that opens a panel now draws. Sized from the Group this
    // stands in rather than from the clock: the clock is 42px of digits in a
    // 46px ground with Theme.groupPad above and below, so 2px inside the first
    // and half of the second keeps the hairline clear of the group's own edge.
    // It is anchored rather than laid out, so the implicitHeight above is still
    // the time's and the rail's height budget has not moved.
    OpenGround {
        anchors.centerIn: parent
        width: Theme.groupWidth - 4
        height: parent.height + Theme.groupPad
        on: root.active
    }

    Column {
        id: time
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        // iNiR stacks its two halves at spacing 0, which at 17px leaves 10px of
        // empty leading between them and reads as two numbers rather than one
        // time. Digits have no descenders, so all of that is air: −4 closes it
        // to a 4px gap, the tuck caelestia spends between its own hour and
        // minute (modules/bar/components/Clock.qml:96).
        spacing: -4

        component Half: Text {
            color: Theme.fg
            font.pixelSize: 15
            font.weight: Font.DemiBold
            // Tabular figures matter more in a fixed-width slot than anywhere
            // else: proportional digits make a centred clock shuffle sideways
            // every minute. noctalia sets this on both its bar clocks for the
            // same reason (Modules/Bar/Widgets/Clock.qml:108,135).
            font.features: ({ tnum: 1 })
        }

        Half { text: Qt.formatDateTime(clock.date, "HH") }
        Half { text: Qt.formatDateTime(clock.date, "mm") }
    }

    // The fraction. 21 wide is iNiR's 24 scaled to the room the stacked time
    // leaves, and the digits are 12px against its 13; the height is iNiR's own
    // 30, because the box is shorter than the time beside it either way and the
    // two spare pixels are the gap between the two numbers. Everything inside
    // is placed from the box's corners, so they are held apart by the box and
    // not by a layout.
    Item {
        id: frac
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 21
        height: 30

        // Inset 2px at the ends so the rule stops short of the corners rather
        // than pointing out of the box. It passes within a pixel of the corner
        // of each pair of digits — that near miss is what makes two numbers a
        // fraction, and it is why the box cannot shrink much further.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: Theme.dim
                strokeWidth: 1.2
                fillColor: Qt.alpha(Theme.dim, 0)
                startX: frac.width - 2
                startY: 3
                PathLine { x: 2; y: frac.height - 3 }
            }
        }

        component Num: Text {
            color: root.dateFg
            font.pixelSize: 12
            font.features: ({ tnum: 1 })

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Num {
            anchors { top: parent.top; left: parent.left }
            text: Qt.formatDateTime(clock.date, "dd")
        }

        Num {
            anchors { bottom: parent.bottom; right: parent.right }
            text: Qt.formatDateTime(clock.date, "MM")
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
