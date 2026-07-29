import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Workspace number plus the icons of whatever is actually running in it,
// resolved from each window's class through the desktop entry database.
ColumnLayout {
    id: root

    spacing: 6

    // Windows grouped by workspace id, deduped by class so three terminals
    // show one icon rather than three.
    readonly property var byWorkspace: {
        const m = ({});
        for (const t of Hyprland.toplevels.values) {
            const ws = t.workspace?.id;
            const cls = t.lastIpcObject?.class ?? "";
            if (ws === undefined || cls === "")
                continue;
            if (!m[ws])
                m[ws] = [];
            if (!m[ws].includes(cls))
                m[ws].push(cls);
        }
        return m;
    }

    // Window classes rarely match a .desktop id exactly, so try the obvious
    // spellings before giving up and letting the icon theme guess.
    function iconFor(cls) {
        const want = cls.toLowerCase();
        const apps = DesktopEntries.applications.values;
        const hit = apps.find(a => a.id.toLowerCase() === want)
                 ?? apps.find(a => (a.startupClass ?? "").toLowerCase() === want)
                 ?? apps.find(a => a.id.toLowerCase().endsWith("." + want))
                 ?? apps.find(a => a.name.toLowerCase() === want);
        return Quickshell.iconPath(hit ? hit.icon : want, true);
    }

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            id: ws

            required property var modelData
            readonly property bool here: Hyprland.focusedWorkspace?.id === modelData.id
            readonly property var classes: root.byWorkspace[modelData.id] ?? []

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 40
            implicitHeight: body.implicitHeight + 10
            radius: Theme.radiusS
            color: ws.here ? Qt.alpha(Theme.accent, 0.22) : hover.containsMouse ? Theme.bgHi : "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            Rectangle {
                visible: ws.here
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 2
                height: parent.height * 0.55
                radius: 1
                color: Theme.accent
            }

            ColumnLayout {
                id: body
                anchors.centerIn: parent
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: ws.modelData.name
                    color: ws.here ? Theme.accent : Theme.dim
                    font.pixelSize: 11
                    font.weight: ws.here ? Font.Bold : Font.Normal
                }

                // Up to three icons, then a count for the rest.
                Repeater {
                    model: ws.classes.slice(0, 3)
                    Image {
                        required property string modelData
                        Layout.alignment: Qt.AlignHCenter
                        source: root.iconFor(modelData)
                        sourceSize.width: 15
                        sourceSize.height: 15
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                        opacity: ws.here ? 1 : 0.62
                        smooth: true
                    }
                }

                Text {
                    visible: ws.classes.length > 3
                    Layout.alignment: Qt.AlignHCenter
                    text: "+" + (ws.classes.length - 3)
                    color: Theme.dim
                    font.pixelSize: 8
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: ws.modelData.activate()
            }
        }
    }
}
