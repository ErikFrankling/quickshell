import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris

// What is playing, on the rail, without opening anything.
//
// Eighteen shells were read for this and the vertical ones nearly all give up
// on the title: noctalia's MediaMini collapses to a square of album art and
// pushes the title into a tooltip (Bar/Widgets/MediaMini.qml:348-374), end-4's
// VerticalMedia shows a progress circle and a glyph (VerticalMedia.qml:44-87),
// DankMaterialShell's vertical branch has no text at all (Media.qml:171-247),
// omarchy-quattro's title is literally `visible: !bar.vertical`. All of them
// then hide next behind a middle-click or a thumb button nobody ever finds.
//
// Two solved it, and both turned the text on its side: shub39_dotfiles'
// PlayingMedia.qml:65-83 rotates the label 90 degrees and swaps its slot's
// dimensions so a 40px rail carries a whole song name down its length, and
// cartoon-shell rotates a marquee the same way. That is the idiom copied here.
//
// So: noctalia's skeleton — art puck, progress, click for the panel — with
// shub39's rotated title put back where noctalia drops it, and real buttons
// instead of mouse chords. vast-shell (Qml/Widgets/Mpris.qml:37-67) is the one
// surveyed shell keeping visible transport in the bar; it is right.
//
// Nothing here may ever be wider than 34px. The rail's width is load-bearing,
// so every width below is a literal and only heights answer to content.
Item {
    id: root

    // Set by the rail so the art can show the panel is open; the rail owns
    // which page is up, not this.
    property bool active: false

    // Clicking the art opens the player panel. The rail decides what that
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

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: parent.width
        spacing: 5

        // Album art is the icon, which is how every vertical bar that shows
        // art at all does it. ClippingRectangle rounds it without a shader of
        // our own — it ships one — and a plain Rectangle cannot, because its
        // clip is square whatever its radius. nucleus-shell's bar module rounds
        // its art exactly this way, ClippingRectangle over PreserveAspectCrop
        // with a music glyph behind it (MediaPlayerModule.qml).
        ClippingRectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 34
            implicitHeight: 34
            radius: Theme.radiusS
            color: Theme.bgAlt

            // Under, not inside: an inside border resizes the art by two
            // pixels the moment a panel opens, and the tile visibly twitches.
            contentUnderBorder: true
            border.width: root.active ? 2 : 0
            border.color: Theme.accent

            // Paused art is dimmed rather than hidden. It is the first of the
            // three cues that say whether this is playing; the transport
            // glyph and the title colour are the other two.
            opacity: root.playing ? 1 : 0.5
            Behavior on opacity { NumberAnimation { duration: 110 } }

            Image {
                id: art
                anchors.fill: parent
                source: root.p?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 34
                sourceSize.height: 34
                asynchronous: true
                smooth: true
            }

            // Podcasts, local files and half the web players have no art at
            // all, and Spotify has none for the first moment of a track.
            Text {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: root.p ? "󰝚" : "󰎊"
                color: Theme.dim
                font.pixelSize: 17
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activated()
            }
        }

        // Where the track is, in two pixels. Streams report no length and get
        // nothing rather than a bar stuck at zero.
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 34
            implicitHeight: 2
            radius: 1
            color: Theme.line
            visible: (root.p?.length ?? 0) > 0

            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: 1
                color: Theme.accent
            }
        }

        // The title, turned on its side, reading bottom to top. shub39's rail
        // does this by swapping the slot's width and height around the label
        // (PlayingMedia.qml:65-83); the swap is spelled out here instead,
        // because the slot's width must stay a literal 34 rather than become
        // whatever the text happens to measure. Only the height answers to the
        // title, and height is what the rail has to give.
        Item {
            id: slot

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 34
            implicitHeight: Math.min(104, Math.ceil(metrics.advanceWidth))
            visible: root.title !== ""

            // Measured unconstrained, so the slot can size to the text without
            // the text sizing to the slot — reading the label's own width back
            // into the slot that sets it is the loop this avoids. xenon-shell
            // uses TextMetrics the same way to size a slot it is also eliding
            // into (Modules/Bar/Widgets/Media.qml:92-98).
            //
            // advanceWidth, not width. width rounds down to whole pixels, and
            // a label given its own rounded-down width elides — "The Spins"
            // measured 59 and needed 59.34, so every title lost its last two
            // characters to a third of a pixel. advanceWidth is the unrounded
            // number and matches the label's implicitWidth exactly.
            TextMetrics {
                id: metrics
                font: label.font
                text: root.title
            }

            Text {
                id: label
                anchors.centerIn: parent
                rotation: -90
                width: slot.height
                text: root.title
                color: root.playing ? Theme.fg : Theme.dim
                font.pixelSize: 11
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Play/pause and next, because those are the two you actually reach
        // for. Two cells of seventeen fill the tile's width exactly, so the
        // row cannot be the thing that makes this wider.
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            visible: root.p !== null

            component Ctl: Item {
                id: ctl

                property string glyph: ""
                property bool can: true

                signal trigger

                implicitWidth: 17
                implicitHeight: 20
                opacity: ctl.can ? 1 : 0.35

                Text {
                    anchors.centerIn: parent
                    text: ctl.glyph
                    color: hit.containsMouse && ctl.can ? Theme.accent : Theme.fg
                    font.pixelSize: 14
                }

                MouseArea {
                    id: hit
                    anchors.fill: parent
                    enabled: ctl.can
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ctl.trigger()
                }
            }

            Ctl {
                glyph: root.playing ? "󰏤" : "󰐊"
                can: root.p?.canTogglePlaying ?? false
                onTrigger: root.p?.togglePlaying()
            }

            Ctl {
                glyph: "󰒭"
                can: root.p?.canGoNext ?? false
                onTrigger: root.p?.next()
            }
        }
    }
}
