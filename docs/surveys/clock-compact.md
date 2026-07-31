# Below 36px

The first survey (`clock-survey.md`) asked how thirteen shells fit hours,
minutes, day and month into a 58px vertical rail, and the answer that came out
of it was `RailClock.qml` at 36px: `HH` over `mm` tucked together, a vertical
hairline, and `30 JUL` turned −90° into the margin the two-digit time leaves
free. The date cost no height at all.

This survey asks the obvious next question — can it go lower — and finds that
it can, by 8px, and that the way down is not a smaller font. It is turning the
clock the other way.

```bash
quickshell -p docs/surveys/clock-compact.qml
```

`clock-compact.png` is a render of it. Sixteen strips at the rail's true 58px,
each measured for height **and width**, with `RailClock` imported rather than
redrawn so the baseline number cannot drift.

## Why width is on this sheet and was not on the last one

Every one of the thirteen designs in the first survey stacks. The time is two
lines down the rail and the date is more lines under it, so the only axis that
ever ran out was height, and nobody measured width.

But the rail is 58px wide and this shell's font resolves to JetBrains Mono at
about 0.6em per glyph. That is nine characters of room at 10px and six at 15px.
`17:47` is five. **A whole `HH:mm` fits across the rail at the rail's own type
size with a third of the width still spare** — and it costs one line instead of
two.

Once the time goes horizontal, width becomes the binding constraint, and it
disqualifies the shortest design on the sheet. So it is measured too.

## The table

Height and width are both measured at render. "Beats 36" is against the shipped
`RailClock`.

| # | Design | Height | Width | Verdict |
|---|---|---|---|---|
| 1 | **Row, date under** — `HH:mm` 15px over `dd MMM` 9px, tucked −4 | **28** | 45 | **recommended** |
| 2 | Row, date under, big — 16px time, 10px date | 34 | 48 | beats 36 |
| 3 | Row, no date — 18px `HH:mm` alone | 24 | 54 | beats 36, drops the date |
| 4 | Row, no date, small — 15px `HH:mm` alone | 20 | 45 | beats 36, drops the date |
| 5 | Hairline colon — `17`│`47` at 16px, date under | 32 | 45 | beats 36 |
| 6 | Split flank — `30` and `JUL` turned either side of a 15px time | 18 | **67** | **too wide for the rail** |
| 7 | Split flank, made to fit — colon dropped, time down to 12px | 18 | 57 | fits, but see below |
| 8 | Row, date turned — horizontal time, `RailClock`'s turned date beside it | 36 | 57 | no gain |
| 9 | Row, turned digits — the same with `30/07` | 30 | 57 | beats 36, ambiguous date |
| 10 | Time turned — `HH:mm` as one turned line | 48 | 20 | no gain |
| 11 | Time+date turned — everything on one turned line | 124 | 20 | no gain |
| 12 | Watermark — date inside the time's own box at 0.2 alpha | 23 | 51 | **rejected — contrast** |
| 13 | Micro date — design 1 with the date at 7px | 28 | 45 | **rejected — type size** |
| 14 | Sandwich — date between hour and minute, AsteroidOS `digital-outfit` | 45 | 32 | **rejected — type size** |
| 15 | Analog — a 24px dial with the date under it | 36 | 36 | **rejected — precision** |
| 16 | `RailClock`, the baseline — stacked time, turned date | 36 | 41 | — |

## What the numbers say

**Turning the time sideways is what saves the height, and nothing else is.**
Designs 8, 9 and 10 all keep some part of the vertical idea and all land within
6px of the baseline or worse. Design 8 is the clearest: horizontal time with
`RailClock`'s own turned date next to it measures 36px, exactly the baseline.
The baseline's 36px was never the cost of the stacked time — it is the cost of
the turned date. `30 JUL` is six glyphs at 9px with 0.5 letterspacing, which is
36px of column whichever way the time beside it is laid out. Laying the time
down underneath a 36px column buys nothing.

**Rotating the reading direction is a loss, not a win.** Design 10 turns the
whole `HH:mm` into one column: 48px, worse than the baseline, and you have to
tilt your head. Design 11 takes it to its conclusion — time and date on one
turned line — and measures 124px, taller than the 92px design this whole
exercise started from. This is worth stating plainly because it reads like it
should be the compact answer: no leading, no separator, one line. Five glyphs of
15px monospace is 45px of rail whichever axis you spend it on.

No project in either survey turns a clock's reading direction. nucleus-shell is
the only one that rotates at all, and it rotates the row 90° and the clock 270°
back so the text lands upright (`bar/content/ClockModule.qml`, placed by
`BarContent.qml:144-177`). A sweep of both clone trees for `rotation: 90` and
`rotation: -90` in bar widgets returns hands on analog faces, corner masks and
arc offsets — no rotated clock text anywhere.

**The date costs 8px, and the row saves 8px.** Design 4 is design 1 with the
date deleted: 20px against 28px. So the entire day-and-month costs eight pixels
of rail — and moving to a row saves eight pixels on its own. Keeping the date is
free relative to what ships today.

## What was rejected, and on what grounds

The floor is what already ships: nothing smaller than **9px**, nothing dimmer
than **`Theme.dim`**. `RailClock`'s turned date is already 9px `Theme.dim`, so
that is a floor Erik has already accepted in practice rather than one invented
here. Four designs break it. All four are drawn and measured on the sheet in red
rather than deleted, so the next person to have the idea can see the number.

- **12, Watermark** — the date drawn inside the time's own bounding box, so it
  costs zero pixels. It cannot work, and the reason is structural rather than a
  matter of tuning: the only way two strings share one box is for one of them to
  get out of the way, and the only way it gets out of the way is alpha. Drawn at
  0.2, which is the alpha noctalia uses for a binary dot that is *off*
  (`Widgets/NClock.qml:316-426`) — the contrast of something deliberately
  reading as not-there.
- **13, Micro date** — design 1 with the date at 7px. It measures 28px, the same
  as the recommendation, so it does not even buy anything, and it is a smudge at
  arm's length. Nothing in either survey ships a date under 9px: end-4 and iNiR
  stop at 10, noctalia at 8pt (11px), DankMaterialShell at 12.
- **14, Sandwich** — AsteroidOS's `digital-outfit` watchface puts the date on
  its own line *between* the hour and the minute: hour at 0.4 of the face,
  minute at 0.4, date at 0.1 in the gap
  (`AsteroidOS/asteroid-launcher`, `src/watchfaces/007-digital-outfit.qml`). It
  is a lovely face. Held to its own proportions against a 15px time the date
  lands at 4px; drawn at 8px here to be visible at all, it is still under the
  floor — and three lines is three lines, so it measures 45px anyway.
- **15, Analog** — a 24px dial with the date under it. noctalia ships an analog
  style (`Widgets/NClock.qml:133-231`) but as a square panel widget, never in
  the bar. At 24px the minute hand tip moves about a third of a pixel per
  minute. You can see that it is roughly quarter past, which is not what a clock
  is for.

**6 and 7, the split flank**, were not rejected on legibility — they were the
most promising idea on the list and they are worth understanding. The date is
cut in half and stood up on both sides of the time, so neither turned column is
longer than the single line between them: `30` is two glyphs, `JUL` is three,
and both are shorter than one line of 15px type. That gets the height to **18px**,
half the baseline, and it is the best height on the sheet.

It fails on width. Two turned slots plus a five-glyph time is 67px, and the rail
is 58. Design 7 is the same idea forced to fit — colon dropped, time down to
12px — and it does fit, at 57px and 18px tall. But look at what paid for it. The
time is now smaller than every other label on the rail, and it has lost its
colon, so `2207` has to be parsed rather than read. That is spending the one
element that must be legible in order to win a number.

## The recommendation: design 1

`HH:mm` at 15px on one line, `dd MMM` at 9px `Theme.dim` under it, pulled
together by −4. **28px**, 45px wide, against the baseline's 36.

The −4 is not a squeeze in the sense that designs 12–14 are. Digits have no
descenders, so the four pixels a 15px line reserves below its baseline are
simply empty, and the date moves up into space nothing was using. It is
caelestia's tuck (`modules/bar/components/Clock.qml:96`) spent on the gap
between time and date rather than the gap between hour and minute. The render at
4× shows the two lines close but not touching.

What makes this the recommendation rather than design 7 is that **it is the only
design on the sheet that gets shorter while getting easier to read**:

- `HH:mm` on one line is a *time*. `HH` over `mm` is two numbers you assemble
  into a time. The baseline made the rail read the clock vertically; nothing
  else on the rail asks that.
- The date is the same 9px `Theme.dim` it already is, but upright rather than
  turned −90°. Strictly better at the same cost.
- The time stays at 15px, which is the rail's own size, so the clock does not
  become the one thing on the bar set in smaller type.

Nothing was traded for the eight pixels. Every other design on the sheet that
beats 36px pays with something: 3 and 4 drop the date, 7 shrinks the time, 9
turns the month back into a number that reads the same in either order.

If Erik wants it more legible rather than more compact, **design 2** is the same
layout at 16px/10px for 34px — still under the baseline, with more air between
the lines.

## Does the date belong in the rail at all?

Yes, and the numbers support keeping it rather than dropping it.

The case for dropping it is real and worth stating: the clock opens a calendar
page, that page shows the date in full, and design 3 puts an 18px `HH:mm` in
24px of rail — the largest, most readable clock in either survey. bjarneo does
exactly this (`desktop/Bar.qml:147-202`: no date on the bar, "Calendar" on
hover, a calendar on click), and Brainitech swaps the date into the same `Text`
on right-click so it costs nothing at all
(`src/modules/Right/Clock.qml:15-51`).

But the arithmetic does not support it here. The date costs **8px** — design 1
at 28px against design 4 at 20px — and the move to a row saves 8px by itself.
Dropping the date from a row clock would buy back another eight pixels on a rail
that has just been given eight, to remove something Erik asked for by name. A
glanceable date is worth 8px of a 1080px rail; the two lines it used to cost
were not.

The honest version of "time only" is design 3, not design 4: if the date goes,
spend some of what it saved on 18px digits. That is a 24px clock, 4px shorter
than the recommendation. Four pixels is not worth a trip to the calendar page to
find out what day it is.

## If design 1 is chosen

`RailClock.qml` is owned by another agent this session and has not been touched.
The change would be, precisely:

- Replace the outer `Row` with a `Column { spacing: -4 }`.
- One `Text` for the time: `Qt.formatDateTime(clock.date, "HH:mm")`,
  `pixelSize: 15`, `Font.DemiBold`, `Theme.fg`.
- One `Text` for the date: the existing `dd MMM` uppercase at `pixelSize: 9`,
  `letterSpacing: 0.5`, `Theme.dim` — unrotated, so the `TextMetrics`, the
  turned `Item` and its `advanceWidth` sizing all go away.
- The vertical hairline goes too. It separated a stack; a row does not need it,
  and design 5 measures the version that keeps it as a colon substitute at 32px,
  4px worse.
- Keep `active` driving the date's colour to `Theme.fg`, and add
  `font.features: ({ tnum: 1 })` to the time. Tabular figures matter more in a
  fixed-width slot than anywhere else: proportional digits make a centred clock
  shuffle sideways every minute. noctalia sets this on both its bar clocks for
  that reason (`Modules/Bar/Widgets/Clock.qml:108,135`).

That is a shorter file than the one it replaces.

## What happened next: width won again

Design 1 shipped, at 30px. It lasted until Erik looked at the rail and said the
clock looked like it was almost overflowing, which is this sheet's own number
read from the other side: 45px wide, in a ground that is `Theme.groupWidth`, 46.
The sheet was right that width is the binding constraint once a clock goes
horizontal — it just measured width against the 58px rail rather than against
the 46px ground the group actually draws, and the shortest design on the sheet
was also the widest thing on the rail bar the workspaces.

What replaced it is design 7 of the *first* survey, iNiR's, assembled the way
neither sheet tried: the time stacked so it costs 18px of width instead of 45,
and the date as the typographic fraction in the 21px that frees. **42x36**, so
it gives back the 6px this sheet saved and buys 2px of air either side of the
clock inside the ground. `clock-survey.md:130` carries the measurements, and
why the "collapses into mush" finding against that fraction did not survive the
time being stacked.

## Sources read for this sheet

On disk, under the session's clone and repo trees: `tripathiji1312_quickshell`
(`modules/bar/components/Clock.qml:17-78` — the best compact-horizontal
reference, `HH`/`:`/`mm` as three separate `Text`s at 12px with the date beside
rather than below), `luyu-wu_Config` (`quickshell/components/Clock.qml:31` —
three literal spaces as the separator), `Brainitech_Brain_Shell`
(`src/modules/Right/Clock.qml:15-51` — date replaces time in the same `Text` on
click), `bjarneo_quickshell` (`desktop/Bar.qml:147-202`), `Axenide_Ambxst`
(`modules/components/Separator.qml` — one separator component that flips
orientation), `shub39_dotfiles` (`quickshell/bar/PlayingMedia.qml:66-85` — the
`Layout.preferredWidth: <text>.implicitHeight` swap that is the correct way to
reserve space for rotated text), `Rexcrazy804_Zaphkiel`
(`kurukurubar/greeter.qml:71-91` — sizing a rotated slot from
`contentWidth`/`contentHeight`), `maxchennn_vroomies`
(`components/Clock.qml:54-63` — anchor-offset overlap rather than a layout),
`na-ive_nandoroid-shell` (`widgets/clock/RotatingDate.qml` — the date laid
character by character around a circle), and the noctalia checkout
(`Modules/Bar/Widgets/Clock.qml`, `Widgets/NClock.qml`).

Off disk, over HTTP: AsteroidOS's watchfaces
(`AsteroidOS/asteroid-launcher`, `src/watchfaces/007-digital-outfit.qml` and
`011-bold-hour-bebas.qml`) — the other discipline that has to fit a clock into a
space with no room, and the source of design 14. Seventeen watchfaces ship in
that repo; two were read. `digital-outfit` puts the date on its own centred line
between hour and minute, and `bold-hour-bebas` drops the date entirely and
orbits the minute around the hour at `0.364` of the face radius — which is the
same trade as designs 3 and 4 here, made by people whose display is smaller than
this rail is wide.
