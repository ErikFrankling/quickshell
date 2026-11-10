import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    function neighbor(index, step) {
        for (let n = 1; n <= actions.count; n++) {
            const item = actions.itemAt((index + step * n + actions.count * n) % actions.count);
            if (item && item.visible && item.enabled) return item;
        }
        return null;
    }

    Process {
        id: execute
        stderr: StdioCollector { onStreamFinished: root.error = text.trim() }
        onExited: code => {
            if (code === 0) root.closeRequested();
            else if (!root.error) root.error = "The action was refused. Your session is still running.";
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 12
        rowSpacing: 12
        Repeater {
            id: actions
            model: [
                {label: "Lock", glyph: "󰌾", method: "", command: ["loginctl", "lock-session"]},
                {label: "Sleep", glyph: "󰖔", method: "CanSuspend", command: ["systemctl", "suspend"]},
                {label: "Hibernate", glyph: "󰋊", method: "CanHibernate", command: ["systemctl", "hibernate"]},
                {label: "Restart", glyph: "󰜉", method: "CanReboot", command: ["systemctl", "reboot"]},
                {label: "Boot menu", glyph: "󰍹", method: "CanRebootToBootLoaderMenu", command: ["systemctl", "reboot", "--boot-loader-menu=30s"]},
                {label: "UEFI settings", glyph: "󰒓", method: "CanRebootToFirmwareSetup", command: ["systemctl", "reboot", "--firmware-setup"]},
                {label: "Shut down", glyph: "󰐥", method: "CanPowerOff", command: ["systemctl", "poweroff"]}
            ]
            delegate: AbstractButton {
                id: action
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitWidth: 112
                implicitHeight: 142
                readonly property bool highlighted: hovered || activeFocus
                readonly property color tone: modelData.label === "Shut down" ? Theme.bad : Theme.accent
                property string capability: modelData.method ? "checking" : "yes"
                visible: capability === "yes" || capability === "challenge"
                enabled: !execute.running && (capability === "yes" || capability === "challenge")
                opacity: enabled ? 1 : 0.45
                focusPolicy: Qt.StrongFocus
                KeyNavigation.right: root.neighbor(index, 1)
                KeyNavigation.left: root.neighbor(index, -1)
                background: Rectangle {
                    radius: action.highlighted ? Theme.radius + 6 : Theme.radius
                    color: action.highlighted ? Qt.alpha(action.tone, 0.18) : Theme.bgAlt
                    border.width: 1
                    border.color: action.highlighted ? action.tone : Theme.line
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on radius { NumberAnimation { duration: 140 } }
                }
                contentItem: Column {
                    spacing: 10
                    topPadding: 24
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: action.modelData.glyph
                        color: action.enabled ? action.tone : Theme.dim
                        font.pixelSize: 38
                        scale: action.highlighted ? 1.1 : 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: action.modelData.label
                        color: Theme.fg
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: action.modelData.label === "Lock" ? "Super + Ctrl + L" : ""
                        color: Theme.dim
                        font.pixelSize: 10
                    }
                }
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
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
