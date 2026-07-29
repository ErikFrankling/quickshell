import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Theme and wallpaper in one panel — they are the same decision most of the
// time, so the "match theme to wallpaper" toggle lives between them.
ColumnLayout {
    id: root
    spacing: Theme.pad

    property string wallDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
    property list<string> walls: []
    property string current: ""
    property bool matchTheme: false

    readonly property var themes: [
        { name: "Tokyo Night", accent: "#7aa2f7", bg: "#16181d", fav: true },
        { name: "Gruvbox", accent: "#d79921", bg: "#1d2021", fav: true },
        { name: "Catppuccin Mocha", accent: "#89b4fa", bg: "#1e1e2e", fav: true },
        { name: "Nord", accent: "#88c0d0", bg: "#2e3440", fav: false },
        { name: "Rosé Pine", accent: "#c4a7e7", bg: "#191724", fav: false },
        { name: "Everforest", accent: "#a7c080", bg: "#2d353b", fav: false },
        { name: "Kanagawa", accent: "#7e9cd8", bg: "#1f1f28", fav: false }
    ]

    Process {
        id: scan
        running: true
        command: ["sh", "-c", "ls -1 " + root.wallDir + "/*.{jpg,jpeg,png} 2>/dev/null | head -40"]
        stdout: StdioCollector {
            onStreamFinished: root.walls = text.trim().split("\n").filter(s => s !== "")
        }
    }

    Process { id: setWall }

    function apply(path) {
        root.current = path;
        // Hyprland owns the background; no persistence yet, by design.
        setWall.command = ["sh", "-c",
            "hyprctl hyprpaper preload '" + path + "' ; hyprctl hyprpaper wallpaper \",'" + path + "'\""];
        setWall.running = true;
    }

    Text {
        text: "Looks"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Entry {
        glyph: "󰸉"
        label: "Match theme to wallpaper"
        on: root.matchTheme
        value: root.matchTheme ? "on" : "off"
        onClicked: root.matchTheme = !root.matchTheme
    }

    Text { text: "Themes"; color: Theme.dim; font.pixelSize: 11; Layout.topMargin: 6 }

    Repeater {
        model: root.themes.filter(t => t.fav).concat(root.themes.filter(t => !t.fav))
        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Theme.radiusS
            color: tm.containsMouse ? Theme.bgHi : Theme.bgAlt

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 13
                anchors.rightMargin: 13
                spacing: 11
                Rectangle {
                    width: 18; height: 18; radius: 9
                    color: parent.parent.modelData.bg
                    border.width: 2
                    border.color: parent.parent.modelData.accent
                }
                Text {
                    text: parent.parent.modelData.name
                    color: Theme.fg
                    font.pixelSize: 13
                    Layout.fillWidth: true
                }
                Text {
                    visible: parent.parent.modelData.fav
                    text: "★"
                    color: Theme.warn
                    font.pixelSize: 11
                }
            }
            MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true }
        }
    }

    Text { text: "Wallpaper"; color: Theme.dim; font.pixelSize: 11; Layout.topMargin: 6 }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            model: root.walls
            Rectangle {
                required property string modelData
                Layout.fillWidth: true
                implicitHeight: 62
                radius: Theme.radiusS
                clip: true
                border.width: root.current === modelData ? 2 : 0
                border.color: Theme.accent
                color: Theme.bgAlt

                Image {
                    anchors.fill: parent
                    source: "file://" + parent.modelData
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 220
                    asynchronous: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.apply(parent.modelData)
                }
            }
        }
    }

    Text {
        visible: root.walls.length === 0
        text: "No images in " + root.wallDir
        color: Theme.dim
        font.pixelSize: 12
    }

    Item { Layout.fillHeight: true }
}
