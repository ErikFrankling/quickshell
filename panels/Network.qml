import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

// What you are connected by, and the handful of numbers you open a network
// panel to read. The neighbours' wifi is behind a row you have to press: this
// machine reaches the internet by cable, and a screen-height list of routers it
// will never join is not an answer to any question.
ColumnLayout {
    id: root
    spacing: Theme.pad

    property bool wifiOpen: false

    // Closing the flyout hides the card, and an item is not visible while an
    // ancestor is hidden — so this is the close hook. shell.qml never clears
    // `shown`, so the page is *not* destroyed when the flyout shuts; only a
    // switch to another page destroys it. Folding the section away here also
    // means the panel always opens at its small size.
    onVisibleChanged: if (!root.visible) root.wifiOpen = false

    // Scanning is what made this panel full height on a desktop on ethernet,
    // and it costs power on the laptop too, so the radio only sweeps while the
    // list is open. Ricelin gates the same Binding the same way
    // (WifiSurface.qml:275); the `when` guard is for before the device
    // enumerates.
    Binding {
        target: Net.wifiDevice
        property: "scannerEnabled"
        value: root.wifiOpen && Networking.wifiEnabled
        when: Net.wifiDevice !== null
        // The default restore mode puts the *old* value back when this Binding
        // dies, and the old value is whatever the scanner was when the page
        // opened. Measured: the hook below set false and the dying Binding set
        // true again straight after, and the radio kept sweeping.
        restoreMode: Binding.RestoreNone
    }

    // Switching to another page destroys this one with the Binding still on.
    Component.onDestruction: if (Net.wifiDevice) Net.wifiDevice.scannerEnabled = false

    // The public address is asked for when the panel appears, never on a timer.
    // Net clears it the moment the route or the tunnel moves, so asking again
    // on those two signals is asking again exactly when the answer can differ.
    Component.onCompleted: Net.refreshPublicIp()
    Connections {
        target: Net
        function onLinkChanged() { Net.refreshPublicIp(); }
        function onVpnLinkChanged() { Net.refreshPublicIp(); }
    }

    // Interface, LAN address and gateway because they are the three you read off
    // a router or type into another machine; DNS because it is the third thing
    // you check when the internet is "down"; the public address because it is
    // the only one the machine cannot work out for itself, and the only one
    // that says whether the tunnel is carrying anything. The MAC, the netmask
    // spelled out, IPv6 and throughput are all deliberately absent — the first
    // two never change, the third triples the width for the same fact, and the
    // last already has graphs of its own in the system panel.
    readonly property var facts: [
        { k: "Interface", v: Net.link },
        { k: "LAN address", v: Net.lanIp },
        { k: "Gateway", v: Net.gateway },
        { k: "DNS", v: Net.dns },
        { k: "Public address", v: !Net.online ? "" : Net.publicIp || "…" }
    ].filter(f => f.v)

    Text {
        text: "Network"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    // The link carrying the default route, named by what it is.
    Entry {
        glyph: Net.glyph
        label: !Net.online ? "Not connected"
            : Net.wired ? "Connected by ethernet"
            : Net.wifi ? (Net.wifiNetwork?.name ?? "Connected by Wi-Fi")
            : "Connected through " + Net.link
        on: Net.online
        value: Net.rate
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 5

        Repeater {
            model: ScriptModel { values: root.facts }

            RowLayout {
                id: fact
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.pad

                Text {
                    text: fact.modelData.k
                    color: Theme.dim
                    font.pixelSize: 11
                    Layout.preferredWidth: 96
                }
                Text {
                    text: fact.modelData.v
                    color: Theme.fg
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
    }

    // The tunnel, when there is one. It rides on the link above rather than
    // replacing it, so it is a row of its own and not a different first row.
    Entry {
        visible: Net.vpn
        glyph: "󰦝"
        label: Net.vpnLink
        on: true
        value: Net.vpnIp
    }

    // Everything wireless, behind one press, and absent altogether on a machine
    // with no radio in it.
    Entry {
        visible: Net.wifiDevice !== null
        glyph: Networking.wifiEnabled ? "󰤨" : "󰤮"
        label: "Wi-Fi"
        on: root.wifiOpen
        value: !Networking.wifiEnabled ? "off"
            : root.wifiOpen ? "scanning" : Net.wifi ? "connected" : "on"
        onClicked: root.wifiOpen = !root.wifiOpen
    }

    // The radio itself, only where turning it on is the thing standing between
    // you and the list you just asked for.
    Entry {
        visible: root.wifiOpen && !Networking.wifiEnabled
        glyph: "󰤨"
        label: "Turn Wi-Fi on"
        onClicked: Networking.wifiEnabled = true
    }

    ListView {
        visible: root.wifiOpen && Networking.wifiEnabled
        Layout.fillWidth: true
        // See Bluetooth.qml: a ListView reports no implicit height, so the card
        // has to be told the content height to size to it.
        implicitHeight: visible ? contentHeight : 0
        spacing: 6
        clip: true
        model: ScriptModel {
            values: [...(Net.wifiDevice?.networks.values ?? [])]
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
