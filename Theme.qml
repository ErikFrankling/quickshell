pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Colour lives here and nowhere else.
//
// A theme is a base16 palette — base00, the darkest background, through base0F
// — which is the colour format tinted-theming, pywal, matugen and a few hundred
// application templates already agree on. The names below are only this shell's
// words for particular slots; Scheme writes the same palette out in the places
// other applications look, so a theme is not just a shell theme.
//
// The palette is read from a state file so the picker can change it at runtime;
// the values below are the fallback when that file does not exist yet.
Singleton {
    id: root

    property var palette: ({})

    function c(key, fallback) {
        return root.palette[key] ?? fallback;
    }

    readonly property color bg: c("base00", "#16181d")
    readonly property color bgAlt: c("base01", "#1d2027")
    readonly property color bgHi: c("base02", "#252932")
    readonly property color line: c("base03", "#2c313b")
    readonly property color dim: c("base04", "#7c8796")
    readonly property color fg: c("base05", "#d3dae3")
    readonly property color bad: c("base08", "#f7768e")
    readonly property color warn: c("base0A", "#e0af68")
    readonly property color good: c("base0B", "#9ece6a")

    // base0D is the scheme's blue, and the accent for most of them. A theme
    // whose identity is a colour base16 keeps no slot for — Gruvbox's yellow,
    // Everforest's green — names its accent itself.
    readonly property color accent: c("accent", c("base0D", "#7aa2f7"))

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
        Scheme.publish(p);
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
