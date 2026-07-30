import QtQuick

// Sparkline for the monitor panel. Filled area under the line so a glance reads
// as "how loaded", not "what exact number". A second series draws on the same
// axes, which is how network down and up belong together.
Item {
    id: root

    property var values: []
    property var values2: []
    property color tint: Theme.accent
    property color tint2: Theme.good
    property string label: ""
    property string readout: ""

    // Percentages share one axis. Bytes per second and rpm do not, so those
    // autoscale and `max` becomes a floor that keeps idle from looking busy.
    property real max: 100
    property bool autoscale: false

    readonly property real ceiling: autoscale
        ? Math.max(max, ...(values || []), ...(values2 || []))
        : max

    implicitHeight: 60

    Canvas {
        id: c
        anchors.fill: parent

        function curve(ctx, v, colour) {
            if (!v || v.length < 2)
                return;
            const step = width / (v.length - 1);
            const top = 17;                       // clear of the label row
            const y = i => height - Math.max(0, Math.min(1, v[i] / root.ceiling)) * (height - top - 2) - 2;

            ctx.beginPath();
            ctx.moveTo(0, height);
            for (let i = 0; i < v.length; i++)
                ctx.lineTo(i * step, y(i));
            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fillStyle = Qt.alpha(colour, 0.16);
            ctx.fill();

            ctx.beginPath();
            for (let i = 0; i < v.length; i++)
                i ? ctx.lineTo(i * step, y(i)) : ctx.moveTo(0, y(0));
            ctx.strokeStyle = colour;
            ctx.lineWidth = 1.6;
            ctx.stroke();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            curve(ctx, root.values, root.tint);
            curve(ctx, root.values2, root.tint2);
        }
    }

    // Canvas does not repaint on property change by itself.
    onValuesChanged: c.requestPaint()
    onValues2Changed: c.requestPaint()
    onCeilingChanged: c.requestPaint()

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
