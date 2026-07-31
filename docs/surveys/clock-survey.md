# Clocks in a 58px vertical rail

The question: hours, minutes, day and month, in a strip 58 pixels wide, in as
little height as possible. This shell's clock cost 92px — the tallest single
thing on a rail that already overflows on a laptop — and it was four stacked
numbers with a hairline through them.

Thirteen real implementations were read and redrawn at true width. The contact
sheet is `clock-survey.qml`; run it with

```bash
quickshell -p docs/surveys/clock-survey.qml
```

`clock-survey.png` is a render of it. Every height in the table below is
**measured**, not asserted: each mock is built to its source's own font sizes,
spacings and padding, and then asked how tall it came out. Point sizes were
converted at 96dpi (`pt x 1.333`).

## The table

| # | Project | Height | Shows | How |
|---|---|---|---|---|
| 1 | noctalia | **100** | `dd` `MM` | one format string, `HH mm - dd MM`, split on spaces into five lines at one size, spacing `-2` |
| 2 | THIS, before | **80** | `dd` `MM` | noctalia's, retuned — 15px time, 11px date dimmed, the dash promoted to a 16px hairline. 92px until the rail lost its rounded groups |
| 3 | end-4 `ii` | **72** | `dd/MM` | 17px `HH`/`mm` tucked `-4` into one block, `dd/MM` at 10px under it, no rule at all |
| 4 | caelestia | **131** | `ddd` `d` | icon, weekday, day, hairline, then `HH`/`mm` pulled up 8. 70px with the date off, which is its default |
| 5 | DankMaterialShell | **100** | `dd` `MM` | every digit its own 7px cell so the columns align in any font; date in the accent rather than dimmed |
| 6 | omarchy-quattro | **99** | — | the format is literally `HH\n—\nmm`; the em dash is a line of text with a whole 27px slot to itself |
| 7 | iNiR | **117** | `dd` `MM` | colon-split `HH`/`mm` at zero spacing, a rule, then the date as a typographic fraction across a drawn diagonal |
| 8 | Whisker | **58** | `dd/MM` | `lineHeight: 0.1` on every line, so each `Text` reports a tenth of its own box and the three collapse into each other |
| 9 | bjarneo | **36** | — | `HH` anchored above `verticalCenter` and `mm` below it, 1px each. No layout, and no date anywhere |
| 10 | nucleus-shell | **66** | — | one `Text`, `hh\nmm\nAP`. The only project that really rotates |
| 11 | Keystone | **92** | `dd MMM` | each digit a 24px window onto a drum of 0–9 that springs into place, each on its own tilt |
| 12 | noctalia binary | **37** | — | binary coded decimal, one dot column per digit |
| 13 | **THIS, after** | **36** | `dd MMM` | time stacked, date turned into the margin it leaves free |

The line that decided it: **bjarneo reaches 36px by dropping the date entirely,
and 36px is also what this design costs with the date kept.** Nothing else in
the survey shows day and month for under 58px, and the one that manages 58 does
it by making every line lie about its own height.

## What each one actually does

### 1. noctalia — `Modules/Bar/Widgets/Clock.qml`

`formatVertical` defaults to `"HH mm - dd MM"` (`Services/UI/BarWidgetRegistry.qml:120`).
The widget splits it on spaces and stacks one `NText` per fragment at a single
size, `spacing: -2` (`:121-140`). So the dash is a line of text, and the design
is entirely a format string — you get more lines by adding more words.

Clicking opens `clockPanel`; right-click offers "open calendar" and widget
settings (`:145-171`). Hovering shows a tooltip whose format is a *third*
setting. The panel (`Modules/Panels/Clock/ClockPanel.qml:31`) is a `Repeater`
over `Settings.data.calendar.cards` — a header card, a month card and a weather
card.

**This shell's clock was this design.** Same five items, same order, retuned.

### 2. THIS, before — `shell.qml`

15px `HH` DemiBold, 15px `mm`, a 16x1 `Theme.line` rule with 5px above and 4px
below, then `dd` and `MM` at 11px in `Theme.dim`. 80px measured bare; it stood
on a `Group` worth another 12px until the rail dropped its rounded grounds this
session, which is the 92px in the brief.

### 3. end-4 `ii` — `modules/ii/verticalBar/VerticalClockWidget.qml`

The neat trick is at `:27`: it splits the **already-formatted** time string on
`/[: ]/`, so one delegate draws `hh:mm` as two lines and `hh:mm AP` as three
without a branch. `text: modelData.padStart(2, "0")`, so a 12-hour "2" becomes
"02" and the columns stay the same width.

Inner column `spacing: -4`, digits at 17px, then `dd/MM` at 10px
(`shortDate` in `services/DateTime.qml:21-25`). No rule, no dimming — **size
alone carries the hierarchy**, which is the cheapest separator there is.
Wrapped by `BarGroup { vertical: true; padding: 8 }`
(`verticalBar/VerticalBarContent.qml:134-141`). Hover opens a popup with the
long date, uptime and a to-do list; it is not a calendar.

### 4. caelestia — `modules/bar/components/Clock.qml`

Its bar is only ever a 40px vertical strip, so this is its native form. Icon,
`ddd`, unpadded `d`, a 1px rule that bleeds 4px past the column on each side,
then hour and minute.

Two details worth taking:

- `Layout.topMargin: -parent.spacing - 4` between hour and minute (`:96`) —
  the two lines are pulled into one block of digits rather than two labels.
  **This design uses that.**
- `:78-108` measures both strings with `TextMetrics` and then stretches the
  narrower one on the variable font's `wdth` axis until the two lines are
  optically the same width, with a hard-coded 1.15 for `"11"`. Beautiful, and
  it needs a variable font this shell does not commit to.

`showDate` defaults to **false** (`plugin/src/Caelestia/Config/barconfig.hpp:118`),
so out of the box it is icon + `HH` + `mm` at about 70px. No `MouseArea` at
all — it is not clickable.

### 5. DankMaterialShell — `Modules/DankBar/Widgets/Clock.qml:24-197`

Every digit is its own `StyledText` in a cell of `round(pixelSize * 0.6)` = 7px,
so the columns line up whatever the font's digit advance is. The rule is 60% of
an already narrow column — a tick, not a divider. The date is drawn in
`Theme.primary`, the accent, while the time is neutral: **the inverse of the
usual "dim the date"**, and it works, because the accent reads as secondary
against white-ish text.

Date order is locale-derived rather than a format string: it reads
`locale.dateFormat(Locale.ShortFormat)` and compares `indexOf('d')` against
`indexOf('M')` (`:132-195`). Clicking opens the DankDash on its overview tab.

### 6. omarchy-quattro — `shell/plugins/panels/clock/BarWidget.qml:154-173`

Vertical rendering is "a format string containing `\n`, one line per icon
slot". The default (`Model.js:20`) is `"HH\n—\nmm"`: the em dash is a real text
glyph with a whole 27px slot to itself, not a `Rectangle`. Lines longer than
three characters drop to 90% size.

The other preset is `"dd\nMMM\n'W'ww\n''yy"` — day, month, ISO week, year, and
no time. Right-click cycles between them and writes the choice back to
`shell.json` (`:39-53`). So **the date is a mode, not a field**: you get the
time or you get the date.

`Ui/OpticalGlyph.qml:14-16,26-37` re-centres each line on its tight bounding box
rather than its advance width, which is what stops a stacked `—` from sitting
off-centre against digits.

### 7. iNiR — `modules/verticalBar/VerticalDateWidget.qml`

**The best single idea in the survey.** The date is a typographic fraction: a
24x30 box with a `Shape`/`PathLine` drawn from (20,4) to (4,26) at
`strokeWidth: 1.2` in the dim colour, `dd` anchored top-left and `MM`
bottom-right, both 13px at full strength. No slash glyph, no rule — the
diagonal *is* the separator, and it makes two numbers unambiguously a fraction.

Its clock (`VerticalClockWidget.qml:18-28`) is end-4's colon-split repeater at
`spacing: 0`. Assembled by `VerticalBarContent.qml:265-300` as clock, rule,
date, rule, battery inside a `BarGroup` with `rowSpacing: 12`.

This was tried as the runner-up here — the fraction shrunk to sit beside the
time rather than under it. At the ~9px that margin allowed, the diagonal and the
digits collided into mush, and the finding written down was that it needs
iNiR's full 24x30 and 13px digits to read.

**That was a finding about the margin, and the margin was a choice.** The 9px
is what a one-line `HH:mm` leaves over; nothing about the fraction requires it.
Stack the time instead — `HH` over `mm`, 18px wide against 45 — and the same
fraction gets 21px of width and 12px digits, nine-tenths of iNiR's own drawing
rather than a third of it. That is what ships now, in `RailClock.qml`: 42x36 in
the 46px ground a rail group draws, measured off a render rather than claimed —
12px of time-digit ink over two lines tucked −4, 9px of date-digit ink with 3px
of ground between `dd` and `MM`, and a 29.4px diagonal where iNiR draws 27.2.

It replaces the one-line design of `clock-compact.md`, which was 30px tall and
45px wide in that same 46px ground. The date goes back to two numbers with it:
the one-line version wrote `dd MMM` because `30` over `07` reads in either
order, and the diagonal is what buys that back — a fraction has a top and a
bottom, so day-above-month is a direction rather than a convention.

### 8. Whisker — `modules/bar/TimeLabel.qml:21-40`

Three lines at 18px ExtraBold, every one given `lineHeight: 0.1` so it reports
a tenth of its natural line box, with negative `spacing` on top. The glyphs
overflow their items and the block collapses. Time in `m3on_surface`, date in
`m3on_surface_variant` — the only design in the survey that dims the date and
keeps it on the strip.

`showLabel` is bound to `Hyprland.currentWorkspace.hasTilingWindow()`
(`vertical/BarLeft.qml:36`): on an empty workspace the whole clock animates its
height and opacity to zero. Hovering opens an interactable calendar popout.

### 9. bjarneo — `desktop/Bar.qml:147-202`

No layout at all. `HH` is `anchors.bottom: parent.verticalCenter` with
`bottomMargin: 1`, `mm` is `anchors.top: parent.verticalCenter` with
`topMargin: 1`, so the two blocks meet on the axis with a 2px optical gap. 11px
mono `Font.Light`, and the `letterSpacing: 2` the horizontal variant uses is
dropped so the two columns stay flush. Hover recolours the whole clock to the
accent over 180ms.

**No date anywhere on the bar** — hovering says "Calendar", clicking opens one.
This is the floor: 36px is what time alone costs.

### 10. nucleus-shell — `modules/interface/bar/content/ClockModule.qml`

One `Text`, format `"hh\nmm\nAP"`. The only project on disk that really
rotates: `BarContent.qml:144-177` turns the whole `Row` 90 degrees so its
children stack down the screen, then turns the clock and the power toggle 270
back so they land upright, and manually swaps `implicitWidth`/`implicitHeight`
on the wrapper because rotation does not affect layout size.

No date in vertical mode, and at 16px plus a hardcoded `+ 40` on width it is
the one design in the survey that does not fit a 58px rail.

### 11. Keystone — `Modules/Keystone/ClockContent/ClockContent.qml:45-120`

Each digit is a 24px-tall `clip: true` window onto a `Text` containing
`"0\n1\n2\n…\n9"` at `lineHeightMode: FixedHeight`, moved by `y: -digit * 24`
with a `SpringAnimation { spring: 3.5; damping: 0.75 }`. Each of the four
digits gets its own `rotation` (-3, 2, 3, -2) and vertical offset, so they sit
like loose type. Date to the left of a `|` at 13px.

It is a wide panel, not a rail widget, and drawing it stacked to compare is
already unfair to it. Kept in the survey because the drum is the most
memorable thing anyone in this list does with a digit.

### 12. noctalia binary — `Widgets/NClock.qml:316-380`

Binary coded decimal: 2, 4, 3 and 4 bits of dots for the four digits, lit
reading up. 37px, the most compact thing here, and unreadable unless you enjoy
counting bits. Its sibling analog style (`:131`) is square, so it costs exactly
its own width — and there is nowhere in a clock face to put a date.

## Things nobody does

- **Nobody rotates clock text.** `grep -rn "rotation: *-\?90"` across all
  twenty-one trees on disk returns media titles, progress arcs, corner
  decorations and iNiR's analog hands — no dates and no digits. nucleus rotates
  its clock only to un-rotate it. So the date turned on its side, below, is not
  a copied idiom; it is this shell's own move, taken from what it already does
  to a media title in `RailPlayer.qml:191`.
- **Nobody shows a weekday on a vertical strip except caelestia**, which shows
  a weekday *instead of* a month.
- **Nobody puts hours and minutes on one line vertically.** `16:05` is 39px
  wide at 13px, which fits 58 — and every project stacked it anyway, because at
  a size you can read across a room two digits is all the width there is.

## What this shell took

`RailClock.qml`:

- caelestia's negative tuck between hour and minute, so the two lines read as
  one block of digits.
- The date turned 90 degrees into the margin the two-digit time leaves free, so
  it costs no height at all. Day first, month in letters — `30 JUL` — because
  two numbers one above the other can be read in either order, and three
  letters cost the same room as two digits.
- The rule kept, but run down instead of across. Across, a hairline is ten
  pixels of nothing; down, it is free.

36px against 92. The date is still there, and it is the only thing in the
survey under 58px that can say that.

`panels/Calendar.qml` is what clicking it opens: a month grid and nothing else.
There is no calendar integration in this shell and there is not going to be, so
a list of events would be a list of nothing. A grid of bare numbers still
answers the question the rail stopped asking — which weekday a date falls on —
and that is worth a page.
