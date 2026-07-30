import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

ColumnLayout {
    id: root
    spacing: Theme.pad

    // There is no global list of access points: they hang off the wifi
    // device, and it scans for none of them until asked. The Binding turns
    // the scanner on while this page exists and off again when it closes.
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: true
    }

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
        // See Bluetooth.qml: a ListView has no implicit height, so the card
        // needs to be told the content height to size to it.
        implicitHeight: contentHeight
        spacing: 6
        clip: true
        model: ScriptModel {
            values: [...(root.wifi?.networks.values ?? [])]
                .filter(n => n.name)
                .sort((a, b) => b.signalStrength - a.signalStrength)
        }

        delegate: Entry {
            required property var modelData
            width: ListView.view.width
            glyph: modelData.signalStrength > 0.66 ? "󰤨"
                 : modelData.signalStrength > 0.33 ? "󰤥" : "󰤟"
            label: modelData.name
            on: modelData.connected
            value: Math.round(modelData.signalStrength * 100) + "%"
            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
        }
    }
}
