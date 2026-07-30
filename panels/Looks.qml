import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Theme and wallpaper together, because picking one usually means picking the
// other. Themes apply immediately by writing the palette Theme.qml watches.
ColumnLayout {
    id: root
    spacing: Theme.pad

    property string wallDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
    property list<string> walls: []
    property string current: ""
    property string query: ""
    property var hits: []
    property bool busy: false

    // One grid, two sources. Empty search box shows what is on disk; typing
    // shows wallhaven. Clicking either sets the wallpaper, downloading first
    // if it is not local yet.
    readonly property var cells: root.query.trim() === ""
        ? root.walls.map(w => ({ thumb: "file://" + w, full: w, id: "" }))
        : root.hits

    // base16 palettes: base00-03 background to border, base04-07 muted to
    // brightest text, base08-0F red, orange, yellow, green, cyan, blue, magenta,
    // brown. Theme.qml reads the shell's colours out of these slots and
    // Scheme.qml publishes the whole palette for everything else on the desktop.
    readonly property var themes: [
        { name: "Tokyo Night", fav: true, p: { base00: "#16181d", base01: "#1d2027", base02: "#252932", base03: "#2c313b", base04: "#7c8796", base05: "#d3dae3", base06: "#c0caf5", base07: "#d5d6db", base08: "#f7768e", base09: "#ff9e64", base0A: "#e0af68", base0B: "#9ece6a", base0C: "#7dcfff", base0D: "#7aa2f7", base0E: "#bb9af7", base0F: "#d18616" } },
        { name: "Gruvbox", fav: true, p: { base00: "#1d2021", base01: "#282828", base02: "#32302f", base03: "#3c3836", base04: "#928374", base05: "#ebdbb2", base06: "#d5c4a1", base07: "#fbf1c7", base08: "#fb4934", base09: "#fe8019", base0A: "#fabd2f", base0B: "#b8bb26", base0C: "#8ec07c", base0D: "#83a598", base0E: "#d3869b", base0F: "#d65d0e", accent: "#d79921" } },
        { name: "Catppuccin Mocha", fav: true, p: { base00: "#1e1e2e", base01: "#26263a", base02: "#313244", base03: "#45475a", base04: "#7f849c", base05: "#cdd6f4", base06: "#f5e0dc", base07: "#b4befe", base08: "#f38ba8", base09: "#fab387", base0A: "#f9e2af", base0B: "#a6e3a1", base0C: "#94e2d5", base0D: "#89b4fa", base0E: "#cba6f7", base0F: "#f2cdcd" } },
        { name: "Nord", fav: false, p: { base00: "#2e3440", base01: "#343b4a", base02: "#3b4252", base03: "#434c5e", base04: "#7b88a1", base05: "#eceff4", base06: "#e5e9f0", base07: "#f7f9fb", base08: "#bf616a", base09: "#d08770", base0A: "#ebcb8b", base0B: "#a3be8c", base0C: "#8fbcbb", base0D: "#88c0d0", base0E: "#b48ead", base0F: "#5e81ac" } },
        { name: "Rosé Pine", fav: false, p: { base00: "#191724", base01: "#1f1d2e", base02: "#26233a", base03: "#403d52", base04: "#908caa", base05: "#e0def4", base06: "#e0def4", base07: "#faf4ed", base08: "#eb6f92", base09: "#ebbcba", base0A: "#f6c177", base0B: "#9ccfd8", base0C: "#31748f", base0D: "#c4a7e7", base0E: "#ebbcba", base0F: "#524f67" } },
        { name: "Everforest", fav: false, p: { base00: "#2d353b", base01: "#343f44", base02: "#3d484d", base03: "#475258", base04: "#859289", base05: "#d3c6aa", base06: "#e6e2cc", base07: "#fdf6e3", base08: "#e67e80", base09: "#e69875", base0A: "#dbbc7f", base0B: "#a7c080", base0C: "#83c092", base0D: "#7fbbb3", base0E: "#d699b6", base0F: "#9da9a0", accent: "#a7c080" } },
        { name: "Kanagawa", fav: false, p: { base00: "#1f1f28", base01: "#2a2a37", base02: "#363646", base03: "#54546d", base04: "#727169", base05: "#dcd7ba", base06: "#c8c093", base07: "#e6e0c2", base08: "#e82424", base09: "#ffa066", base0A: "#e6c384", base0B: "#98bb6c", base0C: "#7aa89f", base0D: "#7e9cd8", base0E: "#957fb8", base0F: "#d27e99" } }
    ]

    Process {
        id: scan
        running: true
        command: ["sh", "-c", "ls -1 " + root.wallDir + "/*.jpg " + root.wallDir + "/*.jpeg " + root.wallDir + "/*.png 2>/dev/null | head -40"]
        stdout: StdioCollector {
            onStreamFinished: root.walls = text.trim().split("\n").filter(s => s !== "")
        }
    }

    Process { id: wallProc }

    // wallhaven's anonymous search API — SFW, general category, 1080p and up.
    Process {
        id: fetch
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                try {
                    root.hits = JSON.parse(text).data.map(d => ({ thumb: d.thumbs.small, full: d.path, id: d.id }));
                } catch (e) { root.hits = []; }
            }
        }
    }

    Timer {
        id: debounce
        interval: 350
        onTriggered: {
            const q = root.query.trim();
            if (q === "") { root.hits = []; return; }
            root.busy = true;
            fetch.command = ["curl", "-fsS", "--max-time", "15",
                "https://wallhaven.cc/api/v1/search?categories=100&purity=100" +
                "&atleast=1920x1080&sorting=relevance&q=" + encodeURIComponent(q)];
            fetch.running = false;
            fetch.running = true;
        }
    }

    onQueryChanged: debounce.restart()

    Process {
        id: dl
        property string dest: ""
        onExited: code => {
            root.busy = false;
            if (code === 0) { root.setWall(dl.dest); scan.running = true; }
        }
    }

    function pick(cell) {
        if (cell.id === "") { root.setWall(cell.full); return; }
        const dest = root.wallDir + "/wallhaven-" + cell.id +
            (cell.full.toLowerCase().endsWith(".png") ? ".png" : ".jpg");
        root.busy = true;
        dl.dest = dest;
        dl.command = ["sh", "-c", "mkdir -p " + JSON.stringify(root.wallDir) +
            " && { [ -s " + JSON.stringify(dest) + " ] || curl -fsSL --max-time 90 -o " +
            JSON.stringify(dest) + " " + JSON.stringify(cell.full) + "; }"];
        dl.running = true;
    }

    // Start hyprpaper if it is not already up, then set the image. It ships in
    // this flake, so it is on PATH whether or not the system config has it.
    // hyprpaper 0.8 dropped `preload` and no longer wants the path quoted.
    function setWall(path) {
        root.current = path;
        wallProc.running = false;
        wallProc.command = ["sh", "-c",
            "pgrep -x hyprpaper >/dev/null || { setsid hyprpaper >/dev/null 2>&1 & sleep 1; }; " +
            "hyprctl hyprpaper wallpaper " + JSON.stringify("," + path)];
        wallProc.running = true;
    }

    Text {
        text: "Looks"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Text { text: "Themes"; color: Theme.dim; font.pixelSize: 11 }

    Repeater {
        model: root.themes.filter(t => t.fav).concat(root.themes.filter(t => !t.fav))
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

    Text {
        text: root.busy ? "Wallpaper  …" : "Wallpaper"
        color: root.busy ? Theme.accent : Theme.dim
        font.pixelSize: 11
        Layout.topMargin: 6
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 34
        radius: Theme.radiusS
        color: Theme.bgAlt
        border.width: search.activeFocus ? 1 : 0
        border.color: Theme.accent

        TextInput {
            id: search
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.fg
            font.pixelSize: 13
            onTextChanged: root.query = text
            Keys.onEscapePressed: search.text = ""

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: search.text === ""
                text: "Search wallhaven"
                color: Theme.dim
                font.pixelSize: 13
            }
        }
    }

    GridView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        cellWidth: Math.floor(width / 3)
        cellHeight: Math.round(cellWidth * 9 / 16)
        model: root.cells

        delegate: Rectangle {
            id: cell
            required property var modelData
            width: GridView.view.cellWidth - 6
            height: GridView.view.cellHeight - 6
            radius: Theme.radiusS
            clip: true
            color: Theme.bgAlt
            border.width: root.current === cell.modelData.full ? 2 : 0
            border.color: Theme.accent

            Image {
                anchors.fill: parent
                source: cell.modelData.thumb
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 220
                asynchronous: true
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.pick(cell.modelData)
            }
        }
    }

    Text {
        visible: root.cells.length === 0
        text: root.query.trim() === "" ? "No images in " + root.wallDir : "Nothing found"
        color: Theme.dim
        font.pixelSize: 12
    }
}
