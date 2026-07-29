pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Colours. Everything else in the shell reads from here, and only here.
    // Swap these for a base16 scheme later; nothing downstream changes.
    readonly property color bg: "#141a21"
    readonly property color bgAlt: "#1b2129"
    readonly property color line: "#28313c"
    readonly property color fg: "#c8d1dc"
    readonly property color dim: "#79848f"
    readonly property color accent: "#57c8b8"
    readonly property color warn: "#d9a441"
    readonly property color bad: "#d9706b"

    // Geometry.
    readonly property int rail: 52
    readonly property int panel: 420
    readonly property int radius: 14
    readonly property int pad: 12
}
