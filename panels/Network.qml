import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

// What you are connected by, and the handful of numbers you open a network
// panel to read.
//
// The neighbours' wifi is the long part, and whether it starts open is decided
// by one question: is wifi the link you are actually on? On the laptop it is,
// the list is the reason you opened the panel, and making you press for it was
// a press for nothing. On the desktop wifi is a card that exists, is switched
// on, and carries nothing — ethernet does — and opening into a screen-height
// list of routers it will never join is not an answer to any question.
//
// So the test is `Net.wifi` — the default route leaves by the radio — and not
// `Networking.wifiEnabled`. Measured on the desktop: `nmcli radio` reports
// WIFI enabled there while `wlp11s0` is disconnected with no saved connection
// at all, so the radio switch would have opened the list on exactly the
// machine the collapse was written for.
ColumnLayout {
    id: root
    spacing: Theme.pad

    property bool wifiOpen: Net.wifi

    // Closing the flyout hides the card, and an item is not visible while an
    // ancestor is hidden — so this is the close hook. shell.qml never clears
    // `shown`, so the page is *not* destroyed when the flyout shuts; only a
    // switch to another page destroys it. Putting the section back to its
    // natural state here is what makes a press on it last for one visit and
    // not for the rest of the session.
    onVisibleChanged: if (!root.visible) root.wifiOpen = Net.wifi

    // Scanning is what made this panel full height on a desktop on ethernet,
    // and it costs power on the laptop too, so the radio only sweeps while the
    // list is open *and on screen*. Ricelin gates the same Binding the same way
    // (WifiSurface.qml:275); the `when` guard is for before the device
    // enumerates.
    //
    // `root.visible` is the half Ricelin does not need and this does. The list
    // now starts open on a wifi machine, so `wifiOpen` is true with the panel
    // shut — and without this the radio would sweep for as long as the shell
    // ran. That is the battery, on the machine that has one.
    Binding {
        target: Net.wifiDevice
        property: "scannerEnabled"
        value: root.visible && root.wifiOpen && Networking.wifiEnabled
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
        function onTunnelsChanged() { Net.refreshPublicIp(); }
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

    // The tunnels, one row each. They ride on the link above rather than
    // replacing it, so they are rows of their own and not a different first
    // row — and there is a row *each* because two are up on his laptop at
    // once, an OpenVPN and Cloudflare's WARP. The rail can only say that some
    // tunnel is up; this is where you find out which, and how many.
    Repeater {
        model: ScriptModel { values: Net.tunnels }

        Entry {
            required property var modelData
            glyph: "󰌆"
            label: modelData.name
            on: true
            value: modelData.ip
        }
    }

    // Everything wireless, and nothing at all on a machine with no radio in
    // it. `Net.hasWifi` is a wifi *card* in `Networking.devices`, which is a
    // different question from `Networking.wifiEnabled` — the switch. No card
    // and none of the next three items exist; a card with the switch off and
    // the row below says so and offers to flip it.
    Entry {
        visible: Net.hasWifi
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
        visible: Net.hasWifi && root.wifiOpen && !Networking.wifiEnabled
        glyph: "󰤨"
        label: "Turn Wi-Fi on"
        onClicked: Networking.wifiEnabled = true
    }

    ListView {
        visible: Net.hasWifi && root.wifiOpen && Networking.wifiEnabled
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
