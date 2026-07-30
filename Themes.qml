import QtQuick
import QtQuick.Layouts
import Quickshell
import "schemes.js" as Schemes

// The theme list: nine hand-picked palettes, then every base16 scheme
// tinted-theming publishes, in one list with one search box over both.
//
// Two lists would need two delegates, two models and a rule for which one you
// are looking at, so `curated` is built into exactly the shape a row of
// schemes.js already has and the delegate never has to ask. The hand-picked
// ones sit at the top because they are the ones he actually wears; the other
// 335 are one scroll below, which is what "let me look at all of them" wants.
//
// base00 is the first swatch on every row, so the light schemes announce
// themselves by being pale before you have read a word.
ColumnLayout {
    id: root
    spacing: 8

    property string query: ""
    // "", "light" or "dark".
    property string only: ""

    function row(name, variant, p, fav) {
        return {
            name: name,
            light: variant === "light",
            p: Object.assign({ name: name, variant: variant }, p),
            swatch: [p.base00, p.base05, p.base08, p.base0A, p.base0B, p.accent ?? p.base0D],
            find: (name + " " + variant).toLowerCase(),
            fav: fav
        };
    }

    // base16 palettes, with each slot meaning what tinted-theming's styling
    // spec says it means: base00 background, base01 lighter background, base02
    // selection, base03 comments, base04 dark foreground, base05 foreground,
    // base06-07 lighter still, base08-0F red, orange, yellow, green, cyan,
    // blue, magenta, brown. Theme.qml reads the shell's colours out of these
    // slots and Scheme.qml publishes the whole palette for the rest of the
    // desktop — so a slot that lies here makes every other application lie.
    //
    // "Lighter" is the spec's word for a dark scheme. A light scheme runs the
    // same eight slots the other way, base00 lightest to base07 darkest, and
    // that is the whole of why one works here: `bg` is base00 and `fg` is
    // base05 by role, not by brightness, so the palette flips and no colour in
    // this shell had to be told about it.
    //
    // base03 is the colour a theme draws comments in, legible against base00,
    // and never a border. `line` is the border and `accent` the colour a theme
    // is known by; both sit outside the base namespace on purpose.
    readonly property var curated: [
        root.row("Tokyo Night", "dark", { base00: "#16181d", base01: "#1d2027", base02: "#252932", base03: "#565f89", base04: "#7c8796", base05: "#d3dae3", base06: "#c0caf5", base07: "#d5d6db", base08: "#f7768e", base09: "#ff9e64", base0A: "#e0af68", base0B: "#9ece6a", base0C: "#7dcfff", base0D: "#7aa2f7", base0E: "#bb9af7", base0F: "#d18616", line: "#2c313b" }, true),
        root.row("Gruvbox", "dark", { base00: "#1d2021", base01: "#282828", base02: "#32302f", base03: "#665c54", base04: "#928374", base05: "#ebdbb2", base06: "#d5c4a1", base07: "#fbf1c7", base08: "#fb4934", base09: "#fe8019", base0A: "#fabd2f", base0B: "#b8bb26", base0C: "#8ec07c", base0D: "#83a598", base0E: "#d3869b", base0F: "#d65d0e", line: "#3c3836", accent: "#d79921" }, true),
        root.row("Catppuccin Mocha", "dark", { base00: "#1e1e2e", base01: "#26263a", base02: "#313244", base03: "#6c7086", base04: "#7f849c", base05: "#cdd6f4", base06: "#f5e0dc", base07: "#b4befe", base08: "#f38ba8", base09: "#fab387", base0A: "#f9e2af", base0B: "#a6e3a1", base0C: "#94e2d5", base0D: "#89b4fa", base0E: "#cba6f7", base0F: "#f2cdcd", line: "#45475a" }, true),

        // The light half. Taken verbatim from tinted-theming's spec-0.11
        // base16/ — gruvbox-light-medium, rose-pine-dawn — rather than made up,
        // because a light palette that was eyeballed goes wrong in the same
        // places every eyeballed palette does. Each is the light counterpart of
        // a dark scheme already in this list, so switching is a change of
        // brightness and not of taste.
        //
        // `line` is the one slot they do not get from upstream: base03 is a
        // comment grey and on cream it reads as a scar, so the hairline is the
        // slot below it, the way every dark scheme here also names its own.
        // Neither names an `accent`: base0D is the highest-contrast colour in
        // both against their own base00, and accent is what the workspace
        // label and the notification's app name are drawn in, so it is the one
        // place a light scheme cannot afford the prettier choice.
        root.row("Gruvbox Light", "light", { base00: "#fbf1c7", base01: "#ebdbb2", base02: "#d5c4a1", base03: "#bdae93", base04: "#665c54", base05: "#504945", base06: "#3c3836", base07: "#282828", base08: "#9d0006", base09: "#af3a03", base0A: "#b57614", base0B: "#79740e", base0C: "#427b58", base0D: "#076678", base0E: "#8f3f71", base0F: "#d65d0e", line: "#c8b795" }, true),
        root.row("Rosé Pine Dawn", "light", { base00: "#faf4ed", base01: "#fffaf3", base02: "#f2e9de", base03: "#9893a5", base04: "#797593", base05: "#575279", base06: "#575279", base07: "#cecacd", base08: "#b4637a", base09: "#ea9d34", base0A: "#d7827e", base0B: "#286983", base0C: "#56949f", base0D: "#907aa9", base0E: "#ea9d34", base0F: "#cecacd", line: "#e4dcd4" }, true),

        root.row("Nord", "dark", { base00: "#2e3440", base01: "#343b4a", base02: "#3b4252", base03: "#616e88", base04: "#7b88a1", base05: "#eceff4", base06: "#e5e9f0", base07: "#f7f9fb", base08: "#bf616a", base09: "#d08770", base0A: "#ebcb8b", base0B: "#a3be8c", base0C: "#8fbcbb", base0D: "#88c0d0", base0E: "#b48ead", base0F: "#5e81ac", line: "#434c5e" }, false),
        root.row("Rosé Pine", "dark", { base00: "#191724", base01: "#1f1d2e", base02: "#26233a", base03: "#6e6a86", base04: "#908caa", base05: "#e0def4", base06: "#e0def4", base07: "#faf4ed", base08: "#eb6f92", base09: "#ebbcba", base0A: "#f6c177", base0B: "#9ccfd8", base0C: "#31748f", base0D: "#c4a7e7", base0E: "#ebbcba", base0F: "#524f67", line: "#403d52" }, false),
        root.row("Everforest", "dark", { base00: "#2d353b", base01: "#343f44", base02: "#3d484d", base03: "#859289", base04: "#859289", base05: "#d3c6aa", base06: "#e6e2cc", base07: "#fdf6e3", base08: "#e67e80", base09: "#e69875", base0A: "#dbbc7f", base0B: "#a7c080", base0C: "#83c092", base0D: "#7fbbb3", base0E: "#d699b6", base0F: "#9da9a0", line: "#475258", accent: "#a7c080" }, false),
        root.row("Kanagawa", "dark", { base00: "#1f1f28", base01: "#2a2a37", base02: "#363646", base03: "#727169", base04: "#727169", base05: "#dcd7ba", base06: "#c8c093", base07: "#e6e0c2", base08: "#e82424", base09: "#ffa066", base0A: "#e6c384", base0B: "#98bb6c", base0C: "#7aa89f", base0D: "#7e9cd8", base0E: "#957fb8", base0F: "#d27e99", line: "#54546d" }, false)
    ]

    readonly property var rows: {
        const q = root.query.trim().toLowerCase();
        let list = root.curated.concat(Schemes.all);
        if (root.only !== "")
            list = list.filter(s => (s.light ? "light" : "dark") === root.only);
        if (q !== "")
            list = list.filter(s => s.find.indexOf(q) >= 0);
        return list;
    }

    component Pill: Rectangle {
        id: pill
        property alias label: t.text
        property bool on: false
        signal clicked

        implicitWidth: t.implicitWidth + 20
        implicitHeight: 26
        radius: 13
        color: pill.on ? Theme.accent : ma.containsMouse ? Theme.bgHi : Theme.bgAlt

        Text {
            id: t
            anchors.centerIn: parent
            color: pill.on ? Theme.bg : Theme.fg
            font.pixelSize: 11
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            text: root.rows.length + " of " + (root.curated.length + Schemes.all.length)
            color: Theme.dim
            font.pixelSize: 11
            Layout.fillWidth: true
        }
        Pill { label: "All"; on: root.only === ""; onClicked: root.only = "" }
        Pill { label: "Dark"; on: root.only === "dark"; onClicked: root.only = "dark" }
        Pill { label: "Light"; on: root.only === "light"; onClicked: root.only = "light" }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 32
        radius: Theme.radiusS
        color: Theme.bgAlt
        border.width: field.activeFocus ? 1 : 0
        border.color: Theme.accent

        TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.fg
            font.pixelSize: 13
            onTextChanged: root.query = text

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: field.text === ""
                text: "Search 344 schemes"
                color: Theme.dim
                font.pixelSize: 12
            }
        }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 220
        spacing: 4
        clip: true

        // A plain array here segfaults quickshell when an entry goes away.
        model: ScriptModel { values: root.rows }

        delegate: Rectangle {
            id: card
            required property var modelData
            readonly property bool on: Theme.name === card.modelData.name

            width: list.width
            implicitHeight: 42
            radius: Theme.radiusS
            color: card.on ? Qt.alpha(Theme.accent, 0.18) : tm.containsMouse ? Theme.bgHi : Theme.bgAlt

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                // base00 first: the background is the one swatch that tells you
                // at a glance which half of the corpus you are looking at.
                Row {
                    spacing: 3
                    Repeater {
                        model: card.modelData.swatch
                        Rectangle {
                            required property string modelData
                            width: 9
                            height: 18
                            radius: 3
                            color: modelData
                        }
                    }
                }
                Text {
                    text: card.modelData.name
                    color: Theme.fg
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: card.modelData.light ? "Light" : "Dark"
                    color: Theme.dim
                    font.pixelSize: 10
                }
                Text {
                    visible: card.modelData.fav ?? false
                    text: "★"
                    color: Theme.warn
                    font.pixelSize: 11
                }
            }

            MouseArea {
                id: tm
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Theme.apply(card.modelData.p)
            }
        }
    }
}
