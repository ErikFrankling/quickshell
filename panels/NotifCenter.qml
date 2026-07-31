import ".."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: Theme.pad

    property bool showSaved: false

    // The one heading here was doing two jobs. Naming the panel is the job it
    // did not need — you opened it — but it was also the only thing saying
    // which of the two lists the ☆ button had left you looking at, and the
    // button cannot say that itself: its glyph is what the press will do, not
    // where you are. So the name goes and the count takes over the line, and
    // the count now names the list it is counting. That is a fact rather than
    // a label, it is a line the panel was spending anyway, and it tells you
    // more than "Saved" did — an empty saved list and an empty history read
    // differently now.
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: root.showSaved ? Notifs.saved.length + " saved"
                                 : Notifs.history.length + " in history"
            color: Theme.dim
            font.pixelSize: 12
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
            saved: Notifs.isSaved(modelData.key)
            savedList: root.showSaved
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
