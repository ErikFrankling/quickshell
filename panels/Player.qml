import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris

ColumnLayout {
    id: root
    spacing: Theme.pad

    readonly property var p: Mpris.players.values.find(x => x.isPlaying) ?? Mpris.players.values[0] ?? null

    // Seconds, not microseconds: Quickshell converts on the way in, which is
    // what Ricelin's `positionSec: player.position` (pill/Media.qml:46) and
    // noctalia's infinite-stream threshold — 922337203685, one ten-millionth
    // of the microsecond sentinel — both assume, and what the live player
    // reports for a track whose D-Bus mpris:length is 313684000.
    readonly property real len: root.p?.length ?? 0

    // A bar with no length behind it is a lie, so it is not drawn at all —
    // that is a live stream, and there is nothing to be a fraction of.
    readonly property bool live: root.len > 0 && (root.p?.positionSupported ?? false)

    // And a bar that cannot be dragged does not offer to be. canSeek is the
    // player's own answer; Ricelin gates on exactly this pair plus a length
    // (pill/Media.qml:622) and whisker on the same pair
    // (players/PlayerDisplay.qml:157).
    readonly property bool seekable: root.live && (root.p?.canSeek ?? false)

    // Where the drag is, or -1 for "not dragging". One property rather than a
    // position and a bool, and it is what the bar reads while the pointer is
    // down so the fill follows the finger instead of the player's own report,
    // which lands about a second late.
    property real dragFrac: -1

    readonly property real frac: root.dragFrac >= 0 ? root.dragFrac
        : root.len > 0 ? Math.max(0, Math.min(1, (root.p?.position ?? 0) / root.len)) : 0

    function clock(sec) {
        const s = Math.max(0, Math.floor(sec));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // position is read on demand rather than pushed, so a binding on it never
    // moves by itself; re-emitting its notify signal on a timer is the idiom
    // RailPlayer already uses for the ring, and Ricelin (pill/Media.qml:93-98)
    // and vroomies (components/MusicPanel.qml:65-75) for their bars. It ticks
    // only while something is playing, and the panel is a Loader in shell.qml,
    // so with the card shut this Timer does not exist at all.
    Timer {
        running: root.p?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: root.p?.positionChanged()
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: art.implicitHeight + 26
        radius: Theme.radiusS + 2
        color: Theme.bgAlt
        visible: root.p !== null

        ColumnLayout {
            id: art
            anchors.fill: parent
            anchors.margins: 13
            spacing: 10

            RowLayout {
                spacing: 12
                // The art was a bare Image held visible by `source != ""`,
                // which is true from the moment the URL arrives and stays true
                // whether or not the picture ever does. Spotify's artUrl is an
                // https://i.scdn.co address, so there is a fetch between the
                // two: logging status on this instance caught it at 2
                // (Loading), paintedWidth 0, on open, then 1 (Ready) at 64.
                // The rail rides out the same window because it asks for 26px
                // where this asks for 64 — a different sourceSize is a
                // different cache entry, so the panel always fetches its own
                // copy — and because RailPlayer.qml:179-186 draws a glyph in
                // the gap. This is that box. Nothing moves when the picture
                // lands, and a podcast with no art, or a fetch that never
                // finishes, keeps the glyph instead of leaving a hole.
                // ClippingRectangle rounds the picture; a plain Rectangle
                // cannot, its clip being square whatever its radius.
                ClippingRectangle {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    radius: Theme.radiusS
                    color: Theme.bg

                    Image {
                        id: cover
                        anchors.fill: parent
                        source: root.p?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 64
                        sourceSize.height: 64
                        asynchronous: true
                        smooth: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: cover.status !== Image.Ready
                        text: "󰝚"
                        color: Theme.dim
                        font.pixelSize: 28
                    }
                }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: root.p?.trackTitle ?? ""
                        color: Theme.fg
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.p?.trackArtist ?? ""
                        color: Theme.dim
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.p?.identity ?? ""
                        color: Theme.dim
                        opacity: 0.7
                        font.pixelSize: 11
                    }
                }
            }

            // How far in, and how long left. The two numbers sit on the bar's
            // own line rather than under it — skwd stacks them
            // (components/ProgressBar.qml:72-90) and pays a second row for it,
            // vroomies puts all three in one (components/MusicPanel.qml:170-208)
            // and that is the one that costs the card nothing.
            RowLayout {
                Layout.fillWidth: true
                visible: root.live
                spacing: 8

                Text {
                    text: root.clock(root.frac * root.len)
                    color: Theme.dim
                    font.pixelSize: 11
                }

                Rectangle {
                    id: track

                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Theme.line

                    Rectangle {
                        id: fill
                        width: parent.width * root.frac
                        height: parent.height
                        radius: 2
                        color: Theme.accent
                    }

                    // The one thing that says the bar is draggable, and only
                    // on a player that will honour it. skwd shows the same
                    // dot on hover (components/ProgressBar.qml:47-55).
                    Rectangle {
                        visible: root.seekable && (seek.containsMouse || root.dragFrac >= 0)
                        x: fill.width - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 9
                        height: 9
                        radius: 4.5
                        color: Theme.accent
                    }

                    // Taller than the bar it drives: 4px is not a target. The
                    // seek is sent once, on release, rather than on every
                    // sample — Spotify takes about a second to act on one and
                    // a dragged bar would queue a dozen. Ricelin commits on
                    // release for the same reason (pill/Media.qml:618-639).
                    MouseArea {
                        id: seek

                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        height: 16
                        enabled: root.seekable
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function fracAt(x) {
                            return Math.max(0, Math.min(1, x / seek.width));
                        }

                        onPressed: e => root.dragFrac = seek.fracAt(e.x)
                        onPositionChanged: e => {
                            if (seek.pressed)
                                root.dragFrac = seek.fracAt(e.x);
                        }
                        onReleased: {
                            if (root.p && root.dragFrac >= 0)
                                root.p.position = root.dragFrac * root.len;
                            root.dragFrac = -1;
                        }
                    }
                }

                Text {
                    text: root.clock(root.len)
                    color: Theme.dim
                    font.pixelSize: 11
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Btn { glyph: "󰒮"; onClicked: root.p?.previous() }
                Btn {
                    glyph: root.p?.isPlaying ? "󰏤" : "󰐊"
                    active: root.p?.isPlaying ?? false
                    onClicked: root.p?.togglePlaying()
                }
                Btn { glyph: "󰒭"; onClicked: root.p?.next() }
            }
        }
    }

    Text {
        visible: root.p === null
        text: "Nothing playing"
        color: Theme.dim
        font.pixelSize: 13
    }

    Item { Layout.fillHeight: true }
}
