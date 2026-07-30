import QtQuick
import QtQuick.Layouts

// A tappable row inside a panel. Same hover discipline as Btn.
Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property string value: ""
    property bool on: false
    property bool hovering: false

    signal clicked

    Layout.fillWidth: true
    implicitHeight: 44
    radius: Theme.radiusS
    color: root.on ? Qt.alpha(Theme.accent, 0.18) : root.hovering ? Theme.bgHi : Theme.bgAlt

    Behavior on color { ColorAnimation { duration: 110 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 13
        anchors.rightMargin: 13
        spacing: 11

        Text {
            text: root.glyph
            color: root.on ? Theme.accent : Theme.dim
            font.pixelSize: 14
        }
        Text {
            text: root.label
            color: Theme.fg
            font.pixelSize: 13
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        Text {
            text: root.value
            color: Theme.dim
            font.pixelSize: 12
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovering = true
        onExited: root.hovering = false
        onClicked: root.clicked()
    }
}
