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

    Text {
        visible: !root.showSaved
        text: Notifs.history.length + " in history"
        color: Theme.dim
        font.pixelSize: 12
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        // See Bluetooth.qml. The card grows with the history until it hits
        // the screen, and past that the list keeps the overflow and scrolls.
        implicitHeight: contentHeight
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
