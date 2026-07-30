import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// The card that appears at the bottom of the screen when the volume or the
// brightness changes, and takes itself away again.
//
// Detecting the change is the whole problem, and the answer is that there is
// nothing to detect: both values are already tracked as properties, so the
// property's own change signal *is* the event, whoever caused it — a media
// key, wpctl, brightnessctl, pavucontrol, this shell's own slider. whisker
// watches its pipewire sink exactly this way (windows/osdpanel/VolumeOsd.qml)
// and caelestia watches its Audio singleton (modules/osd/Wrapper.qml). Nothing
// here polls, and nothing here has to be told.
//
// What that idiom gets wrong on its own is startup. Both properties step off a
// placeholder onto their real value a moment after the shell loads, and a step
// is a step: the OSD would flash on every launch and every hot reload. cxOrz
// answers it with a flag a timer flips (modules/osd/VolumeOsd.qml:22), Ricelin
// with a -1 sentinel on the first backlight reading (Singletons/Backlight.qml:29).
// Volume needs the timer, because 0 is a real volume and no sentinel can stand
// for "not read yet". Brightness needs the sentinel as well as the timer,
// because Sys does not start polling until Caps has finished probing and that
// can land either side of the timer.
Scope {
    id: root

    property bool shown: false
    property string kind: "volume"

    // Nothing shows until the shell has settled into itself.
    property bool ready: false
    Timer { interval: 1500; running: true; onTriggered: root.ready = true }

    // -1 until brightness has been read once. Stepping off it is not a change.
    property int seenBright: -1

    readonly property real value: root.kind === "brightness" ? Math.max(0, Sys.brightness) / 100 : Audio.vol
    readonly property bool muted: root.kind === "volume" && Audio.muted

    readonly property string glyph: root.kind === "brightness" ? "󰃟" : root.muted ? "󰖁" : root.value > 0.5 ? "󰕾" : root.value > 0 ? "󰖀" : "󰕿"

    function flash(k) {
        if (!root.ready)
            return;
        root.kind = k;
        root.shown = true;
        away.restart();
    }

    // restart(), not start(): holding a volume key keeps one card alive for
    // longer rather than queueing a card per keypress.
    Timer { id: away; interval: 1600; onTriggered: root.shown = false }

    Connections {
        target: Audio
        function onVolChanged() { root.flash("volume"); }
        function onMutedChanged() { root.flash("volume"); }
    }

    // Gated on the capability the same way the panel's brightness slider is:
    // a machine with no backlight reports -1 forever and must never show this.
    Connections {
        target: Sys
        enabled: Sys.hasBacklight
        function onBrightnessChanged() {
            const was = root.seenBright;
            root.seenBright = Sys.brightness;
            if (was >= 0)
                root.flash("brightness");
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            // Mapped only while there is something to see, and never with an
            // input region: every click goes to whatever is underneath.
            visible: root.shown || card.opacity > 0
            anchors.bottom: true
            margins.bottom: 80
            implicitWidth: 300
            implicitHeight: 62
            color: "transparent"
            // Ignore, not a zero zone: a zero zone still gets pushed out of
            // the rail's reservation, which lands the card off centre by
            // exactly the rail's width.
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            WlrLayershell.namespace: "osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Rectangle {
                id: card

                anchors.fill: parent
                radius: Theme.radiusS + 2
                color: Qt.alpha(Theme.bgAlt, Theme.panelOpacity)

                opacity: root.shown ? 1 : 0
                scale: root.shown ? 1 : 0.94
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.pad
                    spacing: 12

                    Text {
                        text: root.glyph
                        color: root.muted ? Theme.bad : Theme.accent
                        font.pixelSize: 17
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 7
                        radius: 4
                        color: Theme.bgHi

                        // Muted leaves the bar where it is and drains the
                        // colour out of it, so it never reads as volume zero.
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, root.value))
                            height: parent.height
                            radius: parent.radius
                            color: root.muted ? Theme.dim : Theme.accent
                            Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 110 } }
                        }
                    }

                    Text {
                        text: Math.round(root.value * 100) + "%"
                        color: root.muted ? Theme.dim : Theme.fg
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 38
                    }
                }
            }
        }
    }
}
