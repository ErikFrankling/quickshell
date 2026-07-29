import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root
    spacing: Theme.pad

    // Nothing reports volume until it is tracked.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
            .concat(Pipewire.nodes.values.filter(n => n.isStream))
    }

    Text {
        text: "Audio"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Bar {
        glyph: "󰕾"
        label: "Output"
        value: Pipewire.defaultAudioSink?.audio?.volume ?? 0
        onMoved: v => { if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = v; }
    }

    Bar {
        glyph: "󰍬"
        label: "Input"
        value: Pipewire.defaultAudioSource?.audio?.volume ?? 0
        onMoved: v => { if (Pipewire.defaultAudioSource?.audio) Pipewire.defaultAudioSource.audio.volume = v; }
    }

    Text {
        text: "Output devices"
        color: Theme.dim
        font.pixelSize: 11
        Layout.topMargin: 6
    }

    Repeater {
        model: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
        Entry {
            required property var modelData
            glyph: "󰓃"
            label: modelData.description || modelData.name
            on: Pipewire.defaultAudioSink === modelData
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    Text {
        text: "Per application"
        color: Theme.dim
        font.pixelSize: 11
        Layout.topMargin: 6
    }

    Repeater {
        model: Pipewire.nodes.values.filter(n => n.isStream && n.isSink)
        ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            Bar {
                glyph: "󰝚"
                label: modelData.properties["application.name"] ?? modelData.name
                value: modelData.audio?.volume ?? 0
                onMoved: v => { if (modelData.audio) modelData.audio.volume = v; }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
