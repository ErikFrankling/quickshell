import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris

// What is playing, on the rail, without opening anything.
//
// Eighteen shells were read for this (docs/surveys/player-survey.qml) and the
// vertical ones nearly all give up on the title: noctalia pushes it into a
// tooltip (Bar/Widgets/MediaMini.qml:348-374), end-4 shows a progress circle
// and a glyph and no text (VerticalMedia.qml:44-87), omarchy-quattro's title is
// literally `visible: !bar.vertical`.
//
// Two solved it, and both turned the text on its side: shub39_dotfiles'
// PlayingMedia.qml:65-83 rotates the label 90 degrees and swaps its slot's
// dimensions so a 40px rail carries a whole song name down its length. That is
// the idiom copied here.
//
// This was three stacked things — art, a progress bar under it, a row of
// transport buttons under that — and it is two, because the ones that had to
// be separate did not. Both merges are read off the shells above. The progress
// goes round the art: noctalia's vertical branch is a ProgressRing filling the
// slot with the art inset inside it by twice the stroke (MediaMini.qml:358-373,
// and the same pair horizontally at :298-314), and end-4's whole vertical media
// widget is one ClippedFilledCircularProgress with a glyph in the middle
// (verticalBar/VerticalMedia.qml:44-67). A ring costs the rail nothing; it is
// drawn in the slot the art already had. And play/pause goes on the art, under
// the pointer, because every shell surveyed hides transport behind a mouse
// chord — noctalia and end-4 both on middle click (MediaMini.qml:401,
// VerticalMedia.qml:33) — which is the thing nobody ever finds.
//
// Next is gone. On a rail this narrow the choice was one visible transport
// control or none, and pause is the one you reach for. So the widget has two
// click targets and they mean different things: the art plays and pauses, and
// the title opens the panel. vast-shell (Qml/Widgets/Mpris.qml:37-67) is the
// one surveyed shell keeping visible transport in the bar; it is right.
//
// Nothing here may ever be wider than 34px. The rail's width is load-bearing,
// so every width below is a literal and only heights answer to content.
Item {
    id: root

    // Set by the rail so the title can show the panel is open; the rail owns
    // which page is up, not this.
    property bool active: false

    // Clicking the title opens the player panel. The rail decides what that
    // means, the same way it does for every other rail item.
    signal activated

    // One player, chosen the way noctalia's findActivePlayer does it
    // (Services/Media/MediaService.qml:158-192): whatever is actually
    // playing wins, then whatever has something to say, then whatever is
    // left. Reading playbackState and trackTitle inside the binding is what
    // subscribes it to them, so this re-picks when a second player starts.
    readonly property var p: {
        const v = Mpris.players.values;
        return v.find(x => x.playbackState === MprisPlaybackState.Playing)
            ?? v.find(x => x.trackTitle)
            ?? v[0] ?? null;
    }

    readonly property bool playing: root.p?.playbackState === MprisPlaybackState.Playing

    // A player that reports no metadata at all still has a name, and its name
    // is more use than an empty strip. Spotify does this for a second or two
    // on every launch.
    readonly property string title: root.p ? (root.p.trackTitle || root.p.identity || "Unknown") : ""

    readonly property real progress: {
        const q = root.p;
        if (!q || !(q.length > 0))
            return 0;
        return Math.max(0, Math.min(1, q.position / q.length));
    }

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: 34
    implicitHeight: col.implicitHeight

    // position is read on demand rather than pushed, so a binding on it never
    // moves by itself. Re-emitting the notify signal on a timer is end-4's
    // idiom for exactly this (verticalBar/VerticalMedia.qml:23-28); it only
    // ticks while something is actually playing.
    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.p?.positionChanged()
    }

    // Canvas does not repaint on a property change by itself. Progress is the
    // one that moves, and the palette is the one that moves while nothing is
    // playing — without the second, switching theme leaves the old accent
    // painted round a paused track until it starts again.
    onProgressChanged: ring.requestPaint()

    Connections {
        target: Theme
        function onPaletteChanged() { ring.requestPaint(); }
    }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: parent.width
        spacing: 5

        // The art, in the ring that says where the track is.
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 34
            implicitHeight: 34

            // The same ring Ring draws for the metrics — 3px stroke, round
            // caps, from twelve o'clock — so the two rings on the rail are one
            // ring. The track is drawn even with no length to fill it, the way
            // noctalia feeds its ring zero for a stream (MediaMini.qml:302),
            // because without it a 26px circle floats in a 34px slot.
            Canvas {
                id: ring
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d");
                    const w = width, r = w / 2 - 1.5;
                    ctx.reset();
                    ctx.lineWidth = 3;
                    ctx.lineCap = "round";

                    ctx.beginPath();
                    ctx.arc(w / 2, w / 2, r, 0, Math.PI * 2);
                    ctx.strokeStyle = Theme.line;
                    ctx.stroke();

                    if (root.progress > 0) {
                        ctx.beginPath();
                        ctx.arc(w / 2, w / 2, r, -Math.PI / 2,
                                -Math.PI / 2 + Math.PI * 2 * root.progress);
                        ctx.strokeStyle = Theme.accent;
                        ctx.stroke();
                    }
                }
            }

            // Round, because it is inside a ring now. ClippingRectangle rounds
            // it without a shader of our own — it ships one — and a plain
            // Rectangle cannot, its clip being square whatever its radius. 26
            // across leaves a pixel between the art and the inside of the
            // stroke; noctalia insets by twice the stroke (MediaMini.qml:368).
            ClippingRectangle {
                id: artBox

                anchors.centerIn: parent
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: Theme.bgAlt

                // Paused art is dimmed rather than hidden; the title colour is
                // the other cue. The dim is on the picture rather than on the
                // tile so the transport laid over it stays legible — a half-lit
                // play button on a paused track is the one moment it must be.
                Image {
                    id: art
                    anchors.fill: parent
                    source: root.p?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 26
                    sourceSize.height: 26
                    asynchronous: true
                    smooth: true
                    opacity: root.playing ? 1 : 0.5

                    Behavior on opacity { NumberAnimation { duration: 110 } }
                }

                // Podcasts, local files and half the web players have no art at
                // all, and Spotify has none for the first moment of a track.
                Text {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: root.p ? "󰝚" : "󰎊"
                    color: Theme.dim
                    font.pixelSize: 14
                    opacity: root.playing ? 1 : 0.5
                }

                // The transport, on the art and only under the pointer.
                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Theme.bg, 0.7)
                    opacity: hit.containsMouse ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: 110 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.playing ? "󰏤" : "󰐊"
                        color: Theme.fg
                        font.pixelSize: 14
                    }
                }

                // Only the art, not the ring: the ring is a reading rather than
                // a seek bar, and a click a pixel outside the picture should do
                // nothing rather than something.
                MouseArea {
                    id: hit
                    anchors.fill: parent
                    enabled: root.p?.canTogglePlaying ?? false
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.p?.togglePlaying()
                }
            }
        }

        // The title, turned on its side, reading bottom to top, and the button
        // that opens the panel. shub39's rail swaps the slot's width and height
        // around the label (PlayingMedia.qml:65-83); the swap is spelled out
        // here because the slot's width must stay a literal 34 rather than
        // become whatever the text measures.
        //
        // The height is a constant, not the measured title. Sizing to the text
        // meant every track change moved everything below it — the rail is a
        // fixed piece of furniture and a song name is not a reason to relayout
        // it. With nothing playing the slot goes away entirely and the widget
        // is just the ring, which is the one case where the height may change.
        Item {
            id: slot

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 34
            implicitHeight: 112
            visible: root.title !== ""

            Text {
                id: label
                anchors.centerIn: parent
                rotation: -90
                width: slot.height
                text: root.title
                color: root.active ? Theme.accent
                     : root.playing ? Theme.fg : Theme.dim
                // Back to 11px. 10px was not distorted — rendered, its caps
                // measured 7px and its stems 1px, exactly Ring's value and the
                // clock's date at the same nominal size — it was just a point
                // too small for the one label here nobody reads square on. The
                // eight pixels it bought are kept: "Everything Goes My Way
                // (Remastered)" is fourteen characters in 104, fifteen in 112.
                font.pixelSize: 11
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter

                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activated()
            }
        }
    }
}
