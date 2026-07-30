pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Colour lives here and nowhere else. The palette is read from a state file so
// the theme picker can change it at runtime; the values below are the fallback
// when that file does not exist yet.
Singleton {
    id: root

    property var palette: ({})

    function c(key, fallback) {
        return root.palette[key] ?? fallback;
    }

    readonly property color bg: c("bg", "#16181d")
    readonly property color bgAlt: c("bgAlt", "#1d2027")
    readonly property color bgHi: c("bgHi", "#252932")
    readonly property color line: c("line", "#2c313b")
    readonly property color fg: c("fg", "#d3dae3")
    readonly property color dim: c("dim", "#7c8796")
    readonly property color accent: c("accent", "#7aa2f7")
    readonly property color good: c("good", "#9ece6a")
    readonly property color warn: c("warn", "#e0af68")
    readonly property color bad: c("bad", "#f7768e")

    readonly property string name: c("name", "Tokyo Night")

    readonly property int rail: 58
    readonly property int panel: 430
    readonly property int radius: 20
    readonly property int radiusS: 10
    readonly property int pad: 14
    readonly property real panelOpacity: 0.82

    function heat(pct) {
        return pct >= 90 ? bad : pct >= 70 ? warn : accent;
    }

    function apply(p) {
        root.palette = p;
        store.setText(JSON.stringify(p));
    }

    FileView {
        id: store
        path: Quickshell.statePath("theme.json")
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.palette = JSON.parse(text());
            } catch (e) {}
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => store.setText("{}"));
        }
    }
}
