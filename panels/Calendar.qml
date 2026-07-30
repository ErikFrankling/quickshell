import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell

// A month, and nothing else.
//
// There is no calendar integration here and there is not going to be — no
// account is signed in, so a list of events would be a list of nothing. What a
// grid of bare numbers still answers is the question the rail deliberately
// stopped asking: which weekday a date falls on, and how far off it is. Every
// shell surveyed that opens something from its clock opens exactly this and
// then pads it out — noctalia stacks a header card, a month card and a weather
// card in one panel (noct4/Modules/Panels/Clock/ClockPanel.qml:31). The month
// card is the part that earns its space.
ColumnLayout {
    id: root
    spacing: Theme.pad

    // The clock only has to be right to the day, so it wakes once an hour.
    SystemClock { id: clock; precision: SystemClock.Hours }

    // Months either side of this one. Reset every time the page is opened,
    // because the page is destroyed when it closes.
    property int offset: 0

    readonly property date today: clock.date
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)

    // Six weeks from the Monday on or before the first — the widest a month can
    // ever spread, so the grid never changes height as you page through it.
    readonly property var cells: {
        const first = root.shown;
        const back = (first.getDay() + 6) % 7;
        return Array.from({ length: 42 }, (_, i) =>
            new Date(first.getFullYear(), first.getMonth(), 1 - back + i));
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Also the way back: paged off this month, clicking the name returns.
        Text {
            Layout.fillWidth: true
            text: Qt.formatDateTime(root.shown, "MMMM yyyy")
            color: Theme.fg
            font.pixelSize: 18
            font.weight: Font.DemiBold

            MouseArea {
                anchors.fill: parent
                enabled: root.offset !== 0
                cursorShape: Qt.PointingHandCursor
                onClicked: root.offset = 0
            }
        }

        component Step: Text {
            required property int by
            color: ma.containsMouse ? Theme.fg : Theme.dim
            font.pixelSize: 16
            MouseArea {
                id: ma
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.offset += parent.by
            }
        }

        Step { text: "󰅁"; by: -1 }
        Step { text: "󰅂"; by: 1 }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 0

        Repeater {
            model: ["mo", "tu", "we", "th", "fr", "sa", "su"]
            Text {
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                color: Theme.dim
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Repeater {
            model: root.cells

            Item {
                required property date modelData
                readonly property bool here: modelData.getMonth() === root.shown.getMonth()
                readonly property bool now: root.sameDay(modelData, root.today)

                Layout.fillWidth: true
                implicitHeight: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: Theme.radiusS
                    color: parent.now ? Theme.accent : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData.getDate()
                    color: parent.now ? Theme.bg : parent.here ? Theme.fg : Theme.line
                    font.pixelSize: 12
                    font.weight: parent.now ? Font.DemiBold : Font.Normal
                }
            }
        }
    }
}
