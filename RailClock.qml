import QtQuick
import QtQuick.Layouts
import Quickshell

// The clock, as a stamp rather than a stack.
//
// It used to be four numbers in a column — 17 / 20 / rule / 30 / 07 — which is
// noctalia's vertical-bar clock, split out of its `HH mm - dd MM` format string
// (noctalia Modules/Bar/Widgets/Clock.qml:120,125). Five lines cost 80px bare
// and 92px on the rounded ground the rail used to give it: the tallest single
// thing on a rail that already overflows on a laptop.
//
// The date does not need lines of its own. Turned on its side it stands in the
// margin a two-digit time leaves free, so it costs the rail no height at all
// and the clock is only as tall as the time. Thirteen shells were measured for
// this (docs/surveys/clock-survey.md) and not one of them turns a clock — the
// only one under 58px that shows a date at all does it by making every line
// lie about its own height. So this is not a copied idiom. It is the move this
// shell already makes on a media title in RailPlayer, made again.
//
// The hairline between them runs vertically for the same reason: across, a
// rule is ten pixels of nothing; down, it is free.
Item {
    id: root

    // Whether the calendar page is the one showing, like every Btn on the rail.
    property bool active: false

    signal activated

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: row
        spacing: 5

        Column {
            anchors.verticalCenter: parent.verticalCenter
            // The two lines are pulled together so they read as one block of
            // digits rather than two labels. caelestia does exactly this, with
            // `Layout.topMargin: -parent.spacing - 4` between its hour and its
            // minute (caelestia-shell/modules/bar/components/Clock.qml:96).
            spacing: -4

            Text {
                text: Qt.formatDateTime(clock.date, "HH")
                color: Theme.fg
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            Text {
                text: Qt.formatDateTime(clock.date, "mm")
                color: Theme.fg
                font.pixelSize: 15
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            // As long as the date it separates. Not `parent.height`: a Row
            // sizes to its children, so a child sized from the Row is a loop.
            height: Math.ceil(metrics.advanceWidth)
            color: root.active ? Theme.accent : Theme.line
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        // Measured unconstrained and read back as the slot's length, the way
        // RailPlayer sizes its turned title. advanceWidth, not width: width is
        // rounded down, and a turned label given its own rounded-down length
        // elides the glyph that did not fit.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: date.implicitHeight
            implicitHeight: Math.ceil(metrics.advanceWidth)

            TextMetrics {
                id: metrics
                font: date.font
                text: date.text
            }

            Text {
                id: date
                anchors.centerIn: parent
                rotation: -90
                // Day, then the month in letters. Two numbers one above the
                // other can be read in either order — 30 and 07 is a date in
                // one country and nonsense in the next — and three letters
                // cost the same room as two digits.
                text: Qt.formatDateTime(clock.date, "dd MMM").toUpperCase()
                color: root.active ? Theme.fg : Theme.dim
                font.pixelSize: 9
                font.letterSpacing: 0.5
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
