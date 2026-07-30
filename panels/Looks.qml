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

    readonly property var themes: [
        { name: "Tokyo Night", fav: true, p: { bg: "#16181d", bgAlt: "#1d2027", bgHi: "#252932", line: "#2c313b", fg: "#d3dae3", dim: "#7c8796", accent: "#7aa2f7", good: "#9ece6a", warn: "#e0af68", bad: "#f7768e" } },
        { name: "Gruvbox", fav: true, p: { bg: "#1d2021", bgAlt: "#282828", bgHi: "#32302f", line: "#3c3836", fg: "#ebdbb2", dim: "#928374", accent: "#d79921", good: "#b8bb26", warn: "#fabd2f", bad: "#fb4934" } },
        { name: "Catppuccin Mocha", fav: true, p: { bg: "#1e1e2e", bgAlt: "#26263a", bgHi: "#313244", line: "#45475a", fg: "#cdd6f4", dim: "#7f849c", accent: "#89b4fa", good: "#a6e3a1", warn: "#f9e2af", bad: "#f38ba8" } },
        { name: "Nord", fav: false, p: { bg: "#2e3440", bgAlt: "#343b4a", bgHi: "#3b4252", line: "#434c5e", fg: "#eceff4", dim: "#7b88a1", accent: "#88c0d0", good: "#a3be8c", warn: "#ebcb8b", bad: "#bf616a" } },
        { name: "Rosé Pine", fav: false, p: { bg: "#191724", bgAlt: "#1f1d2e", bgHi: "#26233a", line: "#403d52", fg: "#e0def4", dim: "#908caa", accent: "#c4a7e7", good: "#9ccfd8", warn: "#f6c177", bad: "#eb6f92" } },
        { name: "Everforest", fav: false, p: { bg: "#2d353b", bgAlt: "#343f44", bgHi: "#3d484d", line: "#475258", fg: "#d3c6aa", dim: "#859289", accent: "#a7c080", good: "#a7c080", warn: "#dbbc7f", bad: "#e67e80" } },
        { name: "Kanagawa", fav: false, p: { bg: "#1f1f28", bgAlt: "#2a2a37", bgHi: "#363646", line: "#54546d", fg: "#dcd7ba", dim: "#727169", accent: "#7e9cd8", good: "#98bb6c", warn: "#e6c384", bad: "#e82424" } }
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
        if (cell.id === "") {
            root.setWall(cell.full);
            return;
        }
        const dest = root.wallDir + "/wallhaven-" + cell.id +
            (cell.full.toLowerCase().endsWith(".png") ? ".png" : ".jpg");
        root.busy = true;
        dl.dest = dest;
        dl.command = ["sh", "-c",
            "mkdir -p " + JSON.stringify(root.wallDir) +
            " && { [ -s " + JSON.stringify(dest) + " ] || curl -fsSL --max-time 90 -o " +
            JSON.stringify(dest) + " " + JSON.stringify(cell.full) + "; }"];
        dl.running = true;
    }

    // Start hyprpaper if it is not already up, then set the image. It ships in
    // this flake, so it is on PATH whether or not the system config has it.
    function setWall(path) {
        root.current = path;
        wallProc.command = ["sh", "-c",
            "pgrep -x hyprpaper >/dev/null || (hyprpaper &); sleep 0.3; " +
            "hyprctl hyprpaper preload '" + path + "'; " +
            "hyprctl hyprpaper wallpaper \",'" + path + "'\""];
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
                        model: [card.modelData.p.accent, card.modelData.p.good,
                                card.modelData.p.warn, card.modelData.p.bad]
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

        delegate: Item {
            id: cell
            required property var modelData
            width: GridView.view.cellWidth
            height: GridView.view.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
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
    }

    Text {
        visible: root.cells.length === 0
        text: root.query.trim() === "" ? "No images in " + root.wallDir : "Nothing found"
        color: Theme.dim
        font.pixelSize: 12
    }
}
