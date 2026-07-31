import QtQuick
import QtQuick.Layouts

// A metric as a filled ring: fuller and hotter the closer to the limit.
Item {
    id: root

    property string label: ""
    property real value: 0        // 0..100
    property string text: ""      // centre text; defaults to rounded value

    // What the colour is keyed off, when that is not the fill. Battery is the
    // one metric here where a full ring is the good news, so it hands over
    // 100 - charge and goes red on the way to empty rather than on the way up.
    property real heat: value

    // Where the metric stops being fine and where it stops being survivable,
    // in heat's terms — so a ring that names neither lights exactly where
    // Theme.heat already turned the arc, and a ring that means something else
    // by "full" says so once, at the call site, in the units it is read in.
    property real warnAt: 70
    property real critAt: 90

    // Waybar's `states`, which is where this whole idea comes from: a pair of
    // thresholds in the module config puts a .warning or .critical class on the
    // widget, and the stylesheet then colours *the module* rather than only its
    // text (his config.jsonc:50-53 for the battery, style.css:101-107 for what
    // that does). Here that is a wash over the ring's own ground.
    readonly property int level: heat >= critAt ? 2 : heat >= warnAt ? 1 : 0
    readonly property color tone: level === 2 ? Theme.bad
                                : level === 1 ? Theme.warn : Theme.accent

    // Blinking is opt-in and only two rings ask for it. His waybar is the same:
    // #battery is given an animation-name and #memory is not — it carries the
    // timing properties and never gets a keyframe to run (style.css:135-147) —
    // so memory colours and holds still. The reason is his: a flash he cannot
    // answer is a flash he teaches himself to ignore.
    property bool blink: false

    // And waybar's period, exactly: animation-duration 3s warning, 2s critical,
    // animation-direction alternate (style.css:109-117), so one full breath is
    // six seconds and four. The animation drives a plain scalar rather than the
    // colour, because an animation attached to a property owns it — binding the
    // wash to `pulse` instead keeps the colour a binding, and lets the ring go
    // back to a steady wash the instant the blinking stops.
    property real pulse: 1

    SequentialAnimation on pulse {
        id: breath

        running: root.blink && root.level > 0
        loops: Animation.Infinite
        NumberAnimation {
            to: 0.15
            duration: root.level === 2 ? 2000 : 3000
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 1
            duration: root.level === 2 ? 2000 : 3000
            easing.type: Easing.InOutSine
        }
    }

    Layout.alignment: Qt.AlignHCenter
    // One rail slot, like every other control on the rail. The caption below is
    // the one thing on the rail that lives outside its slot: it is a label on
    // the ring rather than a control of its own, so it hangs into the gap under
    // it and the rings group is given a wider gap to carry it.
    implicitWidth: Theme.slot
    implicitHeight: Theme.slot

    // The wash. 18% and 24% are as much of it as the number standing on top can
    // afford: measured across all 335 schemes the shell ships, the median cost
    // to the number's contrast is 22%, and on the three he actually uses it
    // lands at 3.7/4.3 (Gruvbox dark, from 5.1), 3.5/3.7 (Everforest, from 4.8)
    // and 7.7/6.1 (One Light, from 9.0). A previous attempt at this washed hard
    // enough to leave the number at 1.3:1, which is not dim, it is gone.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Qt.alpha(root.tone, root.level === 0 ? 0
            : (root.level === 2 ? 0.24 : 0.18) * (breath.running ? root.pulse : 1))
    }

    Canvas {
        id: c
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            const w = width, r = w / 2 - 2.5;
            ctx.reset();
            ctx.lineWidth = 3;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.arc(w / 2, w / 2, r, 0, Math.PI * 2);
            ctx.strokeStyle = Theme.line;
            ctx.stroke();

            const frac = Math.max(0, Math.min(1, root.value / 100));
            if (frac > 0) {
                ctx.beginPath();
                // start at 12 o'clock
                ctx.arc(w / 2, w / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * frac);
                ctx.strokeStyle = root.tone;
                ctx.stroke();
            }
        }
    }

    // Canvas does not repaint on property change by itself.
    onValueChanged: c.requestPaint()
    onToneChanged: c.requestPaint()

    Text {
        anchors.centerIn: parent
        text: root.text !== "" ? root.text : Math.round(root.value)
        color: Theme.fg
        font.pixelSize: 10
        font.weight: Font.DemiBold
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: -1
        text: root.label
        color: Theme.dim
        font.pixelSize: 8
    }
}
