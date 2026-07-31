import QtQuick

// Sparkline for the monitor panel. Filled area under the line so a glance reads
// as "how loaded", not "what exact number". A second series draws on the same
// axes, which is how network down and up belong together.
//
// Two things here are about not lying rather than about looks.
//
// The first is the ceiling. A curve with no scale says nothing: the same
// mountain is 20 KB/s or 200 MB/s and the shape cannot tell you which. So the
// top of the plot is drawn as a line and labelled with the value it stands for,
// and the label is derived from the same number the curve is drawn against —
// they cannot disagree. Percentages and temperature keep a fixed ceiling
// because 100 is meaningful for both; rates have no natural top, so they scale
// to what is in the window, and `max` becomes a floor that keeps an idle link
// from being drawn as a busy one.
//
// The second is that the scale is *snapped*. Scaling straight to the window's
// peak re-scales the whole curve on almost every sample — a 1.7M peak followed
// by a 1.9M one moves every pixel of a graph that has barely changed, which is
// the flicker Erik was seeing. Snapping the ceiling up to a power of two (or to
// 1/2/5 for counted units) means the axis only moves when the data crosses a
// real boundary, and when it does move, it moves to a number worth printing.
//
// The horizontal step is fixed at `span` slots for the same reason. Dividing
// the width by however many samples happen to have arrived stretches the whole
// history sideways on every tick until the buffer is full — which is the state
// the panel is in for two minutes after every config reload. A fixed step lets
// a short history grow in from the right instead, newest always at the edge.
Item {
    id: root

    property var values: []
    property var values2: []
    property color tint: Theme.accent
    property color tint2: Theme.good
    property string label: ""
    property string readout: ""

    // How many sample slots wide the plot is, whether or not that many samples
    // have arrived yet.
    property int span: 60

    // Percentages share one axis. Bytes per second and rpm do not, so those
    // autoscale and `max` becomes a floor that keeps idle from looking busy.
    property real max: 100
    property bool autoscale: false

    // What the ceiling counts, and therefore how it is printed: "%", "B/s",
    // "°C", "rpm".
    property string unit: "%"

    readonly property real peak: {
        let p = 0;
        for (const v of (root.values || []))
            if (v > p) p = v;
        for (const v of (root.values2 || []))
            if (v > p) p = v;
        return p;
    }

    readonly property real ceiling: autoscale ? Math.max(max, root.snap(peak)) : max

    // Bytes climb by doubling, so a byte ceiling snaps to a power of two and
    // prints exactly — 256K, 512K, 1.0M. Everything else snaps to 1, 2 or 5
    // times a power of ten, which is how a person reads a fan or a count.
    function snap(v) {
        if (!(v > 0))
            return 0;
        if (root.unit === "B/s") {
            let e = 1;
            while (e < v)
                e *= 2;
            return e;
        }
        const e = Math.pow(10, Math.floor(Math.log(v) / Math.LN10));
        const m = v / e;
        return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 5 ? 5 : 10) * e;
    }

    readonly property string ceilingText: root.unit === "B/s"
        ? Sys.human(root.ceiling) + "/s"
        : root.unit === "%" || root.unit === "°C"
            ? Math.round(root.ceiling) + root.unit
            : Math.round(root.ceiling) + " " + root.unit

    // Clear of the label row; the plot is what is left under it.
    readonly property int plotTop: 17

    implicitHeight: 60

    // The ceiling, drawn where it is measured from. A number without the line
    // is a number about nothing.
    Rectangle {
        x: 0
        y: root.plotTop
        width: parent.width
        height: 1
        color: Theme.line
    }

    Canvas {
        id: c
        anchors.fill: parent

        function curve(ctx, v, colour) {
            if (!v || v.length < 2)
                return;
            const step = width / Math.max(1, root.span - 1);
            // Newest on the right, so a half-full history grows in from the
            // edge rather than stretching to fill.
            const x0 = width - (v.length - 1) * step;
            const y = i => height - Math.max(0, Math.min(1, v[i] / root.ceiling)) * (height - root.plotTop - 2) - 2;

            ctx.beginPath();
            ctx.moveTo(x0, height);
            for (let i = 0; i < v.length; i++)
                ctx.lineTo(x0 + i * step, y(i));
            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fillStyle = Qt.alpha(colour, 0.16);
            ctx.fill();

            ctx.beginPath();
            for (let i = 0; i < v.length; i++)
                i ? ctx.lineTo(x0 + i * step, y(i)) : ctx.moveTo(x0, y(0));
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

    // Canvas does not repaint on property change by itself. The colours are on
    // this list as well as the data: Theme.heat() answers differently as a
    // value climbs and the whole palette changes when the theme does, and a
    // canvas that only listens to its numbers keeps the old colour until the
    // next sample happens to land.
    onValuesChanged: c.requestPaint()
    onValues2Changed: c.requestPaint()
    onCeilingChanged: c.requestPaint()
    onSpanChanged: c.requestPaint()
    onTintChanged: c.requestPaint()
    onTint2Changed: c.requestPaint()

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
        // Tabular figures: a readout that changes every two seconds must not
        // re-flow every two seconds. Proportional digits make "13.5" and
        // "13.9" different widths, and a right-anchored string then twitches
        // sideways on every sample — the same defect the rail clock had.
        font.features: ({ "tnum": 1 })
    }

    // What the top of the plot is worth.
    Text {
        x: 0
        y: root.plotTop + 1
        text: root.ceilingText
        color: Theme.dim
        font.pixelSize: 9
        font.features: ({ "tnum": 1 })
    }
}
