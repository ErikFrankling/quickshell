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

    Process {
        id: execute
        stderr: StdioCollector { onStreamFinished: root.error = text.trim() }
        onExited: code => {
            if (code === 0) root.closeRequested();
            else if (!root.error) root.error = "The action was refused. Your session is still running.";
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Repeater {
            id: actions
            model: [
                {label: "Lock", glyph: "󰌾", method: "", command: ["loginctl", "lock-session"]},
                {label: "Sleep", glyph: "󰖔", method: "CanSuspend", command: ["systemctl", "suspend"]},
                {label: "Hibernate", glyph: "󰋊", method: "CanHibernate", command: ["systemctl", "hibernate"]},
                {label: "Restart", glyph: "󰜉", method: "CanReboot", command: ["systemctl", "reboot"]},
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
                enabled: !execute.running && (capability === "yes" || capability === "challenge")
                opacity: enabled ? 1 : 0.45
                focusPolicy: Qt.StrongFocus
                KeyNavigation.right: actions.itemAt((index + 1) % actions.count)
                KeyNavigation.left: actions.itemAt((index + actions.count - 1) % actions.count)
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
                        text: action.capability === "checking" ? "…"
                            : !action.enabled ? "Unavailable"
                            : action.modelData.label === "Lock" ? "Super + L" : ""
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
