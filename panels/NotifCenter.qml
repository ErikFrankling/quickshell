import ".."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: Theme.pad

    property bool showSaved: false

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: root.showSaved ? "Saved" : "Notifications"
            color: Theme.fg
            font.pixelSize: 18
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }
        Btn {
            glyph: root.showSaved ? "☰" : "☆"
            onClicked: root.showSaved = !root.showSaved
        }
        Btn {
            glyph: "✕"
            onClicked: root.showSaved ? null : Notifs.clearHistory()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: !root.showSaved
        Text {
            text: Notifs.dnd ? "Do not disturb is on" : Notifs.history.length + " in history"
            color: Theme.dim
            font.pixelSize: 12
            Layout.fillWidth: true
        }
        Row {
            id: dndRow
            Rectangle {
                width: 38; height: 21; radius: 11
                color: Notifs.dnd ? Theme.accent : Theme.bgHi
                Rectangle {
                    x: Notifs.dnd ? parent.width - width - 3 : 3
                    y: 3
                    width: 15; height: 15; radius: 8
                    color: Notifs.dnd ? Theme.bg : Theme.dim
                    Behavior on x { NumberAnimation { duration: 130 } }
                }
                MouseArea { anchors.fill: parent; onClicked: Notifs.dnd = !Notifs.dnd }
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 9
        clip: true
        model: root.showSaved ? Notifs.saved : Notifs.history

        delegate: NotifCard {
            required property var modelData
            width: ListView.view.width
            n: modelData
            saved: root.showSaved
        }
    }

    Text {
        visible: (root.showSaved ? Notifs.saved : Notifs.history).length === 0
        text: root.showSaved ? "Nothing saved yet" : "Nothing here"
        color: Theme.dim
        font.pixelSize: 13
        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.topMargin: 40
    }
}
