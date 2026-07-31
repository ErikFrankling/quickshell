import QtQuick

// The ground under a rail control, which says whether that control's panel is
// showing.
//
// Five things on the rail open a panel — the metrics block, the player, wifi,
// bluetooth and the clock — and this is the one drawing that says which of them
// is up. It belonged to the metrics block alone first; Erik asked for the same
// state on the other four, so it moved here rather than being typed out five
// times.
//
// Two channels, and the split between them is the whole point. The *ground*
// barely moves: a 12% accent wash over whatever colour the control already
// rests at, which is a 4.3 to 8.0 step in CIE L* across the nine curated
// schemes — as big as the hover on the ones where hover is quietest (Gruvbox
// steps 6.2 against a 3.8 hover) and never under the 4.0 the pill survey draws
// its floor at. The *edge* does the talking: a 1px hairline in the accent, 38
// to 58 dL against the ground it is drawn on.
//
// Flooding the control with solid accent instead is what this replaces, and the
// reason the wash is a tenth of a step and not a half. Content on its own accent
// is 1.2 to 1.9:1 — that is what made the metric numbers illegible, and it is
// why the padlock on the wifi button had to be repainted in Theme.bg to survive
// at all, at 1.0:1 on Everforest before it was. A 12% wash costs the content
// about half a point of contrast and costs the reading nothing.
//
// The resting colour is passed in, because the five grounds are not the same
// colour: the metrics block *is* the group's ground, a radio button is a disc
// one step below it, and the clock and the player rest on the group's ground
// without drawing one of their own. It has to be an opaque colour if `on` can
// ever be true — Qt.tint blends a zero-alpha base in as if it were opaque and
// then keeps the tint's alpha, so washing nothing yields a wash of 1.4%.
Rectangle {
    id: root

    // This control's panel is the one showing.
    property bool on: false

    // What the control rests at when it is neither open nor under the pointer.
    // The default is the ground a Group draws, which is what the clock and the
    // player stand on: painting bgHi over bgHi is how a control that has no
    // ground of its own gets one only while it is open, without ever going
    // through "transparent" — transparent is transparent *black*, and a
    // ColorAnimation through it washes the control dark on the way in.
    property color ground: Theme.bgHi

    // Whether the pointer is on it. Off by default: the clock and the player
    // have never lit under the pointer, and this is not the change that gives
    // them that.
    property bool hovering: false

    radius: Theme.radiusS
    color: root.on ? Qt.tint(root.ground, Qt.alpha(Theme.accent, 0.12))
         : root.hovering ? Theme.line
         : root.ground
    // Drawn inside the rectangle rather than around it, so switching it on
    // costs the control no width and the rail no height.
    border.width: root.on ? 1 : 0
    border.color: Theme.accent

    Behavior on color { ColorAnimation { duration: 110 } }
}
