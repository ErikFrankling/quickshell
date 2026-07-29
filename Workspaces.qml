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

    // Classes that no lookup will ever resolve. Everyone carries roughly this
    // same list; it is short because most things do resolve.
    readonly property var fixups: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "footclient": "foot",
        "pavucontrol-qt": "pavucontrol",
        "gnome-tweaks": "org.gnome.tweaks"
    })

    readonly property var patterns: [
        { re: /^steam_app_(\d+)$/, to: "steam_icon_$1" },
        { re: /Minecraft.*/, to: "minecraft" },
        { re: /.*polkit.*|gcr.prompter/, to: "system-lock-screen" }
    ]

    // DesktopEntries populates asynchronously, so anything resolved during
    // startup resolves against an empty list. Bump on change and depend on it.
    property int revision: 0
    property var memo: ({})

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.memo = ({});
            root.revision++;
        }
    }

    function has(name) {
        return name && Quickshell.iconPath(name, true) !== "";
    }

    function iconFor(cls) {
        if (!cls)
            return Quickshell.iconPath("application-x-executable");
        if (root.memo[cls])
            return root.memo[cls];

        let name = root.fixups[cls] ?? "";
        if (!name)
            for (const p of root.patterns)
                if (p.re.test(cls)) {
                    name = cls.replace(p.re, p.to);
                    break;
                }

        const want = (name || cls).toLowerCase();
        // The class is often itself a valid icon name with no .desktop at all.
        const direct = [want, want.split(".").slice(-1)[0],
                        want.replace(/_/g, "-"), want.replace(/-/g, "_")]
            .find(n => root.has(n));

        const apps = DesktopEntries.applications.values;
        const hit = apps.find(a => a.id.toLowerCase() === want)
                 ?? apps.find(a => (a.startupClass ?? "").toLowerCase() === want)
                 ?? apps.find(a => a.id.toLowerCase().endsWith("." + want))
                 ?? apps.find(a => a.name.toLowerCase() === want)
                 // Quickshell's own guesser, last so it cannot shadow the above.
                 ?? DesktopEntries.heuristicLookup(cls);

        const out = Quickshell.iconPath(hit?.icon ?? direct ?? cls,
                                        "application-x-executable");
        root.memo[cls] = out;
        return out;
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
                        source: (root.revision, root.iconFor(modelData))
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
