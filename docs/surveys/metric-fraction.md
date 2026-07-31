# Three facts, two strings: labelling a metric that has a used value and a total

**Question.** A rail ring says two things — a number in the middle, a name under
it. Memory and the disks have three to say: a name, a used value and a total.
Where does the third one go, and what does each answer cost in rail height?

**Answer.** In the flank, on its side. It costs nothing. Twenty-one designs were
drawn at the rail's true 58px with the real ring at its real size and measured;
the sheet is `metric-fraction.png` and the harness that produced it is
`metric-fraction.qml`. Run it with
`quickshell -p docs/surveys/metric-fraction.qml` — it prints the table below to
stdout as a TSV as well as drawing it, so the numbers can be checked without
looking at the picture.

## The constraint, stated in pixels

| Thing | Size |
|---|---|
| Rail | 58px wide |
| A group's ground (`Theme.groupWidth`) | 46px, so 6px of rail either side |
| A ring (`Theme.slot`) | 28px, so **9px of unused ground down each flank** |
| The ring's clear middle | 20px — radius 11.5, 3px stroke |
| Centre value | 10px DemiBold |
| Caption | 8px, `Theme.dim` |
| A glyph in this font | 0.609em — measured, not assumed |

Which makes the middle **three characters** at 10px (18.3px of 20) and four
characters impossible (24.4px). `845` fits. `1968` does not. That single fact
decides most of this document.

## The worst case, and why it is not the one that was asked for

The request named `ram 10/15`, `/ 63/500` and `data 274/1800`. This host is
worse, so this host is what was measured:

| Metric | Used | Total | Percent | Longest string |
|---|---|---|---|---|
| ram | 13 GB | 31 GB | 42% | `13/31` |
| `/` | 845 GB | 947 GB | **95%** | `845/947` (7 glyphs, 39px at 8px) |
| `/mnt/data` | 480 GB | 1968 GB | 26% | `480/1968` (8 glyphs, 39px at 8px) |

The `/` row of every mock on the sheet carries its real critical wash — 24% of
`Theme.bad` over the ring's ground, which is what a disk at 95% actually wears
since the warning states landed. Nothing here is measured on a clean background.

## Two heights, because the shipped ring has two

- **claim** — what the element hands the `ColumnLayout`, and therefore what it
  costs the rail. Today's ring claims 28. Its caption is anchored to the ring's
  *bottom edge* (`Ring.qml:141-148`) and hangs outside the box entirely.
- **ink** — the extent of what is drawn. Today that is 38, and the 10px of
  overhang is paid for out of the 9px gap between rings. That is why the rings
  group's `spacing` is 9 and every other rail group's is `Theme.slotGap` = 5.

So 10px of overhang is the tolerance the rail already ships and reads fine at;
past that is a collision. **stack3** is the measured height of all three metrics
together — 102px today — and **rail** is the delta against it, which is the only
number the overflow ladder cares about.

## The twenty-one designs

| # | Design | claim | ink | width | smallest type | rail | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | **Baseline — today.** Used in the centre, `/total` as the caption. No name. | 28 | 38 | 28 | 8px | 0 | free — but says two facts |
| 2 | Name over the ring, fraction under it | 38 | 48 | 39 | 8px | **+30** | costs 30px |
| 3 | Name inside the ring, fraction as the caption | 28 | 38 | 39 | 8px | 0 | free — but demotes the number |
| 4 | Two-line caption: name, then fraction | 38 | 47 | 39 | 8px | **+30** | costs 30px |
| 5 | Two-line caption, tucked -3 | 35 | 45 | 39 | 8px | **+21** | costs 21px |
| 6 | **Name turned into the flank** ← recommended | 28 | 38 | **37** | 8px | **0** | **free, all three facts** |
| 7 | Turned name left, turned total right, no caption | 28 | 28 | **46** | 8px | 0 | free, flush to the ground edge |
| 8 | Whole fraction turned into the right flank | 39 | 44 | 37 | 8px | **+17** | costs 17px |
| 9 | Used over total inside the ring, hairline between | 28 | 38 | **28** | 8px | 0 | free, narrowest — 8px in the wash |
| 10 | Name as caption, total on hover | 28 | 38 | 39 | 8px | 0 | free — third fact is hidden |
| 11 | Percent in the centre, gigabytes on hover | 28 | 38 | 39 | 8px | 0 | free — hides the useful number |
| 12 | Abbreviated fraction as the caption (`480/2.0T`) | 28 | 38 | 39 | 8px | 0 | free — still no name |
| 13 | Full mount path as the caption (`/mnt/data`) | 28 | 38 | **44** | 8px | 0 | fits by 1px a side |
| 14 | Labelled bar: name + percent over a 3px track | 16 | 15 | 42 | 8px | **−36** | saves 36px, drops the ring |
| 15 | Labelled bar, fraction on its own row | 27 | 26 | 42 | 8px | −3 | saves 3px |
| 16 | Bar with name and value laid inside it | 13 | 13 | 42 | 8px | **−45** | saves 45px, drops the ring |
| 17 | Ring for ram, bars for the disks | 28 | 38 | 42 | 8px | −24 | saves 24px, two shapes |
| 18 | ~~Fraction caption at 7px~~ | 28 | 37 | **55** | **7px** | 0 | **REJECTED** |
| 19 | ~~Two-line caption at 6px~~ | 28 | 40 | 29 | **6px** | 0 | **REJECTED** — and collides |
| 20 | ~~Used over total inside the ring at 7px~~ | 28 | 38 | 28 | **7px** | 0 | **REJECTED** |
| 21 | **Name only — the null answer.** Total not shown. | 28 | 38 | 28 | 8px | 0 | free — the design to beat |

### The three rejected on legibility

They are on the sheet, in red, with their numbers, because deleting them only
invites the next session to try them again.

- **18, the 7px fraction caption.** It is the trap: at 7px `/ 845/947` measures
  55px, which *fits the 58px rail*, and it costs the rail nothing. It is also a
  point below anything on this bar and it is sitting under a red wash. Fitting
  is not the test.
- **19, the 6px two-line caption.** This is design 4 shrunk until it stops
  costing 30px. It gets the height back and it is 6px type — not small type,
  texture. It also fails on its own terms: ink 40 against claim 28 is a 12px
  overhang into a 9px gap, so it collides with the ring below it.
- **20, the fraction inside the ring at 7px.** Two 7px lines fit the 20px middle
  with room the 8px version does not have — and the middle is exactly where the
  critical wash is, so this spends contrast and glyph size at the same time, on
  the one ring that goes critical.

Design 9 is the same idea at 8px and is *not* rejected: 8px is the floor, not
below it. It is not recommended either, for a reason the numbers do not show —
it is the only surviving design that puts type inside the washed area at the
caption's size rather than the centre's.

## What everyone else does

Six projects were read. The short version: **nobody puts three facts in a bar
widget**, and **nobody rotates a metric label**.

- **Ricelin** is the closest prior art to the three-fact ring, and it stacks:
  used value in the ring at 20px, name under it at 8.5px, `/ 15 GB` under that
  at 10.5px (`Gakuseei_Ricelin/configs/quickshell/pill/SysmonSurface.qml:244-250`
  and `:142-166`). That is design 4. At this rail's scale it costs 10px a ring.
- **Brainitech's `Speedometer`** puts the name *above* the arc and
  `11.2 / 16 GB` below the centre — its own header comment says so
  (`Brainitech_Brain_Shell/src/components/Speedometer.qml:4-7`, sizes at
  `:108-121`). That is design 2, and it costs the same 10px.
- **Brainitech's `DiskBar`** is the only in-strip mount path found anywhere: a
  fixed 32px elided left label, percent right, `used / total · device` as a 9px
  caption underneath (`src/components/DiskBar.qml:27-31`, `:71`, `:85`). Its
  disks come from `df` and are keyed by *both* device and mount
  (`src/services/system/DiskService.qml:8`, `:19`).
- **noctalia** shows one disk, chosen in a settings combo box
  (`Modules/Panels/Settings/Bar/WidgetSettings/SystemMonitorSettings.qml:307-309`),
  labels it with a `storage` glyph and nothing else
  (`Modules/Bar/Widgets/SystemMonitor.qml:879`), and keeps `used / total` for
  the tooltip (`:136-137`). Its bar string is literally `"{percent}%"`
  (`Assets/Translations/en.json:1892`).
- **whisker** shows an icon at rest and cross-fades to the percent on hover in
  the same slot, both `anchors.centerIn: parent`
  (`corecathx_whisker/modules/bar/CircularProgress.qml:50-67`, `:73-82`). That
  is designs 10 and 11, and it is the best-argued version of hiding a number.
- **Multiple disks are always a `Repeater` in a panel, never in the bar** —
  `Brainitech_Brain_Shell/src/modules/Center/DiskPanel.qml:107-113` and
  `myamusashi_vast-shell/Qml/Modules/Drawers/QuickSettings/PerformancePages/Popup/DiskInfo.qml:100-175`
  are the only two multi-mount renderers found, and both are panels.
- **Rotation is for long free text only.** `shub39_dotfiles/quickshell/bar/
  PlayingMedia.qml:67-80` turns a track title with the canonical width/height
  swap; `Rexcrazy804_Zaphkiel/dots/quickshell/kurukurubar/Widgets/
  CalendarView.qml:51` turns a date. No project turns a metric's name.
- Nobody writes the word "of". Everyone writes `/`
  (`DiskBar.qml:85`, `SystemMenu.qml:446`, `SystemStatsPanel.qml:392`).
- One trick worth stealing later: noctalia pads the used figure to the *total's*
  character width and never renders the total, so a narrow column never jitters
  (`Services/System/SystemStatService.qml:1305-1307`).

So design 6 is borrowed from inside this shell rather than outside it. `RailClock`
already turns the date into the margin its stacked time leaves
(`RailClock.qml:100-118`) and `RailPlayer` turns the track title
(`RailPlayer.qml:222-238`). The rail has two turned labels already; this is the
third, and it is the first one on a metric.

## Does the name belong on every ring?

**No.** Design 21 measures the case: today's ring with the name as its caption
and the total simply not shown is 28 claim, 38 ink, 28 wide — identical to the
baseline, because that is already how `cpu`, `°c` and `fan` work. Six of this
host's seven rings have one number and one name and need no third slot at all.
Adding a flank label to them would be decoration.

Three rings do need it, for two different reasons:

- **ram** has a total that changes the meaning of the number. `13` is not an
  answer; `13` of `31` is.
- **the two disks** need telling apart. Two rings both captioned with a slash
  are two rings that look identical from across a desk.

And the mount **path** does not belong on the rail. Design 13 measures why:
`/mnt/data` at the caption's 8px is 44px on a 46px ground — one pixel of air per
side. That is a measurement, not a design. The last path segment is 19px turned
and sits in 9px of flank with room. The full path lives in the monitor panel,
which is one click away and 430px wide.

## The recommendation, and what was given up

**Design 6.** The name turned into the left flank, the used value in the centre
at 10px where it already was, the total in the caption at 8px where it already
was. Three facts, no new type size, no new height, 37px wide on a 46px ground.

Two things it is worth being honest about:

1. **No other shell does this**, and that is a real argument against it. The
   counter-argument is that no other shell has this problem — noctalia shows one
   disk and hides the pair in a tooltip, Ricelin has a 200px pill to stack in.
   The alternative with actual prior art is design 4, and it costs 30px of a rail
   that is already cramped.
2. **`/` had to become `root`.** A lone `/` rotated −90° is a backslash. Every
   caption under these rings already begins with a slash, so the flank had to
   spell it. Four characters, 19px turned, comfortably inside the ring's 28.

One property the recommendation has that nothing else on the sheet does: the
turned name sits **outside** the ring's box, and the warning wash is
`anchors.fill: parent` on that box. So the third fact is the only one on the ring
that is never washed, never tinted and never blinks — which is exactly right for
the fact that says *which disk this is*, since that is the fact you need most
when the ring has gone red.

**Runner-up:** design 4, the two-line caption. Same three facts, nothing rotated,
direct prior art in Ricelin. Take it if the turned name reads as decoration
rather than as a label. It costs 30px of rail.

**Rejected but tempting:** design 14 and 16, the labelled bars, which *save* 36
and 45 pixels. They are genuinely cheaper and they are the right shape for a
capacity. They were not taken because the rail would then carry two shapes for
the same kind of fact, and because `panels/Monitor.qml` already draws exactly
that bar — one click away, at 430px, where a bar has room to be labelled
properly.

## Rail budget

Nothing moved. Measured live on the running shell, seven rings (cpu, ram, gpu,
°c, fan, `/`, `/mnt/data`) on a 1080px screen:

| | Before | After |
|---|---|---|
| `rings.implicitHeight` | 250 | **250** |
| `ringBox.implicitHeight` | 262 | **262** |
| `rail.fixed` less the player | 426 | **426** |
| Workspace room (`rail.wsRoom`) | 511 | **511** |

`rail.fixed` itself reads 530 before and 589 after, and the entire 59px is
`playerGroup` growing when something started playing — the rings contributed
zero. The overflow ladder is untouched and the metrics group is still centred on
the rail's midpoint.

Verified on the live rail by pixel count rather than by eye: flank ink appears in
exactly three bands — y458-471 (`ram`, 14px), y604-622 (`root`, 19px), y641-659
(`data`, 19px) — at x7-14, inside the 46px ground and clear of the ring box at
x15. The other four rings have no flank ink at all. Centre values measure 17px
(`845`) and 16px (`480`) in a 20px clear middle; captions measure 19px (`/947`)
and 24px (`/2.0T`).
