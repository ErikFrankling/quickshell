pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Volume state, tracked once here so the rail glyph and the panel agree.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    // A node reports nothing until something tracks it.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }
}
