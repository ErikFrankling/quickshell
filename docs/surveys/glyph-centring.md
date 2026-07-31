# Half a pixel left: why `centerIn` does not centre a glyph

Erik, on the wifi and bluetooth buttons the moment they were given a 26px
disc: *"this is slightly off-centered, both of these."*

He is right, and the cause is not the one to suspect. The obvious story is
side bearings — Nerd Font icon glyphs sit off-centre in their em box, so a
perfectly centred *box* holds off-centre *ink*. That story is wrong here, and
this sheet is the measurement that kills it.

## Method

Everything below is measured off the live rail on his desktop, at scale 1 on a
1920x1080 output, so a screenshot pixel is a logical pixel. `grim` crops the
26px disc, `ffmpeg` turns the PNG into raw rgb24 and a Perl script finds the
ink inside the disc: any pixel that differs from the disc's ground colour by
more than a threshold, with the outer 0.9px of the disc excluded so the
antialiased rim and the `open` hairline cannot be mistaken for ink.

Three centres are reported because each lies in a different way.

* **bbox** — the ink bounding box. Honest, but quantised to whole pixels, so
  it can only ever say 0.00 or ±0.50.
* **centroid** — coverage-weighted. Sub-pixel, but it leans wherever the shape
  carries more mass, so it is only meaningful for a shape symmetric about the
  axis being measured.
* **mirror fit** — the axis at which the ink's coverage profile best agrees
  with its own mirror image, searched at 0.01px. Sub-pixel and the right
  answer for a symmetric glyph; biased for the bluetooth rune and the wifi
  fan, which are not symmetric about the axis in question.

Every glyph the two disc buttons can show was put on the rail in turn, by
driving the button's `text` from an index and letting the shell hot-reload
between shots. Qt's own numbers were read the same way, by logging
`TextMetrics` and the `Text` item's position from inside `Btn.qml`.

## What Qt is actually doing

| glyph | codepoint | advance | `contentWidth` | ink width | item `x` in the 26px disc |
|---|---|---|---|---|---|
| wifi, three bars | U+F0928 | 9.000 | 15 | 14.55 | 5.0 — should be 5.5 |
| wifi, two bars | U+F0925 | 9.000 | 15 | 14.55 | 5.0 |
| wifi, one bar | U+F091F | 9.000 | 15 | 14.55 | 5.0 |
| wifi, off | U+F092E | 9.000 | 15 | 14.55 | 5.0 |
| ethernet | U+F0200 | 9.000 | 13 | 12.48 | 6.0 — should be 6.5 |
| globe | U+F059F | 9.000 | 13 | 12.48 | 6.0 |
| bluetooth | U+F00AF | 9.000 | 9 | 7.95 | 8.0 — should be 8.5 |
| bluetooth, off | U+F00B2 | 9.000 | 11 | 10.02 | 7.0 — should be 7.5 |
| padlock | U+F033E | 9.000 | 11 | 10.02 | 7.0 |

Two facts fall out of that table.

**The Text box is sized by the ink, not by the advance.** Qt lays these glyphs
out at `contentWidth` 15/13/11/9 against an advance of 9. The Nerd Font
patcher draws a Material Design glyph 1.4 to 1.6 times wider than the cell it
advances, all of the overhang to the right, and `QQuickText` sizes itself to
the bounding rect rather than to the advance. So the ink very nearly fills its
own box, and centring the box very nearly centres the ink. The side-bearing
story is dead: what is left inside the box is at most a quarter pixel.

**`anchors.centerIn` does not centre an odd-sized item.** Qt's `hcenter()`
helper in `qquickanchors.cpp` returns `(width + 1) / 2` when the width is odd,
which snaps the item to the pixel grid. Every one of these glyphs lays out
odd, so every one of them lands half a pixel left. That is the bug, and it is
the same half pixel in all nine cases.

Against a bare rail there was no edge to be off-centre from, so nobody could
see it. The disc made it measurable, which is when Erik pointed at it.

## Before and after

`anchors.alignWhenCentered: false` is the documented switch for that snapping.
Same rail, same glyphs, same crop.

| glyph | bbox before | bbox after | mirror fit before | mirror fit after |
|---|---|---|---|---|
| wifi, three bars | -1.00 | 0.00 | -0.70 | -0.20 |
| wifi, two bars | -1.00 | 0.00 | -0.70 | -0.20 |
| wifi, one bar | -1.00 | 0.00 | -0.70 | -0.20 |
| wifi, off | -1.00 | 0.00 | -0.84 | -0.34 |
| ethernet | -1.00 | 0.00 | -0.72 | -0.22 |
| globe | -1.00 | 0.00 | -0.72 | -0.22 |
| bluetooth | -0.50 | 0.00 | (asymmetric) | (asymmetric) |
| bluetooth, off | -1.00 | -0.50 | -0.72 | -0.28 |
| padlock | -1.00 | -0.50 | -0.96 | -0.45 |

Every glyph moved exactly +0.50, and none is now further out than half a
pixel. That is the ceiling of what is available. Qt rounds `contentWidth` up
to a whole pixel while the ink inside it is fractional — 12.48px of ethernet
in a 13px box — and half of that rounding is a leftward lean no anchor can
undo. Measuring the ink at runtime cannot beat it either:
`TextMetrics.tightBoundingRect` comes back integer and cannot see the fraction
that would have to be corrected.

## Vertically there was nothing to fix

Every glyph measured 0.00 by bbox before and after, and the arithmetic says
why. The Nerd Font patcher centres these Material Design glyphs on the
midpoint of the font's own ascent and descent: ink centre 360 font units,
against `(1020 - 300) / 2` = 360. The `Text` box is an even 20px tall, so
`centerIn` places it exactly, and the ink lands within 0.1px of the disc's
middle. There is no vertical problem to solve and no `lineHeight`,
`lineHeightMode` or `pointSize`-versus-`pixelSize` trick needed to solve it.

## The tray cells are the control

The tray cells directly above use the same 26px disc with a 15x15 `Image`
rather than a `Text`. They sit at exactly the same **-0.50 in x and -0.50 in
y** — 15 is odd in both axes, so `hcenter()` and `vcenter()` snap it the same
way. That is the proof: the offset is not a text-rendering or side-bearing
effect at all, because it happens identically to a bitmap.

They keep it. A rasterised icon wants the pixel grid more than it wants the
last half pixel, which is exactly what the snap is for; distance-field text
does not care, so it can have the half pixel back.

## What the corpus does — centres the box and lives with it

Ten trees read. Not one has a per-glyph offset table, and only one solves the
problem at all.

| Approach | Who |
|---|---|
| `anchors.centerIn: parent` on a content-sized `Text`, no correction | noctalia (`Widgets/NIcon.qml:6-29`, 31 call sites), Rexcrazy804 `Zaphkiel` (`Generics/MatIcon.qml:7-23`, ground at `ToggleButton.qml:110`), josecriane (`ds/icons/FontIcon.qml:6-17`, ground at `ds/buttons/IconButton.qml:42-43`), corecathx `whisker` (`components/MaterialIcon.qml:3-22`), myamusashi `vast-shell` (`Qml/Core/Utils/Icon.qml:5-28`), tripathiji1312 (`components/IconButton.qml:108-110`), liixini `skwd` (`skwd-music/qml/components/IconButton.qml:16-27`), Brainitech (`src/components/IconBtn.qml:8-18`) |
| Fill the ground and use `AlignHCenter`/`AlignVCenter` | diinki `linux-antiquity` (`sidebarPopups/PowerMenu.qml:188-191`, and five more) |
| Hand-rolled x/y, then rounded back onto the grid | noctalia's two button widgets — `NIconButton.qml:76-77` via `Style.pixelAlignCenter`, which is `Math.round((containerSize - contentSize) / 2)` (`Commons/Style.qml:163-165`); `NIconButtonHot.qml:85-88` writes `(root.width - width) / 2` and `(root.height - height) / 2 + (height - contentHeight) / 2` |
| Abandon fonts; centre the bounding box of a baked SVG path | Gakuseei `Ricelin` (`pill/GlyphIcon.qml:94-106`) |

The three `*CenterOffset` nudges in the corpus are not glyph corrections:
josecriane scales one by font size (`modules/notifications/NotificationItem.qml:221-222`,
`modules/popups/Battery.qml:62,74`) and bjarneo puts a flat `-1` on a *clock*
(`desktop/BarWhiterose.qml:124`, `BarHacker.qml:184`). `lineHeight` and
`lineHeightMode` are never used on an icon `Text` anywhere in the corpus.

So the honest reading is that everyone centres the box and lives with it. The
half pixel is below the threshold at which anyone bothers — until you put the
glyph on a disc, which is what this shell just did.

## Two fixes that measured wrong

**Fill the ground and set `horizontalAlignment`** — diinki's idiom, and the
obvious candidate. It centres the *advance*, not the ink, and these glyphs
carry 14.55px of ink on a 9px advance with all the overhang to the right.
Measured on the rail it threw the wifi glyph **+2.80px** the other way, and
ethernet **+1.78**. This is the same `advanceWidth`-versus-`width` split that
bit this project once before, from the other side.

**A per-glyph offset table** — precise, and a lookup nobody will maintain that
is wrong the day a glyph changes. It would also be five numbers saying the
same thing, since the correction is the same half pixel in every case.

## The VPN padlock

Checked while the disc was open, since the hairline makes the rim visible and
any residual offset with it. The padlock is a 9px `Text` anchored bottom-right
inside `networkBtn` with 0/0 margins, and its ink centre lands **11.7px from
the disc centre against a 13px radius**, at 40 degrees below horizontal — a
mark straddling the rim, which is what those margins were retuned for when the
square corner became a disc. Its right edge and its bottom edge are both flush
with the disc's bounding box.

It is 1.5px higher than the comment beside it claims, because the 9px box
carries about 1.8px of unused descent below the ink while the ink is flush to
the box's right edge. That is towards the disc rather than off it, so it is
left alone.
