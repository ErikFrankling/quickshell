import QtQuick
import QtQuick.Layouts

// One metric in the rail: a label over a number. Nothing configurable.
ColumnLayout {
    id: root

    required property string label
    required property int value
    property int warnAt: 90

    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 7
    spacing: -2

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.label
        color: Theme.dim
        font.pixelSize: 9
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.value
        color: root.value >= root.warnAt ? Theme.warn : Theme.fg
        font.pixelSize: 14
    }
}
