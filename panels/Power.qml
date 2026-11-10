import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: root
    spacing: 8
    signal closeRequested
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

    Repeater {
        model: [
            {label: "Lock", glyph: "󰌾", method: "", command: ["loginctl", "lock-session"]},
            {label: "Sleep", glyph: "󰒲", method: "CanSuspend", command: ["systemctl", "suspend"]},
            {label: "Hibernate", glyph: "󰋊", method: "CanHibernate", command: ["systemctl", "hibernate"]},
            {label: "Restart", glyph: "󰜉", method: "CanReboot", command: ["systemctl", "reboot"]},
            {label: "Shut down", glyph: "󰐥", method: "CanPowerOff", command: ["systemctl", "poweroff"]}
        ]
        delegate: Entry {
            id: action
            required property var modelData
            property string capability: modelData.method ? "checking" : "yes"
            enabled: !execute.running && (capability === "yes" || capability === "challenge")
            opacity: enabled ? 1 : 0.45
            glyph: modelData.glyph
            label: modelData.label
            value: capability === "checking" ? "Checking…"
                 : !enabled ? "Unavailable" : modelData.label === "Lock" ? "Super + L" : ""
            activeFocusOnTab: enabled
            on: activeFocus
            Keys.onReturnPressed: clicked()
            Keys.onSpacePressed: clicked()
            onClicked: root.run(modelData)
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
    Text {
        visible: root.error !== ""
        text: root.error
        color: Theme.bad
        font.pixelSize: 12
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
}
