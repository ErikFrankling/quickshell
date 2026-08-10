pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
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

    // Apps whose MPRIS Volume *is* their stream volume: the two are one number,
    // and writing either moves both. Only these, and by name, because the
    // property does not announce itself — Firefox reports volumeSupported just
    // the same, but its Volume is the media element's and its node does not
    // follow, so a slider that wrote it would sit there looking dead. To add
    // one, check it by hand: `playerctl -p <player> volume 0.4`, then
    // `wpctl get-volume <node id>` and see whether the node moved too.
    readonly property var mirrors: ["spotify"]

    // Spotify keeps its own idea of how loud it is and writes it onto its node
    // at the start of every track, so a slider that sets the node is undone one
    // song later, back to where it was. Setting that idea instead is the write
    // that survives the next track — and it moves the node on the way.
    function player(n) {
        const app = root.name(n).toLowerCase();
        if (!root.mirrors.includes(app))
            return null;
        return Mpris.players.values.find(p => p.volumeSupported && (p.desktopEntry.toLowerCase() === app || p.identity.toLowerCase() === app)) ?? null;
    }

    function setVolume(n, v) {
        const p = root.player(n);
        if (p)
            p.volume = v;
        else if (n?.audio)
            n.audio.volume = v;
    }

    // A node reports nothing until something tracks it, and `properties` is
    // not even valid until then.
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.outputs, root.inputs, root.playing, root.recording).filter(n => n)
    }
}
