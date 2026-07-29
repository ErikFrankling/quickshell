import QtQuick

// Sparkline for the monitor panel. Filled area under the line so a glance
// reads as "how loaded", not "what exact number".
Item {
    id: root

    property var values: []
    property color tint: Theme.accent
    property string label: ""
    property string readout: ""

    implicitHeight: 74

    Canvas {
        id: c
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const v = root.values;
            if (!v || v.length < 2) return;

            const step = width / (v.length - 1);
            const y = i => height - (Math.max(0, Math.min(100, v[i])) / 100) * (height - 4) - 2;

            ctx.beginPath();
            ctx.moveTo(0, height);
            for (let i = 0; i < v.length; i++) ctx.lineTo(i * step, y(i));
            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fillStyle = Qt.alpha(root.tint, 0.16);
            ctx.fill();

            ctx.beginPath();
            for (let i = 0; i < v.length; i++)
                i ? ctx.lineTo(i * step, y(i)) : ctx.moveTo(0, y(0));
            ctx.strokeStyle = root.tint;
            ctx.lineWidth = 1.6;
            ctx.stroke();
        }
    }

    onValuesChanged: c.requestPaint()

    Text {
        anchors { left: parent.left; top: parent.top }
        text: root.label
        color: Theme.dim
        font.pixelSize: 11
    }

    Text {
        anchors { right: parent.right; top: parent.top }
        text: root.readout
        color: Theme.fg
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }
}
