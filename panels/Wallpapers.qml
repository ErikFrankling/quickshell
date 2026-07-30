import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// What is on disk, and wallhaven's catalogue, in the same grid. Browsing needs
// no API key and no typing: "Browse online" opens on wallhaven's monthly
// toplist, so the popular wallpapers are one click away. Anonymous search is
// capped at 45 requests a minute and pages 24 at a time.
ColumnLayout {
    id: root
    spacing: 8

    // Downloads land beside the local ones, so a wallpaper joins the list the
    // moment it finishes. A real directory, not a cache — it is synced between
    // his machines, by the syncthing folder named `wallpapers` in the NixOS
    // config, which must point at this exact path and nowhere else. When the
    // two disagree the grid is empty while the disk is full, so the empty
    // state below says out loud which directory it looked in.
    readonly property string dir: Quickshell.env("HOME") + "/Pictures/wallpapers"

    // The same path with $HOME folded back to a tilde, for showing a human.
    readonly property string dirLabel: "~" + root.dir.slice(Quickshell.env("HOME").length)

    property list<string> walls: []
    property string current: ""
    property bool online: false
    property string query: ""
    property var hits: []
    property int page: 1
    property int pages: 1
    property bool busy: false
    property string note: ""

    // Off unless asked for: the hand-picked themes stay the way to choose
    // colours, and this is the toy next to them.
    readonly property string pick: root.current !== "" ? root.current : (root.walls[0] ?? "")

    readonly property var cells: root.online
        ? root.hits
        : root.walls.map(w => ({ thumb: "file://" + w, full: w, id: "" }))

    component Pill: Rectangle {
        id: pill
        property alias label: t.text
        property bool on: false
        property bool live: true
        signal clicked

        implicitWidth: t.implicitWidth + 20
        implicitHeight: 26
        radius: 13
        opacity: pill.live ? 1 : 0.3
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
            onClicked: if (pill.live) pill.clicked()
        }
    }

    // Newest first, so something just downloaded is at the top of the grid.
    Process {
        id: scan
        running: true
        command: ["sh", "-c", "ls -1t " + root.dir + "/*.jpg " + root.dir + "/*.jpeg " + root.dir + "/*.png 2>/dev/null | head -60"]
        stdout: StdioCollector {
            onStreamFinished: root.walls = text.trim().split("\n").filter(s => s !== "")
        }
    }

    Process { id: wallProc }

    Process {
        id: fetch
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                try {
                    const r = JSON.parse(text);
                    root.pages = r.meta.last_page || 1;
                    root.hits = r.data.map(d => ({ thumb: d.thumbs.small, full: d.path, id: d.id }));
                    root.note = r.data.length === 0 ? "Nothing found" : "";
                } catch (e) {
                    root.hits = [];
                    root.note = "wallhaven unreachable, or over 45 requests/min";
                }
            }
        }
    }

    Process {
        id: dl
        property string dest: ""
        onExited: code => {
            root.busy = false;
            if (code === 0) {
                root.setWall(dl.dest);
                scan.running = true;
            } else {
                root.note = "Download failed";
            }
        }
    }

    Timer {
        id: debounce
        interval: 350
        onTriggered: root.search(1)
    }
    onQueryChanged: if (root.online) debounce.restart()

    // An empty box is not an empty result: it is wallhaven's monthly toplist,
    // which is the whole point of a browse button.
    function search(p) {
        root.page = Math.max(1, p);
        root.busy = true;
        const q = root.query.trim();
        fetch.running = false;
        fetch.command = ["curl", "-fsS", "--max-time", "20",
            "https://wallhaven.cc/api/v1/search?categories=100&purity=100" +
            "&atleast=1920x1080&page=" + root.page +
            (q === "" ? "&sorting=toplist&topRange=1M"
                      : "&sorting=relevance&q=" + encodeURIComponent(q))];
        fetch.running = true;
    }

    function pick(cell) {
        if (cell.id === "") {
            root.setWall(cell.full);
            return;
        }
        const dest = root.dir + "/wallhaven-" + cell.id +
            (cell.full.toLowerCase().endsWith(".png") ? ".png" : ".jpg");
        root.busy = true;
        root.note = "";
        dl.dest = dest;
        dl.command = ["sh", "-c", "mkdir -p " + JSON.stringify(root.dir) +
            " && { [ -s " + JSON.stringify(dest) + " ] || curl -fsSL --max-time 120 -o " +
            JSON.stringify(dest) + " " + JSON.stringify(cell.full) + "; }"];
        dl.running = true;
    }

    // Start hyprpaper if it is not already up, then set the image. It ships in
    // this flake, so it is on PATH whether or not the system config has it.
    // hyprpaper 0.8 dropped `preload` and no longer wants the path quoted.
    function setWall(path) {
        root.current = path;
        if (matcher.on)
            matcher.derive(path);
        wallProc.running = false;
        wallProc.command = ["sh", "-c",
            "pgrep -x hyprpaper >/dev/null || { setsid hyprpaper >/dev/null 2>&1 & sleep 1; }; " +
            "hyprctl hyprpaper wallpaper " + JSON.stringify("," + path)];
        wallProc.running = true;
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            text: "Wallpaper"
            color: root.busy ? Theme.accent : Theme.dim
            font.pixelSize: 11
            Layout.fillWidth: true
        }
        Pill {
            label: "On disk"
            on: !root.online
            onClicked: root.online = false
        }
        Pill {
            label: root.busy ? "Loading …" : "Browse online"
            on: root.online
            onClicked: {
                root.online = true;
                if (root.hits.length === 0)
                    root.search(1);
            }
        }
    }

    Rectangle {
        visible: root.online
        Layout.fillWidth: true
        implicitHeight: 32
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
                text: "Search wallhaven, or browse the toplist"
                color: Theme.dim
                font.pixelSize: 12
            }
        }
    }

    GridView {
        id: grid
        Layout.fillWidth: true
        // A real height, and a constant one. The panel sizes itself to its
        // content, so fillHeight leaves the grid a clipped sliver — and a
        // height derived from cellHeight cannot be used either, because
        // cellHeight comes from the width the layout has not worked out yet.
        Layout.preferredHeight: 250
        clip: true
        cellWidth: Math.floor(width / 3)
        cellHeight: Math.round(cellWidth * 9 / 16)

        // A plain array here segfaults quickshell when an entry goes away.
        model: ScriptModel { values: root.cells }

        delegate: Rectangle {
            id: cell
            required property var modelData

            width: grid.cellWidth - 6
            height: grid.cellHeight - 6
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
                cache: true
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.pick(cell.modelData)
            }
        }
    }

    RowLayout {
        visible: root.online && root.pages > 1
        Layout.fillWidth: true
        spacing: 6

        Pill {
            label: "‹"
            live: root.page > 1 && !root.busy
            onClicked: root.search(root.page - 1)
        }
        Text {
            text: root.page + " / " + root.pages
            color: Theme.dim
            font.pixelSize: 11
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
        Pill {
            label: "›"
            live: root.page < root.pages && !root.busy
            onClicked: root.search(root.page + 1)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            text: "Match theme to wallpaper"
            color: Theme.dim
            font.pixelSize: 11
            Layout.fillWidth: true
        }
        Pill {
            label: matcher.on ? "On" : "Off"
            on: matcher.on
            live: root.pick !== ""
            onClicked: matcher.toggle(root.pick)
        }
    }

    WallMatch {
        id: matcher
        onFailed: root.note = "No colours could be read from that image"
    }

    Text {
        visible: text !== ""
        text: root.note !== "" ? root.note
            : root.cells.length === 0 && !root.online
                ? "Nothing in " + root.dirLabel + " — try Browse online"
            : ""
        color: Theme.dim
        font.pixelSize: 11
    }
}
