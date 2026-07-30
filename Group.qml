import QtQuick
import QtQuick.Layouts

// A cluster of rail items on its own rounded ground, so the bar reads as a few
// distinct groups with air between them rather than one continuous strip.
//
// This is not in tension with the rail's one curve. That curve is about the
// rail's *outer* silhouette — where the surface meets the screen — and it stays
// exactly where it was, at the bottom of the workspaces. A ground is about what
// is *inside* the rail: which controls belong together. The two are answers to
// different questions, and fifteen bars were read to check that they are
// separable. They are: the projects with the most deliberate outer shape are
// also the ones that ground their clusters hardest.
//
// The colour is one opaque step up from the rail's own background, which is
// what this is everywhere it is done at all. josecriane's bar is base01 and
// every grounded cluster on it is base02 (ds/Foundations.qml:23-24, over
// modules/bar/components/StatusIcons.qml:16 `color: Foundations.palette.base02`);
// whisker steps m3background #111318 to m3surface_container #1e1f25 for the one
// cluster it grounds (modules/bar/BarRight.qml:41); doannc2212 steps bgBase
// #1a1b26 to bgSurface #24283b (bar/DefaultTheme.qml:4-5). Nobody grounds a
// group with a border alone and nobody grounds one with an alpha wash — a wash
// is what those same bars reserve for *hover*, at 7-12%, which is why Btn and
// the workspace pills still light in Theme.line and are still visible doing it.
//
// So the rail reads in three tones rather than two: Theme.bg is the rail,
// Theme.bgAlt is a group standing on it, and Theme.bgHi is the workspaces —
// one further step, because they are the block that carries the curve and runs
// into the screen edges. Giving the privileged cluster exactly one extra step
// is tripathiji1312's move for its centre pill, surfaceContainerHighest against
// surfaceContainerHigh for everything else (modules/bar/Bar.qml:123 against
// :71). Shape says the same thing twice over: the workspaces are full rail
// width and square into the top and left edges, these are inset to
// Theme.groupWidth and rounded on all four corners.
//
// Theme.radiusS, not the 20 the workspaces carry, for the same reason those
// bars keep group radius at or under bar radius — a group should never fight
// the outline it sits inside.
Rectangle {
    id: root

    default property alias content: col.data
    property int gap: Theme.slotGap

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: Theme.groupWidth
    implicitHeight: col.implicitHeight + Theme.groupPad * 2
    radius: Theme.radiusS
    color: Theme.bgAlt

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: parent.width
        spacing: root.gap
    }
}
