# The progress bar in a media panel, and whether it seeks

The player panel showed art, title, artist, source and three transport buttons
and never said where in the track you were. This is what the other shells do
about that, and what had to be established about MPRIS before any of it could
be copied.

Sources: the fifteen clones under `clones/` (the catalogue's list, cloned for
`player-survey.qml`), plus noctalia read in place. Everything below cites a
file and a line in one of them.

## 1. Who has one at all

Counted by grepping each clone for `Mpris` and then for a write to `position`,
`setPosition` or a read of `canSeek`:

| Project | MPRIS files | Seek/position hits | Has a bar |
|---|---|---|---|
| liixini/skwd | 5 | 11 | yes, with a dot handle |
| corecathx/whisker | 7 | 8 | yes, a slider |
| myamusashi/vast-shell | 8 | 4 | yes, a slider, in three places |
| Gakuseei/Ricelin | 3 | 3 | yes, a drawn waveform |
| tripathiji1312 | 1 | 2 | yes, a slider |
| maxchennn/vroomies | 2 | 2 | yes, a rectangle |
| noctalia | — | — | yes, a slider |
| Brainitech/Brain_Shell | 3 | 1 | yes |
| Rexcrazy804/Zaphkiel | 8 | 1 | yes |
| bjarneo, doannc2212, shub39, diinki ×2, josecriane | 0–3 | 0 | no |

Nine of fifteen. Every one of the nine puts elapsed and total beside or under
the bar; none ships a bar with no numbers.

## 2. Does `position` move by itself? No.

This is the trap. MPRIS `Position` is a read-on-demand property: the player
emits `Seeked` when *it* jumps, and otherwise never says anything, so a QML
binding on `position` is subscribed to a signal that does not fire. Every shell
that draws a moving bar therefore re-emits the notify signal on a timer, and
every one of them gates the timer on playback:

- Ricelin, `configs/quickshell/pill/Media.qml:92-97` —
  `interval: 500`, `running: root.active && root.playing`,
  `onTriggered: if (root.player) root.player.positionChanged();`
  Note the double gate: `active` is "the pill is open", `playing` is "there is
  something to move".
- vroomies, `settings/quickshell/components/MusicPanel.qml:65-75` —
  `interval: 1000`, `running: root.musicVisible && musicPanel.isPlaying`, same
  `positionChanged()` call, plus it caches the value into a property.
- noctalia, `Services/Media/MediaService.qml:296-308` — `interval: 1000` and a
  four-term guard (`currentPlayer && !isSeeking && isPlaying &&
  playbackState === Playing`), and it sets `running = false` from inside
  `onTriggered` if the guard has gone stale.
- whisker, `components/players/PlayerDisplay.qml:160-167` — the same timer,
  commented out, with a half-written `FrameAnimation` under it. Their slider is
  driven only by `Connections { function onPositionChanged() }` at :144-151,
  which means it moves when Spotify feels like telling it and not otherwise.
  This is what the bug looks like when you skip the timer.

`RailPlayer.qml:85-90` in this shell already had the idiom, cited to end-4's
`verticalBar/VerticalMedia.qml:23-28`. The panel reuses it rather than adding
a second mechanism, and gets Ricelin's second gate for free: the panel is a
`Loader` in `shell.qml:1133-1148`, so with the card shut the `Timer` does not
exist at all, let alone run.

## 3. Does it seek — and does Spotify honour it?

`canSeek` is advertised by the player and is not the same question as whether
seeking works. Checked against the actual type, not from memory:

`/nix/store/rbzv96…-quickshell-0.3.0/lib/qt-6/qml/Quickshell/Services/Mpris/quickshell-service-mpris.qmltypes`

- `:105` `canSeek`, bool, readonly, notify `canSeekChanged`
- `:194` `position`, double, **`write: "setPosition"`**, notify `positionChanged`
- `:203` `positionSupported`, bool, readonly
- `:212` `length`, double, readonly
- `:499` method `seek(offset: double)` — relative, the MPRIS `Seek` call

So there are two routes: assigning to `position` (MPRIS `SetPosition`,
absolute) and calling `seek()` (relative). Every surveyed shell uses the first:

- noctalia, `Services/Media/MediaService.qml:286-293` — `seekByRatio(ratio)`
  guards on `target.canSeek && target.length > 0`, then `target.position =
  ratio * target.length`.
- vroomies, `components/MusicPanel.qml:196-197` — `if (trackLength > 0 &&
  player && player.canSeek) player.position = (mouse.x / parent.width) *
  trackLength`.
- whisker, `components/players/PlayerDisplay.qml:155-159` — guards on
  `active?.canSeek && active?.positionSupported`, then
  `active.position = (value/100) * active.length`.
- Ricelin, `configs/quickshell/pill/Media.qml:618-639` — the fullest gate:
  `enabled: root.hasPlayer && root.player.canSeek &&
  root.player.positionSupported && root.lengthSec > 0 && !root.live`.
- vast-shell, `Qml/Modules/Drawers/QuickSettings/Settings/ContentMediaPlayer.qml:115`
  and `:345`, and `Qml/Modules/Lock/MediaPlayer.qml:289` and `:420` — the same
  one-liner in four places.

**Spotify's answer, measured rather than assumed.** Spotify advertises
`CanSeek true`. It also has a reputation for ignoring `SetPosition`, so it was
tested over the bus against the live player:

```
$ busctl --user get-property org.mpris.MediaPlayer2.spotify \
    /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player CanSeek
b true
$ # Position 222s; ask for 60s
$ busctl --user call … SetPosition ox /com/spotify/track/34xGLuxM0rkxhCVyMSqwJO 60000000
  t+1s: 60s   t+2s: 61s   t+3s: 62s   t+4s: 63s   t+5s: 64s
```

It works, and relative `Seek` works too. The important detail is the **latency**:
a first attempt read the position back 600ms after the call and saw only the
600ms of ordinary playback, which reads exactly like a call that was ignored.
Spotify applies the seek roughly a second later. Two consequences:

- Do not sample a seek's result inside a second. The naive test says "Spotify
  ignores SetPosition" and it is wrong.
- Do not send a seek per drag sample. A dragged slider that fires on every
  `onMoved` queues a dozen calls a second at a player that takes a second to
  answer each. noctalia works around this with a 75ms debounce timer and an
  epsilon (`Modules/Cards/MediaCard.qml:370-382, 386-413`) — 45 lines. Ricelin
  just commits once, `onReleased` (`pill/Media.qml:633-637`) — 5 lines. This
  panel does what Ricelin does.

The live player is reached through `org.mpris.MediaPlayer2.playerctld`, not
Spotify directly, so the write crosses a proxy. Verified end to end through the
UI: the bar sat at frac 0.415 (118s of 287s), a click at 40% of the bar's width
put it at 115s two and a half seconds later — the only way position goes
*backwards* is a seek that landed.

## 4. The layout: one row or two

- skwd, `skwd-music/qml/components/ProgressBar.qml:17-90` — a `ColumnLayout`:
  bar on top, then a `RowLayout` with elapsed left, spacer, total right. Costs
  a second row, `implicitHeight: 28`.
- vroomies, `components/MusicPanel.qml:170-208` — one `RowLayout`:
  elapsed, `Layout.fillWidth` bar, total. One line.
- tripathiji, `modules/controlcenter/sections/MediaSection.qml:375-441` — a
  `Slider` with a custom track and handle, then the two times in a row under
  it. Two rows plus a 20px slider.

One row, vroomies' shape. In a card that is already tall enough to reach the
screen edge, the stacked version buys nothing for the row it spends.

The affordance: skwd draws a 12px dot at the fill edge, `visible:
progressRoot.canSeek && seekArea.containsMouse`
(`components/ProgressBar.qml:47-55`). That is the only thing in any of the nine
that distinguishes a bar you can drag from a bar you can only read, and it is
six lines, so it is copied. skwd also over-sizes the hit area against a 6px bar
with `anchors.margins: -4` (`:61`); this panel gives the `MouseArea` a fixed
16px height against a 4px bar for the same reason.

## 5. What was taken

| Decision | Taken from |
|---|---|
| 1s timer re-emitting `positionChanged()`, gated on playing | `RailPlayer.qml:85-90`, Ricelin `pill/Media.qml:92-97` |
| Panel is a `Loader`, so the timer is absent when shut | Ricelin's second gate, for free |
| `position = frac * length` to seek | all six above |
| Gate on `canSeek && positionSupported && length > 0` | Ricelin `pill/Media.qml:622` |
| No bar at all when `length` is 0 (a stream) | noctalia `MediaService.qml:38` |
| Commit the seek once, on release | Ricelin `pill/Media.qml:633-637` |
| Dot at the fill edge on hover, only when seekable | skwd `ProgressBar.qml:47-55` |
| elapsed / bar / total on one row | vroomies `MusicPanel.qml:170-208` |
| `m:ss`, no leading hour unless there is one | skwd `ProgressBar.qml:93-99` |

## 6. Units

`MprisPlayer.length` and `.position` are **seconds**, not the microseconds the
bus carries. Two independent confirmations in the prior art — Ricelin names the
property it reads them into `positionSec` / `lengthSec`
(`pill/Media.qml:46-47`), and noctalia's "this is an infinite stream" threshold
is `922337203685` (`Services/Media/MediaService.qml:46`), one ten-millionth of
the microsecond sentinel — and one live: a track whose D-Bus `mpris:length` is
`313684000` renders as `4:47` and `7:47` in the panel for the tracks measured.
tripathiji's `formatTime(microseconds)`
(`modules/controlcenter/sections/MediaSection.qml:595-603`) divides by a
million and is the one that has it wrong.

## 7. Aside: the album art was not rendering

Found while doing the above, same `RowLayout`. The panel's art was a bare
`Image` kept on screen by `visible: source != ""` — true from the moment the
URL arrives, and true forever whether or not the picture follows. Spotify's
`mpris:artUrl` is an `https://i.scdn.co/…` address, so there is always a
network fetch in between. Logging `status` on the panel's own instance:

```
DIAGART status 2 src https://i.scdn.co/image/ab676…  pw 0  w 0  prog 0
DIAGART status 1 src https://i.scdn.co/image/ab676…  pw 64 w 64 prog 1
```

`2` is `Image.Loading`, `1` is `Image.Ready`. It loads — it just is not there
yet when the card opens, and the placeholder-free `Image` leaves a 64px hole
until it is. The rail rides out the same window because it asks for
`sourceSize` 26 where the panel asks for 64 — a different size is a different
entry in Qt's pixmap cache, so the panel always fetches its own copy — and
because `RailPlayer.qml:179-186` draws a glyph whenever
`art.status !== Image.Ready`.

Fixed by mirroring the rail: a `ClippingRectangle` that is always 64 across,
the `Image` inside it, and the glyph in its place until `status === Image.Ready`.
Nothing moves when the picture lands, and a podcast with no art at all keeps
the glyph rather than a hole — the same rule the tray icons follow.
