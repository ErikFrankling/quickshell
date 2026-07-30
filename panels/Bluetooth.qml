import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

ColumnLayout {
    spacing: Theme.pad

    Text {
        text: "Bluetooth"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Entry {
        glyph: "󰂯"
        label: "Bluetooth"
        on: Bluetooth.defaultAdapter?.enabled ?? false
        value: (Bluetooth.defaultAdapter?.enabled ?? false) ? "on" : "off"
        onClicked: {
            if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
        }
    }

    Entry {
        glyph: "󰐷"
        label: "Scan for devices"
        on: Bluetooth.defaultAdapter?.discovering ?? false
        onClicked: {
            if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering;
        }
    }

    Text {
        text: "Devices"
        color: Theme.dim
        font.pixelSize: 11
        Layout.topMargin: 6
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        // A ListView reports no implicit height of its own, so the card it
        // sits in would size to nothing and slice the rows. Report the
        // content, and the card follows it up to its own screen clamp.
        implicitHeight: contentHeight
        spacing: 6
        clip: true
        model: Bluetooth.devices

        delegate: Entry {
            required property var modelData
            width: ListView.view.width
            glyph: modelData.connected ? "󰂱" : "󰂲"
            label: modelData.name || modelData.address
            on: modelData.connected
            value: modelData.connected ? "connected" : modelData.paired ? "paired" : ""
            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
        }
    }
}
