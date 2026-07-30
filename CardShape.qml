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
//
// Either inverted corner can be squared off, and that is what happens when the
// card is against a screen edge. A flare is drawn a whole radius *outside* the
// card, so a card sitting flush to the top or bottom of the screen has nowhere
// to put one: the choice is to cut the curve, to hold the card a radius clear
// of the edge and leave a sliver of wallpaper under it, or to admit that a
// surface running into the end of the screen does not have a corner there. The
// third is the honest one and it is what this does. The two ordinary corners
// away from the rail are never squared — they are the card's own outline
// against the desktop and there is always room for them.
//
// Sixteen shells were read for this and none of them does it, so the rule is
// ours. What exists elsewhere is two halves of it. noctalia is the only project
// that derives corner shape from where a panel actually ended up —
// `touchingLeftEdge: panelBackground.x <= 1` and its three siblings
// (SmartPanel.qml:823-826) feed four per-corner blocks (:1166-1297) that re-run
// after the clamp — but those blocks only ever return normal or inverted, never
// square, so a noctalia panel against a screen edge grows a concave corner
// rather than losing one. Its renderer would draw square today: PanelBackground
// .qml:70 maps state -1 to a 0.01px radius, which is the same epsilon this file
// uses and for the same reason, that a true zero folds the triangulator.
// Everyone else hard-codes the edge instead of detecting it — Brainitech's
// src/shapes/PopupShape.qml takes an `attachedEdge` string and its
// "bottom-right" case squares exactly the corner the screen border covers,
// Zaphkiel's Layers/Notch.qml squares the two corners that touch the top of the
// screen, and vast-shell's drawers each round only their two inward corners.
// That is the same picture, drawn by an author who knew in advance which edge
// the panel would live on. A card that follows a button up and down a rail does
// not know, so it has to work it out, and nothing found does both halves.
//
// Every other clamp read was silent: position moves, shape does not. bjarneo is
// the only author who treats a clamp as visually meaningful at all, and what he
// moves is the scale origin so the card still grows out of the icon that opened
// it (desktop/CardWindow.qml:88-99, :110).
Shape {
    id: root

    // The card's size, in the parent's coordinates. This item positions itself.
    property real cardWidth: 0
    property real cardHeight: 0
    property color fill: Theme.bg
    property real corner: Theme.radius

    // Set when the card is flush against that screen edge, so the fillet on it
    // has no room and the card should meet the edge square instead.
    property bool squareTop: false
    property bool squareBottom: false

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

    // The two inverted corners, which are the ones that can be squared. A
    // squared one keeps the same epsilon floor rather than dropping the arc
    // from the path: the outline stays one loop with the same eight elements
    // whatever the card is doing, and 0.01px of curve is no curve.
    readonly property real invTop: root.squareTop ? 0.01 : root.rad
    readonly property real invBot: root.squareBottom ? 0.01 : root.rad

    // An inverted corner is drawn outside the card, so the shape is grown by
    // the radius at each end that still has one. Left and right stay put:
    // inverting on the Y axis carries the fill along the rail, not across it.
    x: -overlap
    y: -invTop
    implicitWidth: cardWidth + overlap
    implicitHeight: cardHeight + invTop + invBot

    visible: cardWidth > 0 && cardHeight > 0
    preferredRendererType: Shape.CurveRenderer

    // The card's edges in this item's coordinates. Its left edge is 0: the path
    // is drawn a whole `overlap` wider than the card so it tucks under the rail.
    readonly property real xRight: cardWidth + overlap
    readonly property real yTop: invTop
    readonly property real yBot: invTop + cardHeight

    ShapePath {
        fillColor: root.fill
        strokeWidth: -1

        startX: root.invTop
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
        PathLine { x: root.invBot; y: root.yBot }

        // Bottom left, inverted: the fill carries on *past* the card's bottom
        // edge until it reaches the rail, so the sweep runs the other way.
        // Squared against the bottom of the screen, this collapses and the
        // bottom edge simply runs into the rail.
        PathArc {
            x: 0; y: root.yBot + root.invBot
            radiusX: root.invBot; radiusY: root.invBot
            direction: PathArc.Counterclockwise
        }

        // The rail edge, longer than the card by the radius at each end that
        // still curves.
        PathLine { x: 0; y: root.yTop - root.invTop }

        // Top left, inverted, and it lands exactly on startX/startY, so the
        // path closes on itself with nothing left over.
        PathArc {
            x: root.invTop; y: root.yTop
            radiusX: root.invTop; radiusY: root.invTop
            direction: PathArc.Counterclockwise
        }
    }
}
