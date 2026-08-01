import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// Pipewire in the order you reach for it: the two defaults, the programs
// making noise, then the devices to send them to. Nodes are tracked in
// Audio.qml — nothing here reports a volume until they are.
//
// Every list goes through ScriptModel. Handing a Repeater a plain array
// rebuilds every delegate whenever a node appears or disappears, and doing
// that while pipewire is midway through destroying the node segfaults Qt.
ColumnLayout {
    id: root
    spacing: Theme.pad

    // Output, input and every stream are the same row, so it is written once.
    component Mix: RowLayout {
        id: mix

        property var node: null
        property string glyph: ""
        property string label: ""

        Layout.fillWidth: true
        spacing: 8

        Bar {
            glyph: mix.glyph
            label: mix.label
            value: mix.node?.audio?.volume ?? 0
            onMoved: v => {
                if (mix.node?.audio) {
                    mix.node.audio.muted = false;
                    mix.node.audio.volume = v;
                }
            }
        }

        Btn {
            Layout.alignment: Qt.AlignVCenter
            glyph: mix.node?.audio?.muted ? "󰖁" : "󰕾"
            tint: mix.node?.audio?.muted ? Theme.bad : Theme.dim
            onClicked: if (mix.node?.audio) mix.node.audio.muted = !mix.node.audio.muted
        }
    }

    Mix {
        node: Audio.sink
        glyph: "󰕾"
        label: "Output"
    }

    // No mic plugged in means no source node at all, and a capture slider
    // pinned at zero with a mute button that mutes nothing is the same lie
    // the device lists below used to tell.
    Mix {
        visible: !!Audio.source
        node: Audio.source
        glyph: "󰍬"
        label: "Input"
    }

    RowLayout {
        visible: Sys.brightness >= 0
        Layout.fillWidth: true
        spacing: 8

        Bar {
            glyph: "󰃟"
            label: "Brightness"
            value: Math.max(0, Sys.brightness) / 100
            onMoved: v => Sys.setBrightness(v)
        }

        // Stands in for the mute button so every slider ends in one place.
        Item { implicitWidth: 34 }
    }

    Text {
        text: "Applications"
        color: Theme.dim
        font.pixelSize: 11
        Layout.topMargin: 6
    }

    Text {
        visible: Audio.playing.length === 0 && Audio.recording.length === 0
        text: "Nothing playing"
        color: Theme.dim
        font.pixelSize: 12
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: ScriptModel { values: Audio.playing.concat(Audio.recording) }
            Mix {
                required property var modelData
                node: modelData
                glyph: modelData.isSink ? "󰝚" : "󰍬"
                label: Audio.name(modelData)
            }
        }
    }

    Text {
        text: "Output device"
        color: Theme.dim
        font.pixelSize: 11
        Layout.topMargin: 6
    }

    // A list of one is not a choice, and a list of none is a header over
    // nothing. Both used to render as rows you could hover and click to no
    // effect, which is what "I can't select a device" turned out to mean:
    // this machine has one sink and, until a mic is plugged in, no sources.
    Text {
        visible: Audio.outputs.length < 2
        text: Audio.outputs.length === 0 ? "No output devices"
            : "Only " + Audio.name(Audio.outputs[0])
        color: Theme.dim
        font.pixelSize: 12
    }

    ColumnLayout {
        visible: Audio.outputs.length > 1
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: ScriptModel { values: Audio.outputs }
            Entry {
                required property var modelData
                glyph: "󰓃"
                label: Audio.name(modelData)
                on: Audio.sink?.id === modelData.id
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
    }

    Text {
        text: "Input device"
        color: Theme.dim
        font.pixelSize: 11
        Layout.topMargin: 6
    }

    Text {
        visible: Audio.inputs.length < 2
        text: Audio.inputs.length === 0 ? "No input devices"
            : "Only " + Audio.name(Audio.inputs[0])
        color: Theme.dim
        font.pixelSize: 12
    }

    ColumnLayout {
        visible: Audio.inputs.length > 1
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: ScriptModel { values: Audio.inputs }
            Entry {
                required property var modelData
                glyph: "󰍬"
                label: Audio.name(modelData)
                on: Audio.source?.id === modelData.id
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }

    Item { Layout.fillHeight: true }
}
