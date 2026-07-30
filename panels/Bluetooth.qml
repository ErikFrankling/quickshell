import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: Theme.pad

    readonly property BluetoothAdapter bt: Bluetooth.defaultAdapter

    // Set while a power-up is in flight. `rfkill unblock` returns before BlueZ
    // has noticed the radio came back, and enabling inside that window is
    // refused outright — "Cannot enable adapter because it is blocked by
    // rfkill" in the log and a dead row on screen. The write is retried from
    // onStateChanged instead, once the adapter has left Blocked.
    property bool powerWhenUnblocked: false

    // Set when Scan is pressed while the radio is off, and spent once the
    // adapter is properly up. See tryScan.
    property bool scanWhenReady: false

    // Discovery belongs to the adapter, not to this panel, so it outlives the
    // flyout unless someone stops it — a radio scanning all afternoon because
    // a panel was opened once. The Loader in shell.qml destroys the panel when
    // the flyout closes, so this is the close hook.
    Component.onDestruction: if (root.bt?.discovering) root.bt.discovering = false

    // Turning Bluetooth on is a write to BlueZ's Powered property, and while
    // rfkill has the radio soft-blocked Quickshell refuses to even make it.
    // That is the state everything else that turns Bluetooth off leaves
    // behind — blueman's toggle, airplane mode, `rfkill block` — so the row
    // was dead with the reason in a log nobody reads. Clear the block first.
    //
    // The unblock needs no privilege: /dev/rfkill carries an ACL for the seat
    // user. Everything after it is Quickshell's own BlueZ service, which is
    // what the other shells use too — noctalia sets adapter.enabled directly
    // (Services/Networking/BluetoothService.qml:156) and Ricelin the same
    // (pill/BtSurface.qml:252). Neither shells out for power.
    Process {
        id: unblock
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: root.tryEnable()
    }

    function powerOn(): void {
        root.powerWhenUnblocked = true;
        powerGiveUp.restart();
        unblock.running = true;
    }

    // Retried on every state change until the adapter is out of Blocked, so an
    // unblock that BlueZ takes a moment to register still ends in a power-up
    // rather than one refused write and a button that did nothing.
    function tryEnable(): void {
        if (!root.powerWhenUnblocked || !root.bt)
            return;
        if (root.bt.state === BluetoothAdapterState.Blocked)
            return;
        root.powerWhenUnblocked = false;
        powerGiveUp.stop();
        root.bt.enabled = true;
    }

    // `enabled` reads back true the instant the write is made, while the
    // adapter is still only Enabling and BlueZ will still answer StartDiscovery
    // with "Resource Not Ready" — which is exactly how the old panel managed to
    // start a scan that never happened. Enabled is the state that means it, so
    // a Scan held over a power-up is replayed from here rather than from
    // enabledChanged, which fires a good deal too early.
    function tryScan(): void {
        if (!root.scanWhenReady || root.bt?.state !== BluetoothAdapterState.Enabled)
            return;
        root.scanWhenReady = false;
        scanGiveUp.stop();
        root.bt.discovering = true;
    }

    Connections {
        target: root.bt

        function onStateChanged(): void {
            root.tryEnable();
            root.tryScan();
        }
    }

    // A hard block is the one thing none of this can clear, so both pending
    // intents give up rather than firing into the next time Bluetooth is
    // switched on by hand. The rows go on saying "blocked" throughout.
    Timer {
        id: powerGiveUp
        interval: 8000
        onTriggered: root.powerWhenUnblocked = false
    }

    Timer {
        id: scanGiveUp
        interval: 8000
        onTriggered: root.scanWhenReady = false
    }

    Text {
        text: "Bluetooth"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Entry {
        glyph: "󰂯"
        label: "Bluetooth"
        on: root.bt?.enabled ?? false
        // A hard block — the physical switch — is the one thing a click cannot
        // clear, so say "blocked" rather than "off" and leave the lie out of it.
        value: root.bt?.state === BluetoothAdapterState.Blocked ? "blocked" : (root.bt?.enabled ?? false) ? "on" : "off"
        onClicked: {
            if (!root.bt)
                return;
            if (root.bt.enabled)
                root.bt.enabled = false;
            else
                root.powerOn();
        }
    }

    Entry {
        glyph: "󰐷"
        label: "Scan for devices"
        // Pressing Scan with the radio off was the complaint itself: the row
        // fired StartDiscovery at an adapter that was not powered, got back
        // "Resource Not Ready", and said nothing. Ricelin hides the control
        // outright while off (pill/BtSurface.qml:225); Brain Shell powers up as
        // part of scanning — `(echo 'power on'; echo 'scan on')` in
        // src/popups/BluetoothTab.qml:101. This does the latter, because a
        // control that is on screen should answer to a press: turn the radio
        // on, then start discovery once it has actually arrived.
        on: root.bt?.discovering ?? false
        value: (root.bt?.discovering ?? false) ? "scanning" : root.scanWhenReady ? "turning on" : root.bt?.state === BluetoothAdapterState.Blocked ? "blocked" : ""
        onClicked: {
            if (!root.bt)
                return;
            if (root.bt.discovering) {
                root.bt.discovering = false;
                root.scanWhenReady = false;
                scanGiveUp.stop();
            } else if (root.bt.state === BluetoothAdapterState.Enabled) {
                root.bt.discovering = true;
            } else {
                root.scanWhenReady = true;
                scanGiveUp.restart();
                root.powerOn();
            }
        }
    }

    Text {
        text: "Devices"
        color: Theme.dim
        font.pixelSize: 11
        Layout.topMargin: 6
    }

    ListView {
        id: devices

        // Six rows of devices, and it scrolls past that.
        readonly property int maxRows: 6
        readonly property int capHeight: maxRows * 44 + (maxRows - 1) * spacing

        Layout.fillWidth: true
        Layout.fillHeight: true
        // A ListView reports no implicit height of its own, so the card it
        // sits in would size to nothing and slice the rows. Report the
        // content, and the card follows it up to its own screen clamp — but
        // capped, because a scan turns five paired devices into twenty in a
        // couple of seconds. Uncapped, the card grew to the full height of the
        // screen and carried the two rows above it 600px upwards, out from
        // under the cursor that had just pressed Scan; the next press then
        // landed on whatever had slid into its place, which is a good part of
        // why these buttons read as doing nothing.
        // While a scan is running the row count churns every second as devices
        // come and go, and shell.qml positions this card by centring it on the
        // rail button — so every single change moved both card edges and slid
        // the two control rows out from under the cursor that was reaching for
        // them. Hold the list at its full height for the duration of the scan:
        // the card then resizes once when discovery starts and once when it
        // stops, instead of continuously while you are trying to press things.
        implicitHeight: (root.bt?.discovering ?? false) ? devices.capHeight : Math.min(contentHeight, devices.capHeight)
        spacing: 6
        clip: true
        model: Bluetooth.devices

        delegate: Entry {
            required property var modelData

            width: ListView.view.width
            glyph: modelData.connected ? "󰂱" : "󰂲"
            label: modelData.name || modelData.address
            on: modelData.connected
            value: modelData.pairing ? "pairing" : modelData.state === BluetoothDeviceState.Connecting ? "connecting" : modelData.state === BluetoothDeviceState.Disconnecting ? "disconnecting" : modelData.connected ? "connected" : modelData.paired ? "paired" : ""
            // A device a scan has just turned up is not paired yet, and
            // Connect on an unpaired device fails on the spot — so pair first
            // and let the row say so. Quickshell's pair() covers the devices
            // that need no PIN; the ones that do need a BlueZ agent to answer
            // the prompt, which is why noctalia and Ricelin both hand pairing
            // to bluetoothctl (BtSurface.qml:138). Those stall at "pairing"
            // rather than failing silently.
            onClicked: {
                if (modelData.connected)
                    modelData.disconnect();
                else if (modelData.paired)
                    modelData.connect();
                else
                    modelData.pair();
            }
        }
    }
}
