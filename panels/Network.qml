import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

ColumnLayout {
    spacing: Theme.pad

    Text {
        text: "Network"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Entry {
        glyph: "󰤨"
        label: "Wi-Fi"
        on: Networking.wifiEnabled
        value: Networking.wifiEnabled ? "on" : "off"
        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    Text {
        text: "Available"
        color: Theme.dim
        font.pixelSize: 11
        Layout.topMargin: 6
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 6
        clip: true
        model: Networking.accessPoints

        delegate: Entry {
            required property var modelData
            width: ListView.view.width
            glyph: modelData.strength > 66 ? "󰤨" : modelData.strength > 33 ? "󰤥" : "󰤟"
            label: modelData.ssid
            on: modelData.active
            value: modelData.strength + "%"
            onClicked: modelData.connect()
        }
    }
}
