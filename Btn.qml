import QtQuick
import QtQuick.Layouts

// The hover ground is one rectangle that is both what you see and what the
// pointer hits: the MouseArea and the Rectangle both fill the item, so they can
// never disagree about where the button is. Every button component worth
// copying does this — noctalia's NIconButton, whisker's StyledButton, skwd's
// and doannc2212's IconButton all fill the root with the MouseArea and draw the
// ground at the same size.
//
// The ground itself is an OpenGround, which owns the resting, hover and open
// colours and the animation between them. Two things about them matter and both
// were wrong before:
//
//  * The idle colour is the hover colour at zero alpha, not "transparent".
//    "transparent" is transparent *black*, and ColorAnimation interpolates the
//    channels, so fading in from it washes the button dark before it arrives —
//    a visible flash on every enter and exit.
//  * The hover colour is Theme.line, not Theme.bgHi. A button on the rail sits
//    inside a Group, and Group draws its ground in bgHi, so a bgHi highlight
//    there is invisible; line is the step above it and reads on bg, bgAlt and
//    bgHi alike. It is the same colour the rail already uses to light the
//    metrics group under the pointer.
Item {
    id: root

    property string glyph: ""

    // Two ways of being on, because they are two different things.
    //
    // `active` is a toggle that is set: the pinned row in the widget list, the
    // playing track's pause button, the tab the control centre is on. It floods
    // the slot with the accent and inverts the glyph to Theme.bg, which measures
    // 3.5 to 8.4:1 — fine, because it is one glyph and the glyph flips with the
    // ground.
    //
    // `open` is this button's *panel* being the one showing, which is the state
    // the whole rail now says the same way — see OpenGround. It cannot flood,
    // because the glyph has to keep its own colour: the wifi glyph is Theme.bad
    // when the link is down and the bluetooth one is Theme.good when something
    // is paired, and the flood threw both away exactly while their panel was
    // open. Nothing sets both.
    property bool active: false
    property bool open: false

    property color tint: Theme.dim

    // A ground that is there when the button is idle, and round, instead of a
    // rounded square that only appears under the pointer.
    //
    // Two controls take it — wifi and bluetooth — because they stand directly
    // under the tray cells in the same bottom cluster, and a tray cell is a 26px
    // disc of Theme.bgAlt (shell.qml:752-760, and the overflow count at :818-826
    // is the same shape). Without it that column reads as two grounded icons
    // followed by two floating glyphs, which is the thing Erik pointed at.
    //
    // This is not an option asking "should I show this?". It is the button's
    // shape, stated once at the two call sites that happen to be standing in a
    // row of discs; every other Btn on the rail is deliberately bare and says
    // nothing at all. The diameter is the tray cell's 26 rather than the slot's
    // 28, so the two kinds of icon are literally the same disc — and the slot is
    // untouched, so the rail's rhythm and rail.fixed are exactly what they were.
    //
    // A ground under a dim glyph is where legibility usually goes, so it was
    // measured rather than assumed. bgAlt is one step nearer base00 than the
    // bgHi these buttons used to sit on, so every glyph gained contrast in every
    // theme checked: on his Gruvbox dark the fg glyph goes 9.57 to 10.75 and the
    // dim one 3.58 to 4.02; on One Light 9.01 to 9.96 and 4.16 to 4.60; on
    // Atelier Dune Light — the worst of six — 2.08 to 4.18 and 1.68 to 3.38. The
    // one pairing still under 3.3 is Theme.good on a light scheme (2.81 on One
    // Light, 2.20 on Atelier Dune), which is the bluetooth-connected tint and the
    // VPN padlock. That was already below the floor before this change, at 2.55
    // and 1.10, and it is a light-scheme green problem rather than a disc one.
    //
    // The 12% wash `open` lays over that disc was measured the same way, on the
    // nine curated schemes. It costs a glyph about half a point: Theme.fg is
    // 8.72 washed against 10.75 resting on his Gruvbox, 5.13 against 6.40 on
    // Everforest, 9.39 against 11.57 on Tokyo Night, 5.46 against 6.43 on
    // Gruvbox Light. Theme.dim — the bluetooth glyph with the radio off — is the
    // weakest, 2.36 washed against 2.88 resting on Kanagawa, 3.26 against 4.02
    // on Gruvbox. That is a glyph the shell is deliberately drawing quiet, it
    // was already under the floor before the wash, and a heavier wash would make
    // it worse rather than better: the wash moves the ground *towards* the
    // accent, which on every dark scheme here is the direction dim already lies
    // in. What it replaces was not better — the flood repainted that glyph
    // Theme.bg and said nothing about the radio at all.
    property bool disc: false

    // Read from the MouseArea rather than latched by entered/exited, so it
    // cannot stick on when the button is hidden or reparented mid-hover.
    readonly property bool hovering: ma.containsMouse

    signal clicked

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: Theme.slot
    implicitHeight: Theme.slot

    OpenGround {
        anchors.centerIn: parent
        width: root.disc ? 26 : parent.width
        height: root.disc ? 26 : parent.height
        radius: root.disc ? width / 2 : Theme.radiusS

        on: root.open
        // The flood outranks the pointer, the way it did when both were one
        // ternary here.
        hovering: root.hovering && !root.active
        // A disc is never absent, so its resting colour is a real colour rather
        // than the hover colour at zero alpha — and the animation still runs
        // between two real colours either way, which is the whole reason the
        // zero-alpha idiom is there. It is also the only shape a button that
        // opens a panel takes, so it is the only resting colour `open` above
        // ever has to wash, and the one case OpenGround needs opaque.
        ground: root.active ? Theme.accent
              : root.disc ? Theme.bgAlt
              : Qt.alpha(Theme.line, 0)

        // The glyph, half a pixel further right than QML would put it on its
        // own.
        //
        // `anchors.centerIn` does not centre an odd-sized item. Qt's own
        // hcenter() helper in qquickanchors.cpp returns (width + 1) / 2 when
        // the width is odd, which snaps the item to the pixel grid and leaves
        // it half a pixel left of centre — and every one of these glyphs lays
        // out odd: 15px for the four wifi shapes, 13 for ethernet and the
        // globe, 11 for bluetooth-off, 9 for bluetooth. Against a bare rail
        // there was nothing to be off-centre from, so nobody could see it. The
        // disc made it measurable, which is when Erik pointed at it.
        //
        // Measured on his rail, ink bounding box against disc centre, before
        // and after: every glyph sat 0.5 to 1.0px left and now sits 0.19 to
        // 0.45px left, which is the ceiling of what is available — Qt rounds a
        // Text's contentWidth up to a whole pixel while the ink inside it is
        // fractional (12.48px of ethernet in a 13px box), so half of that
        // rounding is a leftward lean no anchor can undo. Nor can measuring it
        // at runtime: TextMetrics.tightBoundingRect comes back integer, so it
        // cannot see the fraction either.
        //
        // Vertically there is nothing to fix and nothing to fear: the Nerd Font
        // patcher centres these Material Design glyphs on the midpoint of the
        // font's own ascent and descent — ink centre 360 units, (1020 - 300) / 2
        // is 360 — so the ink already lands within 0.1px of the disc's middle,
        // and the box is an even 20px tall, which centerIn gets exactly right.
        //
        // Two things that look like the fix are not. Filling the ground and
        // setting horizontalAlignment centres the *advance* rather than the
        // ink, and these glyphs carry 14.55px of ink on a 9px advance, all of
        // it overhanging right: measured, it throws the wifi glyph 2.8px the
        // other way. And a per-glyph offset table would be five numbers nobody
        // will maintain, wrong the day a glyph changes, for a correction that
        // is the same half pixel in all five cases.
        //
        // The reference shells are no help here because none of them has this
        // problem in view: noctalia, whisker, skwd, Zaphkiel, vast-shell,
        // josecriane and four others all centre the box and live with it, and
        // the one that fills and aligns instead — diinki's — would be off the
        // way measured above. Only Ricelin actually solves it, by giving up on
        // fonts and centring the bounding box of a baked SVG path.
        Text {
            anchors.centerIn: parent
            anchors.alignWhenCentered: false
            text: root.glyph
            color: root.active ? Theme.bg : root.tint
            font.pixelSize: Theme.icon
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
