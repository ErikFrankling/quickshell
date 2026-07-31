# Centred only: the same three facts with nothing on its side

**Question.** `metric-fraction.md` asked where a metric's third fact goes and
answered "in the flank, turned −90°". That shipped in `a01a930` and was
rejected on looks. So: **what does the same problem cost if nothing is rotated
and nothing sits in the flank** — every element vertically stacked and
horizontally centred on the ring?

**Answer.** Twenty-three designs, drawn at the rail's true 58px with the real
ring at real size, measured rather than asserted. The harness is
`metric-centred.qml`; run it with
`quickshell -p docs/surveys/metric-centred.qml` and it prints every table below
to stdout as a TSV.

There is **no `.png` this session** — deliberately. The disk this sheet is about
is at 95% with about 50 GB free, and the sheet's whole point is that it can be
read as numbers by somebody who cannot see it. Everything the picture would say
is in the tables.

## What is measured, and what each column means

| Column | Meaning |
|---|---|
| **claim** | what one element hands the `ColumnLayout`, and therefore what the rail pays. Today's ring claims 28: its caption is anchored to the ring's *bottom edge* (`Ring.qml:154-161`) and hangs outside the box entirely. |
| **ink** | the extent of what is actually drawn. Today that is 38, and the 10px of overhang is paid out of the 9px gap between rings — which is why the rings group's `spacing` is 9 (`shell.qml:570`) and every other rail group's is `Theme.slotGap` = 5. |
| **width** | the widest row's ink. Over 46 leaves the group's ground (`Theme.groupWidth`), over 58 leaves the rail. |
| **min** | the smallest `font.pixelSize` any `Text` in the design actually renders at, read off the built item. |
| **rail** | `stack3 − 102`, where `stack3` is three of these elements at the group's real 9px spacing and 102 is what the three metrics stack today. |

A design **collides** when ink > claim + 10, because 10px is the overhang the
shipped ring already has and reads fine at.

The worst case drawn is this host's, not the one originally asked for:

| Metric | Used | Total | Percent | Wash |
|---|---|---|---|---|
| `ram` | 13 GB | 31 GB | 42% | none |
| `root` | 845 GB | 947 GB | **95%** | **critical — 24% of `Theme.bad`, blinking** |
| `data` | 480 GB | 1968 GB | 26% | none |

## The twenty-three designs

Seven are carried over from the last sheet unchanged, because they were already
centred and their numbers should not be re-derived: designs 2, 3, 4, 5, 9, 12
and 21 there are 2, 3, 4, 5, 6, 7 and 8 here. Every carried-over number was
re-measured by the fork and came back identical, which is the check that the
fork did not quietly change the measurement.

Contrast is the **worst** `Text` in the design, against the ground that text
actually stands on — washed if its centre falls inside the washed circle, plain
if it does not. Drawn palette is Tokyo Night; the floor across all nine curated
palettes is in the next section and is the number that decides.

| # | Design | claim | ink | width | min type | rail | worst contrast | Verdict |
|---|---|---|---|---|---|---|---|---|
| 1 | **Baseline — today, unturned.** Used value in the centre, `/total` as the caption. Two facts. | 28 | 38 | 28 | 8px | **0** | 4.00 | free — the zero for every row below |
| 2 | Name over the ring, fraction under it | 38 | 48 | 39 | 8px | **+30** | 4.00 | costs 30px |
| 3 | Name inside the ring, fraction as the caption | 28 | 38 | 39 | 8px | **0** | 4.00 | free — demotes the number, and `root` becomes `rot` |
| 4 | Two-line caption: name, then fraction | 38 | 47 | 39 | 8px | **+30** | 4.00 | costs 30px |
| 5 | Two-line caption, tucked −3 | 35 | 45 | 39 | 8px | **+21** | 4.00 | costs 21px |
| 6 | Used over total inside the ring, hairline between | 28 | 38 | 28 | 8px | **0** | **2.70** | free — **rejected on contrast** |
| 7 | Abbreviated fraction as the caption (`480/2.0T`) | 28 | 38 | 39 | 8px | **0** | 4.00 | free — still no name |
| 8 | **Name only — the null answer.** Total not shown. | 28 | 38 | 28 | 8px | **0** | 4.00 | free — the design to beat |
| 9 | **One caption line: `name total`** (`ram 31`) ← recommended | 28 | 38 | **44** | 8px | **0** | 4.00 | **free, all three facts** |
| 10 | Two-line caption: name, then total only | 38 | 47 | **28** | 8px | **+30** | 4.00 | costs 30px |
| 11 | The same, tucked −3 | 35 | 45 | **28** | 8px | **+21** | 4.00 | costs 21px |
| 12 | Total inside the ring under the used value, name as caption | 28 | 38 | 28 | 8px | **0** | **2.70** | free — **rejected on contrast** |
| 13 | Percent in the ring, name as the caption, total dropped | 28 | 38 | 28 | 8px | **0** | 4.00 | free — two facts, no gigabytes |
| 14 | Name above the ring, `/total` below it | 38 | 48 | **28** | 8px | **+30** | 4.00 | costs 30px — **runner-up** |
| 15 | Name above the ring, nothing below | 38 | **38** | 28 | 8px | **+30** | 4.00 | costs 30px — the only design whose ink stops at its claim |
| 16 | Both captions hung outside the claim | 28 | **48** | 28 | 8px | 0 | 4.00 | **collides** — 20px of overhang into a 9px gap |
| 17 | Labelled bar: name + percent over a 3px track | 16 | 15 | 42 | 8px | **−36** | 4.00 | saves 36px, drops the ring |
| 18 | Labelled bar, fraction on its own row | 27 | 26 | 42 | 8px | **−3** | 4.00 | saves 3px, all three facts |
| 19 | Bar with name and used value laid inside it | 13 | 13 | 42 | 8px | **−45** | **1.72** | saves 45px — **rejected on contrast** |
| 20 | Ring for ram, bars for the disks | 28 | 38 | 42 | 8px | **−24** | 4.00 | saves 24px, two shapes |
| 21 | ~~Two-line caption `name` / `total` at 7px~~ | 28 | 43 | 28 | **7px** | 0 | 4.00 | **REJECTED** — and collides |
| 22 | ~~Two-line caption at 6px~~ | 28 | 40 | 29 | **6px** | 0 | 4.00 | **REJECTED** — and collides |
| 23 | ~~Used over total inside the ring at 7px~~ | 28 | 38 | 28 | **7px** | 0 | **2.70** | **REJECTED** twice over |

Four are out on geometry and type size alone: **16** collides, and **21**, **22**
and **23** are under the 8px floor. Three more — **6**, **12** and **19** — are
out on contrast, for the reasons in the next two sections. That leaves
**sixteen** to choose from, all of them centred, all upright, none under 8px and
none spending contrast the wash has already claimed.

## Contrast, across every palette he wears

Only text **inside** the ring is ever washed. A caption anchored under the ring
or above it stands on the plain group ground and the wash never reaches it —
which is most of the difference between these designs, and no summary number
can tell you which side of the line a given label is on. The harness works it
out by geometry: it maps every `Text`'s centre into the element and asks which
tinted ground, if any, it falls inside.

There are only nine distinct (ink, ground) pairs on the whole sheet. Measured on
`Themes.qml`'s own curated list — the nine palettes he actually wears — so this
is not one theme's opinion:

| pair | Tokyo Night | Gruvbox | Catppuccin Mocha | Gruvbox Light | Rosé Pine Dawn | Nord | Rosé Pine | Everforest | Kanagawa | **floor** |
|---|---|---|---|---|---|---|---|---|---|---|
| fg 10px on critical wash | 6.97 | 7.31 | 5.68 | 3.37 | 4.65 | 7.16 | 7.90 | 4.14 | 7.15 | **3.37** |
| fg 10px on warning wash | 7.14 | 6.38 | 5.33 | 4.50 | 5.25 | 5.91 | 7.55 | 3.98 | 5.48 | **3.98** |
| fg 10px at the blink floor | 9.82 | 9.25 | 8.19 | 4.84 | 5.83 | 8.49 | 10.95 | 5.33 | 8.06 | **4.84** |
| fg 10px on plain ground | 10.34 | 9.57 | 8.69 | 5.14 | 6.05 | 8.73 | 11.51 | 5.57 | 8.16 | **5.14** |
| fg 8px on critical wash | 6.97 | 7.31 | 5.68 | 3.37 | 4.65 | 7.16 | 7.90 | 4.14 | 7.15 | **3.37** |
| **dim 8px on plain ground** | 4.00 | 3.58 | 3.40 | 3.80 | 3.66 | 2.82 | 4.71 | 2.90 | 2.41 | **2.41** |
| **dim 8px on critical wash** | 2.70 | 2.73 | 2.22 | 2.49 | 2.81 | 2.31 | 3.23 | 2.15 | 2.11 | **2.11** |
| fg 8px on a full bar | 4.44 | 5.11 | 3.28 | 2.07 | 3.34 | 5.46 | 4.41 | 2.92 | 4.65 | **2.07** |
| **dim 8px on a full bar** | 1.72 | 1.91 | 1.28 | 1.53 | 2.02 | 1.76 | 1.80 | 1.52 | 1.38 | **1.28** |

Three things fall out of this table.

- **The 3.37 floor is the one `warning-states.md` already found**, from the other
  direction — it quoted 3.3:1 as the worst the 10px DemiBold centre number gets
  under the critical wash across all 335 schemes. This sweep is the nine curated
  ones only and lands on the same number, which is the check that the two
  measurements agree.
- **The blink makes contrast better, not worse.** `pulse` runs the wash down to
  0.15 of itself and back (`Ring.qml:76-92`), so 0.24 alpha breathes between
  0.036 and 0.24. Full wash is the worse end in every palette, light and dark,
  because a red tint moves a dark ground up and a light ground down and the text
  is on the far side either way. So full wash is what every design here is drawn
  and scored in; the blink's other half is the 4.84 row, and it is slack.
- **`Theme.dim` at 8px is the fragile ink, not the wash.** The shipped caption
  already sits at 2.41:1 in the worst curated palette on a *plain* ground. That
  is the shell's existing floor and this sheet does not get to relitigate it.
  What it does get to say is what happens when that same ink is moved somewhere
  worse.

## The four rejected, and why

**19, the bar with text inside it — 1.72:1 on Tokyo Night, 1.28:1 on Catppuccin
Mocha.** It is the cheapest design on the sheet by a distance, −45px of rail, and
it is the only one that stands 8px `Theme.dim` on a 45%-alpha `Theme.bad` fill.
`warning-states.md` records an earlier wash that left the centre number at 1.3:1
and calls that "not dim, it is gone". This is 1.28. The design is not saved by
using `Theme.fg` for both labels either: that pair floors at 2.07.

**6 and 12, the total inside the ring — 2.70:1 drawn, 2.11:1 at the floor.** Both
put the total in 8px `Theme.dim` inside the washed circle. That is a 32% cut on
Tokyo Night (4.00 → 2.70) and 12% at the floor (2.41 → 2.11), and it lands on the
one ring that has gone critical, which is precisely the ring you are trying to
read. The 10px `fg` centre number can afford the wash — it is measured at 3.37
worst and that was the budget the wash was chosen against. An 8px dim total
cannot; it was never in that budget. Both are free in rail height and both spend
the contrast in the one place the shell has already decided it has none to
spare.

**23, the fraction inside the ring at 7px.** Rejected twice: under the 8px floor
*and* it is designs 6 and 12's contrast problem with a smaller glyph on top.

**21, the new trap: `name` over `total` at 7px.** This is design 10 shrunk until
it stops costing 30px, and it is the sheet's version of last time's design 18.
It fits the ground with 18px to spare, it costs the rail **zero**, and it is a
point below anything else on this bar. It also fails on its own terms — ink 43
against claim 28 is 15px of overhang into a 9px gap, so it collides as well.
Fitting is not the test, and it is worth writing down twice that the thing which
makes a sub-8px design attractive is exactly the thing that should make it
suspect: it is free *because* it is too small.

**22, two lines at 6px**, is the same argument at 6px, where type stops being
small and becomes texture.

**16 is rejected for a different reason and is worth keeping separately.** It is
the first idea anybody has: the caption already hangs outside the claim, so hang
the name outside the top the same way and get design 14 for nothing. Measured,
claim stays 28 and ink goes to 48 — 20px of overhang into a 9px gap. The
overhang budget is not per-edge, it is the gap, and the gap is already spent on
the caption below. Free on paper, collision in fact.

## Two results the last sheet did not have

**Dropping the used value from the caption is worth 11px of width and nothing
else.** Design 4 (`root` over `845/947`) is 39px wide; design 10 (`root` over
`/947`) is 28px, because the ring is already showing `845` and repeating it is
the only reason design 4 was ever wide. Same claim, same ink, same rail cost.
If a two-line caption is chosen at all, there is no case for the four-line
version.

**Putting the name above the ring is not more expensive than putting it below.**
Design 14 and design 4 are both +30. But design 14 is 28px wide against design
4's 39, and design 15 — name above, caption given up — is the only design on the
sheet whose ink equals its claim, which means it is the only one that would let
the rings group's `spacing` drop from 9 back to `Theme.slotGap`'s 5 and hand 8px
of the 30 straight back. That is a real +22 rather than +30, and it is not in the
table because it needs a change to `shell.qml:570` to collect it.

## The recommendation, and what it costs

**Design 9 — one caption line, `name total`.** `ram 31`, `root 947`,
`data 2.0T`, in the caption row the ring already pays for, with the used value
staying at 10px in the centre where it is now.

**Rail cost: zero.** claim 28, ink 38, identical to what ships. All three facts,
nothing rotated, nothing in the flank, nothing under 8px, and no type inside the
wash — the worst contrast in the design is the caption's ordinary 4.00 / 2.41,
which is what every ring caption on the rail already is.

Two things to be honest about:

1. **It is 44px wide on a 46px ground** — one pixel of air a side, and that is
   the same 44px that got `/mnt/data` rejected on the last sheet. The width
   comes entirely from `data 2.0T`; `ram 31` is 30px and `root 947` is 33px. If
   that pixel matters, writing the terabyte total as `2T` rather than `2.0T`
   brings the worst row to 34px, which is inside design 7's 39 and design 3's 39
   and comfortable. That is a one-character change to the formatter, not a
   design change.
2. **The slash is gone.** Every caption under these rings currently begins with
   one. `ram 31` reads as "13 of ram's 31" only because the number above it is
   13; on its own the caption is a name and a number with a space between them.
   `ram/31` measures the same 44px if the space is dropped for a slash, so this
   is a free choice either way and it is his.

**Runner-up: design 14**, name above the ring and `/total` below it. Same three
facts, 28px wide, the slash kept, unambiguous, and direct prior art —
Brainitech's `Speedometer` puts the metric's name above the arc and its
`11.2 / 16 GB` below the centre (`src/components/Speedometer.qml:4-7`,
sizes at `:108-121`). **It costs +30px**, which comes straight out of the 511px
of workspace room the last sheet measured live on a 1080px screen.

**The null answer, if the total turns out not to be worth a row: design 8.**
Name as the caption, total not shown, zero rail, and it is already how `cpu`,
`°c` and `fan` work. Design 13 is the same idea with the percent in the middle
instead of the gigabytes — cheaper to read at a glance, worse to act on, which
is the trade `shell.qml:610-616` already decided once in gigabytes' favour.

## Is the 9px flank wasted if every label is centred?

**No, and the group cannot be narrowed anyway. Keep the air.** Three numbers.

**The flank is what the caption is already standing in.** A 28px ring on a 46px
ground leaves 9px a side, but the ring is not the widest thing on the ground —
the caption is, and always has been. Measured on this sheet: designs 2, 3, 4, 5
and 7 are **39px** wide, designs 17 through 20 are **42px**, and design 9 is
**44px**. The shipped caption `/2.0T` is 24px. Every one of those is wider than
the 28px ring and every one of them is spending the flank. There is no design on
this sheet, centred or otherwise, that would still fit on a 40px ground; four of
them would not fit on a 44px one.

**`Theme.groupWidth` is not the rings' number to give back.** It is one value
shared by every group on the rail — `Group.qml:49` is `implicitWidth:
Theme.groupWidth` and every group inherits it. The widest thing standing on it
is not the ring but the **44px workspace pill** (`Workspaces.qml:158`), which
has exactly the same one pixel of air a side that design 9 does. Narrowing 46
would clip the pills, and narrowing only the rings' ground would put one group
out of line with the other four down a 58px strip, where a 3px misalignment is
the width of the stroke on the ring next to it.

**And it would buy nothing that is scarce.** The rail is 58px wide whatever the
ground does; narrowing the ground returns **0px of rail height**, and height is
the only budget under pressure — it is the only thing the overflow ladder counts
and the only unit every row of the table above is measured in. Trading 6px of
horizontal air, which nothing is competing for, for zero pixels of vertical, which
everything is, is not a trade.

The honest version of the original claim, then, is that the 9px flank was never
"doing nothing". It was doing what the caption needed and had 5px left over,
and the last sheet spent the 5px rather than the 9.
