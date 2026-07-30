import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Workspace number plus the icons of whatever is actually running in it,
// resolved from each window's class through the desktop entry database.
ColumnLayout {
    id: root

    spacing: Theme.slotGap

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


    // A workspace has two identities and they do not agree. `name` is what the
    // pill shows; `id` is Hyprland's internal handle, and anything created as
    // `workspace, name:3` (which is how the keybinds are written) shows "3" but
    // gets id -1337, -1338, ... in creation order. Sorting on id therefore
    // scrambles the rail. Sort on the number that is actually on screen.
    function label(w) {
        return w.name.replace(/^special:/, "");
    }

    // Only plain digits are numbered workspaces; named and special ones have no
    // place on the number line, so they go after, in alphabetical order.
    function rank(w) {
        return /^\d+$/.test(w.name) ? parseInt(w.name) : Infinity;
    }

    Repeater {
        // Hyprland hands workspaces back in the order it created them, so they
        // have to be sorted or the rail is in a random order. ScriptModel diffs
        // by identity, so one workspace appearing or going away does not
        // rebuild every other pill.
        model: ScriptModel {
            values: [...Hyprland.workspaces.values].sort((a, b) => {
                const x = root.rank(a), y = root.rank(b);
                return x === y ? root.label(a).localeCompare(root.label(b)) : x - y;
            })
        }

        Rectangle {
            id: ws

            required property var modelData
            readonly property bool here: Hyprland.focusedWorkspace?.id === modelData.id
            readonly property var classes: root.byWorkspace[modelData.id] ?? []

            Layout.alignment: Qt.AlignHCenter
            // One rail slot tall, the same stripe a button or a ring takes.
            // Wider than it is tall because it carries a number and up to two
            // application icons side by side, which a button does not.
            implicitWidth: 44
            implicitHeight: Theme.slot
            radius: Theme.radiusS
            // Idle is the hover colour at zero alpha, never "transparent":
            // "transparent" is transparent *black*, and ColorAnimation walks
            // every channel, so fading in from it drags the fill through a
            // half-opaque near-black — a dark pulse on enter and another on
            // exit, which is what the flicker was. The hover colour is
            // Theme.line for the same reason Btn uses it: these pills stand on
            // the workspace block's own bgHi ground, so a bgHi highlight is
            // invisible and the dark pulse was the only thing left to see.
            // line is the step above every ground the rail draws. The focused pill
            // keeps its accent and deepens it under the pointer, so every pill
            // acknowledges the cursor without ever leaving its own hue.
            color: ws.here ? Qt.alpha(Theme.accent, hover.containsMouse ? 0.34 : 0.22)
                 : hover.containsMouse ? Theme.line
                 : Qt.alpha(Theme.line, 0)

            Behavior on color { ColorAnimation { duration: 120 } }

            Rectangle {
                visible: ws.here
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 2
                height: parent.height * 0.55
                radius: 1
                color: Theme.accent
            }

            // Number and icons side by side keeps each row short, so the rows
            // sit close together and the group reclaims vertical space.
            RowLayout {
                id: body
                anchors.centerIn: parent
                spacing: 3

                Text {
                    // Same label the sort ranks on, so the rail always reads in
                    // the order of the numbers it is showing.
                    //
                    // The number is what the pill is for and it was the
                    // smallest type on the rail, so it goes up two points. The
                    // cap is what a two-digit number needs at that size and not
                    // a pixel less: a workspace named rather than numbered
                    // elides instead of pushing its icons out of the pill, but
                    // "10" — which is a real workspace here — must never elide,
                    // and at 15 it did.
                    text: root.label(ws.modelData)
                    color: ws.here ? Theme.accent : Theme.dim
                    font.pixelSize: 13
                    font.weight: ws.here ? Font.Bold : Font.Normal
                    elide: Text.ElideRight
                    Layout.maximumWidth: 20
                }

                Repeater {
                    model: ws.classes.slice(0, 2)
                    Image {
                        required property string modelData
                        source: (root.revision, root.iconFor(modelData))
                        sourceSize.width: 13
                        sourceSize.height: 13
                        Layout.preferredWidth: 13
                        Layout.preferredHeight: 13
                        opacity: ws.here ? 1 : 0.62
                        smooth: true
                    }
                }

                Text {
                    visible: ws.classes.length > 2
                    text: "+" + (ws.classes.length - 2)
                    color: Theme.dim
                    font.pixelSize: 8
                }
            }

            MouseArea {
                id: hover
                // The pills stand Theme.slotGap apart, so a hit area that stops
                // at the visual leaves a dead strip between every pair:
                // dragging down the rail fires exit and enter at each boundary
                // and the highlight drops out and comes back on the way past.
                // Reaching half the gap either way makes the areas tile, which
                // is what every rail worth copying does — bjarneo -2,
                // josecriane and tripathiji -4, noctalia a full-height
                // container behind a smaller pill. Rounding up rather than down
                // keeps them tiling when the gap is odd.
                anchors.fill: parent
                anchors.margins: -Math.ceil(Theme.slotGap / 2)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ws.modelData.activate()
            }
        }
    }
}
