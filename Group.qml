import QtQuick
import QtQuick.Layouts

// A cluster of rail items on its own rounded ground, so the bar reads as a few
// distinct groups with air between them rather than one continuous strip.
Rectangle {
    id: root

    default property alias content: col.data
    property int gap: 4

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: 46
    implicitHeight: col.implicitHeight + 12
    radius: 15
    color: Theme.bgHi

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: parent.width
        spacing: root.gap
    }
}
