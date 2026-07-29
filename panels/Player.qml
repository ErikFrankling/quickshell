import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

ColumnLayout {
    id: root
    spacing: Theme.pad

    readonly property var p: Mpris.players.values.find(x => x.isPlaying) ?? Mpris.players.values[0] ?? null

    Text {
        text: "Playing"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: art.implicitHeight + 26
        radius: Theme.radiusS + 2
        color: Theme.bgAlt
        visible: root.p !== null

        ColumnLayout {
            id: art
            anchors.fill: parent
            anchors.margins: 13
            spacing: 10

            RowLayout {
                spacing: 12
                Image {
                    source: root.p?.trackArtUrl ?? ""
                    visible: source != ""
                    sourceSize.width: 64
                    sourceSize.height: 64
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: root.p?.trackTitle ?? ""
                        color: Theme.fg
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.p?.trackArtist ?? ""
                        color: Theme.dim
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.p?.identity ?? ""
                        color: Theme.dim
                        opacity: 0.7
                        font.pixelSize: 11
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Btn { glyph: "󰒮"; onClicked: root.p?.previous() }
                Btn {
                    glyph: root.p?.isPlaying ? "󰏤" : "󰐊"
                    active: root.p?.isPlaying ?? false
                    onClicked: root.p?.togglePlaying()
                }
                Btn { glyph: "󰒭"; onClicked: root.p?.next() }
            }
        }
    }

    Text {
        visible: root.p === null
        text: "Nothing playing"
        color: Theme.dim
        font.pixelSize: 13
    }

    Item { Layout.fillHeight: true }
}
