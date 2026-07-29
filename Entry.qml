import QtQuick
import QtQuick.Layouts

// A tappable row inside a panel: icon, label, optional right-hand value.
Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property string value: ""
    property bool on: false

    signal clicked

    Layout.fillWidth: true
    implicitHeight: 44
    radius: Theme.radiusS
    color: root.on ? Qt.alpha(Theme.accent, 0.18) : ma.containsMouse ? Theme.bgHi : Theme.bgAlt

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
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
