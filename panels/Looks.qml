import ".."
import QtQuick
import QtQuick.Layouts

// Theme and wallpaper together, because picking one usually means picking the
// other. Themes apply immediately by writing the palette Theme.qml watches.
// The wallpaper half is Wallpapers.qml — it was the larger of the two.
//
// The panel hands every page the full height of the card, but the card is only
// as tall as the page's implicitHeight. A ColumnLayout stretches its children
// to fill whatever height it is given, so the extra pushed the bottom of this
// page — the wallpaper grid — past the card's clip. Pinning the layout to its
// own implicit height keeps what is laid out and what is shown the same size.
Item {
    id: root
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: root.width
        height: implicitHeight
        spacing: Theme.pad

        // base16 palettes, with each slot meaning what tinted-theming's styling
        // spec says it means: base00 background, base01 lighter background,
        // base02 selection, base03 comments, base04 dark foreground, base05
        // foreground, base06-07 lighter still, base08-0F red, orange, yellow,
        // green, cyan, blue, magenta, brown. Theme.qml reads the shell's colours
        // out of these slots and Scheme.qml publishes the whole palette for the
        // rest of the desktop — so a slot that lies here makes every other
        // application lie, and one already had to work around base03.
        //
        // base03 is therefore the colour that theme draws comments in, legible
        // against base00 (2.4:1 to 3.8:1 here, each taken from the theme
        // upstream), and never a border. `line` is the border, and `accent` the
        // colour a theme is known by; both sit outside the base namespace on
        // purpose, because base16 has no slot for either and Scheme only
        // publishes base*.
        readonly property var themes: [
            { name: "Tokyo Night", fav: true, p: { base00: "#16181d", base01: "#1d2027", base02: "#252932", base03: "#565f89", base04: "#7c8796", base05: "#d3dae3", base06: "#c0caf5", base07: "#d5d6db", base08: "#f7768e", base09: "#ff9e64", base0A: "#e0af68", base0B: "#9ece6a", base0C: "#7dcfff", base0D: "#7aa2f7", base0E: "#bb9af7", base0F: "#d18616", line: "#2c313b" } },
            { name: "Gruvbox", fav: true, p: { base00: "#1d2021", base01: "#282828", base02: "#32302f", base03: "#665c54", base04: "#928374", base05: "#ebdbb2", base06: "#d5c4a1", base07: "#fbf1c7", base08: "#fb4934", base09: "#fe8019", base0A: "#fabd2f", base0B: "#b8bb26", base0C: "#8ec07c", base0D: "#83a598", base0E: "#d3869b", base0F: "#d65d0e", line: "#3c3836", accent: "#d79921" } },
            { name: "Catppuccin Mocha", fav: true, p: { base00: "#1e1e2e", base01: "#26263a", base02: "#313244", base03: "#6c7086", base04: "#7f849c", base05: "#cdd6f4", base06: "#f5e0dc", base07: "#b4befe", base08: "#f38ba8", base09: "#fab387", base0A: "#f9e2af", base0B: "#a6e3a1", base0C: "#94e2d5", base0D: "#89b4fa", base0E: "#cba6f7", base0F: "#f2cdcd", line: "#45475a" } },
            { name: "Nord", fav: false, p: { base00: "#2e3440", base01: "#343b4a", base02: "#3b4252", base03: "#616e88", base04: "#7b88a1", base05: "#eceff4", base06: "#e5e9f0", base07: "#f7f9fb", base08: "#bf616a", base09: "#d08770", base0A: "#ebcb8b", base0B: "#a3be8c", base0C: "#8fbcbb", base0D: "#88c0d0", base0E: "#b48ead", base0F: "#5e81ac", line: "#434c5e" } },
            { name: "Rosé Pine", fav: false, p: { base00: "#191724", base01: "#1f1d2e", base02: "#26233a", base03: "#6e6a86", base04: "#908caa", base05: "#e0def4", base06: "#e0def4", base07: "#faf4ed", base08: "#eb6f92", base09: "#ebbcba", base0A: "#f6c177", base0B: "#9ccfd8", base0C: "#31748f", base0D: "#c4a7e7", base0E: "#ebbcba", base0F: "#524f67", line: "#403d52" } },
            { name: "Everforest", fav: false, p: { base00: "#2d353b", base01: "#343f44", base02: "#3d484d", base03: "#859289", base04: "#859289", base05: "#d3c6aa", base06: "#e6e2cc", base07: "#fdf6e3", base08: "#e67e80", base09: "#e69875", base0A: "#dbbc7f", base0B: "#a7c080", base0C: "#83c092", base0D: "#7fbbb3", base0E: "#d699b6", base0F: "#9da9a0", line: "#475258", accent: "#a7c080" } },
            { name: "Kanagawa", fav: false, p: { base00: "#1f1f28", base01: "#2a2a37", base02: "#363646", base03: "#727169", base04: "#727169", base05: "#dcd7ba", base06: "#c8c093", base07: "#e6e0c2", base08: "#e82424", base09: "#ffa066", base0A: "#e6c384", base0B: "#98bb6c", base0C: "#7aa89f", base0D: "#7e9cd8", base0E: "#957fb8", base0F: "#d27e99", line: "#54546d" } }
        ]

        Text {
            text: "Looks"
            color: Theme.fg
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        Text { text: "Themes"; color: Theme.dim; font.pixelSize: 11 }

        Repeater {
            model: col.themes.filter(t => t.fav).concat(col.themes.filter(t => !t.fav))
            Rectangle {
                id: card
                required property var modelData
                readonly property bool on: Theme.name === modelData.name

                Layout.fillWidth: true
                implicitHeight: 42
                radius: Theme.radiusS
                color: card.on ? Qt.alpha(Theme.accent, 0.18) : tm.containsMouse ? Theme.bgHi : Theme.bgAlt

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    // A swatch of the palette itself, so the list is scannable.
                    Row {
                        spacing: 3
                        Repeater {
                            model: [card.modelData.p.accent ?? card.modelData.p.base0D,
                                    card.modelData.p.base0B, card.modelData.p.base0A,
                                    card.modelData.p.base08]
                            Rectangle {
                                required property string modelData
                                width: 9; height: 18; radius: 3
                                color: modelData
                            }
                        }
                    }
                    Text {
                        text: card.modelData.name
                        color: Theme.fg
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: card.modelData.fav
                        text: "★"
                        color: Theme.warn
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    id: tm
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Theme.apply(Object.assign({ name: card.modelData.name }, card.modelData.p))
                }
            }
        }

        Wallpapers { Layout.fillWidth: true; Layout.topMargin: 6 }
    }
}
