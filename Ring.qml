import QtQuick
import QtQuick.Layouts

// A metric as a filled ring: fuller and hotter the closer to the limit.
Item {
    id: root

    property string label: ""
    property real value: 0        // 0..100
    property string text: ""      // centre text; defaults to rounded value

    // The metric's name, stood on its side in the flank.
    //
    // Most rings have two things to say and two places to put them: a number in
    // the middle and a name under it. Memory and the disks have three — a name,
    // a used value and a total — and the ring's clear middle is 20px across,
    // which is three characters at the 10px the centre already uses. So the
    // third fact has to go somewhere that costs no height, and the only such
    // place left is sideways: a 28px ring on a 46px group leaves 9px down each
    // side, and until now the rail spent it on nothing.
    //
    // This is a borrowed move rather than a new one — RailClock turns the date
    // into the margin its stacked time leaves (RailClock.qml:100-118) and
    // RailPlayer turns the track title the same way (RailPlayer.qml:222-238) —
    // but it is borrowed from inside this shell, not from outside it. Six other
    // shells were read and none of them labels a *metric* with turned text:
    // rotation is reserved everywhere for long free text like a track title
    // (shub39_dotfiles/quickshell/bar/PlayingMedia.qml:67-80) or a date
    // (Rexcrazy804_Zaphkiel/dots/quickshell/kurukurubar/Widgets/CalendarView.qml:51).
    // What they do instead is stack — Ricelin puts the used value in the ring,
    // the name under it and "/ total" under that (Gakuseei_Ricelin/configs/
    // quickshell/pill/SysmonSurface.qml:244-250, 142-166), and Brainitech puts
    // the name *above* the arc with "11.2 / 16 GB" under the centre
    // (Brainitech_Brain_Shell/src/components/Speedometer.qml:4-7). Measured at
    // this rail's scale both cost 10px a ring, which is 30px of rail over the
    // three metrics that need it. The flank costs nothing. docs/surveys/
    // metric-fraction.md has all twenty-one measurements.
    //
    // Empty on every ring that has nothing to add, which is most of them.
    property string name: ""

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

    // Measured unconstrained and read back transposed, the way both the other
    // turned labels on this rail are sized. Two details are load-bearing:
    //
    // advanceWidth, not width — width is rounded down, and a turned label given
    // its own rounded-down length elides the glyph that did not fit.
    //
    // And the box is the flank, 9px, rather than the text's own line height,
    // which at 8px is 11. The three extra pixels are leading and carry no ink,
    // so letting them fall outside the box moves no glyph and keeps the label
    // inside the group's ground instead of three pixels off the edge of it.
    Item {
        visible: root.name !== ""
        anchors.right: parent.left
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 9
        implicitHeight: Math.ceil(nameMetrics.advanceWidth)

        TextMetrics { id: nameMetrics; font: nameText.font; text: root.name }

        Text {
            id: nameText
            anchors.centerIn: parent
            rotation: -90
            text: root.name
            color: Theme.dim
            font.pixelSize: 8
        }
    }
}
