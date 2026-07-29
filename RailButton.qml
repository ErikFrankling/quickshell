import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string text: ""
    property bool active: false
    property int badge: 0

    signal clicked

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: 34
    implicitHeight: 34
    Layout.topMargin: 9

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.active ? Theme.accent : "transparent"

        Text {
            anchors.centerIn: parent
            text: root.text
            color: root.active ? Theme.bg : Theme.dim
            font.pixelSize: 15
        }
    }

    Rectangle {
        visible: root.badge > 0 && !root.active
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 3
        width: 7
        height: 7
        radius: 4
        color: Theme.accent
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
