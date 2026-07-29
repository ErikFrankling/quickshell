pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // The only place colour lives. Point this at base16 later and nothing
    // downstream changes.
    readonly property color bg: "#16181d"
    readonly property color bgAlt: "#1d2027"
    readonly property color bgHi: "#252932"
    readonly property color line: "#2c313b"
    readonly property color fg: "#d3dae3"
    readonly property color dim: "#7c8796"
    readonly property color accent: "#7aa2f7"
    readonly property color good: "#9ece6a"
    readonly property color warn: "#e0af68"
    readonly property color bad: "#f7768e"

    // Noctalia-ish geometry: generous radius, thin rail, roomy panel.
    readonly property int rail: 54
    readonly property int panel: 430
    readonly property int radius: 20
    readonly property int radiusS: 10
    readonly property int pad: 14
    readonly property real panelOpacity: 0.82

    function heat(pct) {
        return pct >= 90 ? bad : pct >= 70 ? warn : accent;
    }
}
