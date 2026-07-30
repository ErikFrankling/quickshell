import QtQuick
import QtQuick.Layouts

// A metric as a filled ring: fuller and hotter the closer to the limit.
Item {
    id: root

    property string label: ""
    property real value: 0        // 0..100
    property string text: ""      // centre text; defaults to rounded value

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: 30
    implicitHeight: 30

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
                ctx.strokeStyle = Theme.heat(root.value);
                ctx.stroke();
            }
        }
    }

    // Canvas does not repaint on property change by itself.
    onValueChanged: c.requestPaint()

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
