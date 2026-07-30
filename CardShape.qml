import QtQuick
import QtQuick.Shapes

// The panel card's background, drawn as a single closed path so that the two
// corners along the rail can curve the wrong way.
//
// Noctalia does not put a separate wedge at the bar/panel junction. It inverts
// the panel rectangle's *own* corner: the arc's tangent point is moved to the
// far side of the corner and the sweep is flipped, and the straight edge either
// side is lengthened by exactly the amount the arc overshoots, so the outline
// stays one simple loop. See Modules/MainScreen/Backgrounds/PanelBackground.qml
// and the XOR rule in ShapeCornerHelper.qml. That last part is the whole trick:
// an arc closed by a straight line back to its own start draws a lens, not a
// corner.
//
// Here the two corners on the rail side are inverted and the two away from it
// are ordinary, so the fill runs past the card along the rail and curves out
// into it — the rail appears to flare into the card rather than to have a card
// parked next to it.
Shape {
    id: root

    // The card's size, in the parent's coordinates. This item positions itself.
    property real cardWidth: 0
    property real cardHeight: 0
    property color fill: Theme.bg
    property real corner: Theme.radius

    // How far the left edge reaches back under the rail. Noctalia keeps one
    // pixel of overlap (SmartPanel.qml's attachmentOverlap) so no hairline of
    // background survives the seam under fractional scaling.
    property real overlap: 1

    // A radius wider than half the side it sits on would drive the straight
    // edges negative and fold the outline over itself, which matters here
    // because the card animates open from zero width. Noctalia clamps the same
    // way in getFlattenedRadius(); the floor keeps a degenerate zero-radius arc
    // out of the triangulator.
    readonly property real rad: Math.max(0.01,
        Math.min(corner, cardWidth / 2, cardHeight / 2))

    // An inverted corner is drawn outside the card, so the shape is grown by the
    // radius top and bottom. Left and right stay put: inverting on the Y axis
    // carries the fill along the rail, not across it.
    x: -overlap
    y: -rad
    implicitWidth: cardWidth + overlap
    implicitHeight: cardHeight + rad * 2

    visible: cardWidth > 0 && cardHeight > 0
    preferredRendererType: Shape.CurveRenderer

    // The card's edges in this item's coordinates. Its left edge is 0: the path
    // is drawn a whole `overlap` wider than the card so it tucks under the rail.
    readonly property real xRight: cardWidth + overlap
    readonly property real yTop: rad
    readonly property real yBot: rad + cardHeight

    ShapePath {
        fillColor: root.fill
        strokeWidth: -1

        startX: root.rad
        startY: root.yTop

        // Top edge, left to right.
        PathLine { x: root.xRight - root.rad; y: root.yTop }

        // Top right, an ordinary rounded corner.
        PathArc {
            x: root.xRight; y: root.yTop + root.rad
            radiusX: root.rad; radiusY: root.rad
            direction: PathArc.Clockwise
        }

        PathLine { x: root.xRight; y: root.yBot - root.rad }

        PathArc {
            x: root.xRight - root.rad; y: root.yBot
            radiusX: root.rad; radiusY: root.rad
            direction: PathArc.Clockwise
        }

        // Bottom edge, back to the left.
        PathLine { x: root.rad; y: root.yBot }

        // Bottom left, inverted: the fill carries on *past* the card's bottom
        // edge until it reaches the rail, so the sweep runs the other way.
        PathArc {
            x: 0; y: root.yBot + root.rad
            radiusX: root.rad; radiusY: root.rad
            direction: PathArc.Counterclockwise
        }

        // The rail edge, longer than the card by the radius at each end.
        PathLine { x: 0; y: root.yTop - root.rad }

        // Top left, inverted, and it lands exactly on startX/startY, so the
        // path closes on itself with nothing left over.
        PathArc {
            x: root.rad; y: root.yTop
            radiusX: root.rad; radiusY: root.rad
            direction: PathArc.Counterclockwise
        }
    }
}
