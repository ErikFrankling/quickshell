import QtQuick
import QtQuick.Shapes

// The Noctalia detail: where the panel meets the rail, the corner curves the
// wrong way, so the two surfaces read as one carved shape instead of two
// rectangles pushed together.
Shape {
    id: root

    // Which way the fillet bites: "tl", "tr", "bl", "br".
    property string corner: "tl"
    property color fill: Theme.bg
    property int size: Theme.radius

    implicitWidth: size
    implicitHeight: size
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fill
        strokeWidth: 0

        // Start at the outer corner, cut back along one edge, arc inward, and
        // close along the other edge.
        startX: root.corner === "tr" || root.corner === "br" ? root.size : 0
        startY: root.corner === "bl" || root.corner === "br" ? root.size : 0

        PathArc {
            x: root.corner === "tl" || root.corner === "bl" ? root.size : 0
            y: root.corner === "tl" || root.corner === "tr" ? root.size : 0
            radiusX: root.size
            radiusY: root.size
            direction: root.corner === "tl" || root.corner === "br"
                ? PathArc.Clockwise : PathArc.Counterclockwise
        }
        PathLine {
            x: root.corner === "tr" || root.corner === "br" ? root.size : 0
            y: root.corner === "bl" || root.corner === "br" ? root.size : 0
        }
    }
}
