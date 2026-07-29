import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

// The attached panel. Same fill as the rail, separated by a hairline, so the
// two read as one carved surface rather than a popup floating next to a bar.
ColumnLayout {
    id: root

    required property string page

    spacing: Theme.pad

    // Without this the sink is untracked and its volume reads as 0.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Text {
        text: root.page === "notifications" ? "Notifications" : "Controls"
        color: Theme.fg
        font.pixelSize: 17
        font.weight: Font.DemiBold
        Layout.bottomMargin: 2
    }

    // ---- controls ----------------------------------------------------------

    GridLayout {
        visible: root.page === "controls"
        columns: 2
        columnSpacing: Theme.pad
        rowSpacing: Theme.pad
        Layout.fillWidth: true

        Repeater {
            model: ["Wi-Fi", "Bluetooth", "Do not disturb", "Night light"]

            Rectangle {
                required property string modelData
                required property int index
                property bool on: index < 2

                Layout.fillWidth: true
                implicitHeight: 58
                radius: 10
                color: on ? Theme.accent : Theme.bgAlt

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: parent.on ? Theme.bg : Theme.dim
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.on = !parent.on
                }
            }
        }
    }

    Slider {
        visible: root.page === "controls"
        label: "Volume"
        value: Pipewire.defaultAudioSink?.audio?.volume ?? 0
        onMoved: v => {
            if (Pipewire.defaultAudioSink?.audio)
                Pipewire.defaultAudioSink.audio.volume = v;
        }
    }

    // ---- notifications -----------------------------------------------------

    ListView {
        visible: root.page === "notifications"
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8
        clip: true
        model: Notifs.list

        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            implicitHeight: body.implicitHeight + 22
            radius: 10
            color: Theme.bgAlt

            ColumnLayout {
                id: body
                anchors.fill: parent
                anchors.margins: 11
                spacing: 2

                RowLayout {
                    Text {
                        text: parent.parent.parent.modelData.app
                        color: Theme.dim
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                    Text {
                        text: parent.parent.parent.modelData.time
                        color: Theme.dim
                        font.pixelSize: 11
                    }
                }
                Text {
                    text: body.parent.modelData.summary
                    color: Theme.fg
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: body.parent.modelData.body
                    visible: text !== ""
                    color: Theme.fg
                    opacity: 0.8
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    Text {
        visible: root.page === "notifications" && Notifs.count === 0
        text: "Nothing here"
        color: Theme.dim
        font.pixelSize: 13
        Layout.fillHeight: true
    }

    Item {
        visible: root.page === "controls"
        Layout.fillHeight: true
    }
}
