import QtQuick
import QtQuick.Layouts
import Quickshell

// The clock, across the rail rather than down it.
//
// It was four numbers in a column — 17 / 20 / rule / 30 / 07 — which is
// noctalia's vertical-bar clock split out of its `HH mm - dd MM` format string
// (noctalia Modules/Bar/Widgets/Clock.qml:120,125). Five lines cost 92px on the
// ground the rail gives it: the tallest single thing on a rail that overflows on
// a laptop. Turning the date on its side got that to 36px.
//
// This is 30px, and it gets there by turning the *time* back. The rail is 58px
// wide and this shell's font resolves to JetBrains Mono at about 0.6em per
// glyph, so `HH:mm` is five characters in 45px with a third of the rail still
// spare. A whole time fits across the rail at the rail's own type size, and it
// costs one line instead of two.
//
// The sheet's own recommendation was 15px over a 9px date, which measures 28.
// This keeps the 15px time and takes the date up to 10px, which measures 30:
// the date is the part worth reading, and at 9px it is a smudge from a normal
// sitting distance. The sheet's larger option, design 2, is 16px over 10px and
// measures 34 — but the interesting number is its width. 16px digits make
// `HH:mm` 48px, and the ground a rail group draws is Theme.groupWidth, 46. The
// bigger time does not fit the ground it would sit on, and widening every group
// on the rail to suit the clock is the tail wagging the dog. So the extra size
// goes where it was wanted anyway. Every figure here was measured off the live
// rail rather than calculated, which is the whole point of the survey that
// produced them.
//
// Sixteen designs were rendered and measured for this (docs/surveys/
// clock-compact.md). The finding that matters is that the 36px was never the
// cost of the stacked time — it was the cost of the turned date. `30 JUL` is six
// glyphs at 9px, which is 36px of column whichever way the time beside it is
// laid out, so laying the time down underneath it bought nothing. Rotating the
// reading direction is a loss in every variant measured: the whole time turned
// is 48px, time and date on one turned line is 124px, worse than the five-line
// stack this started from. Five glyphs of 15px monospace is 45px of rail
// whichever axis you spend it on.
//
// So this is the only design on the sheet that gets shorter while getting
// easier to read. `HH:mm` on one line is a time; `HH` over `mm` is two numbers
// you assemble into one, and nothing else on the rail asks to be read that way.
Item {
    id: root

    // Whether the calendar page is the one showing, like every Btn on the rail.
    property bool active: false

    signal activated

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: col
        // Digits have no descenders, so the pixels a 15px line reserves below
        // its baseline are empty and the date moves up into space nothing was
        // using. It is caelestia's tuck (modules/bar/components/Clock.qml:96)
        // spent on the gap between time and date rather than between hour and
        // minute.
        spacing: -4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.fg
            font.pixelSize: 15
            font.weight: Font.DemiBold
            // Tabular figures matter more in a fixed-width slot than anywhere
            // else: proportional digits make a centred clock shuffle sideways
            // every minute. noctalia sets this on both its bar clocks for the
            // same reason (Modules/Bar/Widgets/Clock.qml:108,135).
            font.features: ({ tnum: 1 })
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            // Day, then the month in letters. Two numbers one above the other
            // can be read in either order — 30 and 07 is a date in one country
            // and nonsense in the next — and three letters cost the same room
            // as two digits.
            text: Qt.formatDateTime(clock.date, "dd MMM").toUpperCase()
            color: root.active ? Theme.fg : Theme.dim
            font.pixelSize: 10
            font.letterSpacing: 0.5
            font.features: ({ tnum: 1 })

            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
