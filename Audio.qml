pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Volume state, tracked once here so the rail glyph and the panel agree.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    // Pipewire hands out one flat list of nodes. A device is something you
    // pick, a stream is a program making noise; sink is the way the audio
    // flows. Those two flags are the whole taxonomy.
    function pick(isSink, isStream) {
        return Pipewire.nodes.values.filter(n => n.audio && n.isSink === isSink && n.isStream === isStream);
    }

    readonly property var outputs: root.pick(true, false)
    readonly property var inputs: root.pick(false, false)
    readonly property var playing: root.pick(true, true)
    readonly property var recording: root.pick(false, true)

    // application.name for a stream, the description for a device — the
    // nickname is often just the chipset ("USB Audio Device").
    function name(n) {
        return n?.properties["application.name"] ?? n?.description ?? n?.nickname ?? n?.name ?? "";
    }

    // A node reports nothing until something tracks it, and `properties` is
    // not even valid until then.
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.outputs, root.inputs, root.playing, root.recording).filter(n => n)
    }
}
