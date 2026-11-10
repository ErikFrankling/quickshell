import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: 8
    signal closeRequested
    property var pending: null
    property string error: ""

    function run(action) {
        root.error = "";
        execute.command = action.command;
        execute.running = true;
    }

    Process {
        id: execute
        stderr: StdioCollector { onStreamFinished: root.error = text.trim() }
        onExited: code => {
            if (code === 0) root.closeRequested();
            else if (!root.error) root.error = "The action was refused. Your session is still running.";
        }
    }

    Text {
        text: root.pending ? root.pending.label + "?" : "Power & session"
        color: Theme.fg
        font.pixelSize: 22
        Layout.bottomMargin: 6
    }
    Text {
        visible: root.pending !== null
        text: "Save your work before continuing."
        color: Theme.dim
        font.pixelSize: 13
    }
    Repeater {
        model: [
            {label: "Lock", glyph: "󰌾", hint: "Super + L", method: "", command: ["loginctl", "lock-session"], confirm: false},
            {label: "Sleep", glyph: "󰒲", hint: "Suspend to memory", method: "CanSuspend", command: ["systemctl", "suspend"], confirm: false},
            {label: "Hibernate", glyph: "󰋊", hint: "Save session to disk", method: "CanHibernate", command: ["systemctl", "hibernate"], confirm: false},
            {label: "Log out", glyph: "󰍃", hint: "End this session", method: "", command: ["hyprctl", "dispatch", "hl.dsp.exit()"], confirm: true},
            {label: "Restart", glyph: "󰜉", hint: "Reboot the computer", method: "CanReboot", command: ["systemctl", "reboot"], confirm: true},
            {label: "Shut down", glyph: "󰐥", hint: "Power off", method: "CanPowerOff", command: ["systemctl", "poweroff"], confirm: true}
        ]
        delegate: Entry {
            id: action
            required property var modelData
            property string capability: modelData.method ? "checking" : "yes"
            visible: root.pending === null
            enabled: !execute.running && (capability === "yes" || capability === "challenge")
            opacity: enabled ? 1 : 0.45
            glyph: modelData.glyph
            label: modelData.label
            value: capability === "checking" ? "Checking…"
                 : !enabled ? "Unavailable on this system" : modelData.hint
            activeFocusOnTab: enabled
            on: activeFocus
            Keys.onReturnPressed: clicked()
            Keys.onSpacePressed: clicked()
            onClicked: {
                if (modelData.confirm) root.pending = modelData;
                else root.run(modelData);
            }
            Process {
                running: action.modelData.method !== ""
                command: ["busctl", "--system", "--json=short", "call", "org.freedesktop.login1",
                    "/org/freedesktop/login1", "org.freedesktop.login1.Manager", action.modelData.method]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try { action.capability = JSON.parse(text).data[0]; }
                        catch (e) { action.capability = "no"; }
                    }
                }
                onExited: code => { if (code !== 0) action.capability = "no"; }
            }
        }
    }
    Entry {
        visible: root.pending !== null
        label: "Cancel"
        glyph: "󰜺"
        activeFocusOnTab: visible
        on: activeFocus
        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()
        onClicked: root.pending = null
    }
    Entry {
        visible: root.pending !== null
        enabled: !execute.running
        label: root.pending ? root.pending.label : ""
        glyph: root.pending ? root.pending.glyph : ""
        value: "Confirm"
        activeFocusOnTab: visible
        on: activeFocus
        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()
        onClicked: if (root.pending) root.run(root.pending)
    }
    Text {
        visible: root.error !== ""
        text: root.error
        color: Theme.bad
        font.pixelSize: 12
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
    Text {
        text: "Esc or click outside to close"
        color: Theme.dim
        font.pixelSize: 11
        Layout.topMargin: 6
    }
}
