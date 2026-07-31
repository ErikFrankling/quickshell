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
   comes entirely from `data 2.0T`; `ram 31` is 29px and `root 947` is 39px —
   the 30 and the 33 this line first carried were wrong, and the corrected
   numbers are re-measured off the built items and off the rendered rail in
   "What shipped" below. If that pixel matters, writing the terabyte total as
   `2T` rather than `2.0T` brings the worst row to 34px, which is inside design
   7's 39 and design 3's 39 and comfortable. That is a one-character change to
   the formatter, not a design change.
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
is not the ring but the caption itself. ~~The **44px workspace pill**
(`Workspaces.qml:158`) has exactly the same one pixel of air a side that design
9 does.~~ **That was wrong, and it is corrected below** — the pill does not
stand on this ground at all. Narrowing 46 would still be wrong for the second
reason given here: narrowing only the rings' ground would put one group out of
line with the other four down a 58px strip, where a 3px misalignment is the
width of the stroke on the ring next to it.

**And it would buy nothing that is scarce.** The rail is 58px wide whatever the
ground does; narrowing the ground returns **0px of rail height**, and height is
the only budget under pressure — it is the only thing the overflow ladder counts
and the only unit every row of the table above is measured in. Trading 6px of
horizontal air, which nothing is competing for, for zero pixels of vertical, which
everything is, is not a trade.

The honest version of the original claim, then, is that the 9px flank was never
"doing nothing". It was doing what the caption needed and had 5px left over,
and the last sheet spent the 5px rather than the 9.

## What shipped

**Design 9, unabbreviated, without the slash, plus a charging mark on the
battery.** `Ring.qml`'s turned name is gone and with it the whole flank idea;
the caption is now the only place a ring says anything in words, and it carries
one word or two.

Rendered on the live rail, ink bounding box read off a screenshot rather than
off the layout, Gruvbox dark on a 1920×1080 output:

| ring | caption | advance box | rendered ink | x on the 46px ground |
|---|---|---|---|---|
| cpu, gpu, fan | `cpu` | 15 | 14 | 22..35 |
| °c | `°c` | 10 | 10 | 24..33 |
| ram | `ram 31` | 29 | 29 | 15..43 |
| disk `/` | `root 947` | 39 | 39 | 10..48 |
| disk `/mnt/data` | **`data 2.0T`** | **44** | **43** | **7..49** |
| battery, on battery | `bat` | 15 | 15 | 22..36 |
| battery, on mains | `bat 70` | 29 | 27 | 15..41 |

The widest row on the rail is `data 2.0T`: a 44px advance box carrying 43px of
ink, standing on a 46px ground, so one pixel of air on the left and two on the
right. `TextMetrics.advanceWidth` says 43.17 and the screenshot says 43 lit
pixels; both agree with the sheet's 44.

**The rail did not move.** Measured live off `ringBox.implicitHeight` and
`rail.fixed`, before and after, on the same host with the same tray and no VPN:

| | ringBox | rail.fixed | rail.inner | elastic | trayMax |
|---|---|---|---|---|---|
| before | 262 | 595 | 1072 | 477 | 14 |
| after | 262 | 595 | 1072 | 477 | 14 |

262 is also what the group measures on screen — the rings' ground runs y=409..670
in the capture, which is 262 rows. Seven rings at 28 with six 9px gaps and 6px of
pad each side is 262 exactly, and the caption still hangs outside all of it.

### The total is not abbreviated

`data 2.0T` stays `2.0T`. `data 2T` measures 34 and looks like ten pixels of
headroom, but it is not headroom: **`data 1.5T` measures 44 as well.** Stripping
a trailing zero only helps a disk whose size happens to round to a whole
terabyte, and rounding for real — `(1500/1000).toFixed(0)` — would print `2T`
over a 1.5 TB disk, which is the sort of number you have to distrust before you
can act on it and the whole reason this ring reads in gigabytes rather than in
percent. Buying a guaranteed 34px means lying about a third of a disk.

~~The 44px is also not a new precedent here. It is the width of the workspace
pill (`Workspaces.qml:158`), which has stood on this same 46px ground with the
same pixel of air a side since it was drawn.~~ **Struck: the pill is not on this
ground.** See "The ground was widened" below — the pill is 44px on the
*full-width* workspaces block and has 7px of rail a side, so it never was the
precedent quoted here. And `/mnt/data` on the last sheet was not
rejected *for* being 44px — `metric-fraction.md:76` records design 13 as "fits by
1px a side" and the reason given at `:172-177` is that a mount **path** does not
belong on the rail. The 44 was quoted in that argument, not the argument.

### The slash is dropped

Measured: `ram/31` and `ram 31` are both 29px, `data/2.0T` and `data 2.0T` both
44. The font is monospaced, so a slash and a space are the same cell and the
choice is free in every direction.

It goes because the caption is no longer a fraction. The numerator is inside the
ring; a slash between a *name* and a total asserts a ratio between two things
that are not in one. And the battery now writes `bat 87` in the same row, where
the second number is the current charge rather than a total — a slash there
would be a plain lie, and one caption grammar across every ring is worth more
than an ambiguity a slash does not actually resolve.

## The charging mark

`Sys.charging` already existed and nothing drew it. Erik: "the battery thing
needs a charging indicator — needs to show clearly when it's charging."

**While on mains the two facts trade places: a bolt takes the ring's middle at
14px and the charge drops into the caption's second word.** `bat 87`, in the
grammar design 9 has just given every other ring. Nothing else changes — the arc
still runs on the charge, the ground still washes on the warning level, and the
blink is still gated off by the same `!Sys.charging` it always was.

### What the reference shells do

Thirteen trees with a battery widget, and the charging cue falls into three
schools:

| school | projects |
|---|---|
| **overlay a bolt on the level graphic** | noctalia (`Modules/Bar/Widgets/NBattery.qml:187-204`), tripathiji1312 (`modules/bar/components/Battery.qml:182-197`) |
| **replace the level glyph** | Zaphkiel `BatteryPill.qml`, Brainitech `BatteryStatus.qml:72-80`, liixini `TopBar.qml:1004-1006`, josecriane `StatusIcons.qml:261-291`, doannc2212 `SystemInfo.qml:80`, bjarneo `Bar.qml:573-591` |
| **recolour the fill, no glyph at all** | myamusashi vast-shell (`Qml/Widgets/Battery.qml:59-68`) |

Every one of them puts a *shape* on it except vast-shell. Several animate — glyph
frame-cycling at 600–650ms (Brainitech `:72-80`, Zaphkiel `:82-91`), a shimmer
sliding across the fill (Ricelin `Osd.qml:483-502`), a fill sweeping past the
true level to 100% and snapping back (vast-shell `:103-163`).

**And his own waybar answered this exact question with a glyph and nothing
else.** The bolt is hard-coded into the AC-side format string —
`"format": " {icon} {capacity}%"`, `config.jsonc:55` — `format-charging` is never
set, and there is no `#battery.charging` rule anywhere in `style.css`. So on
mains at 25% that bar still went orange and simply stopped blinking. This ring
now does the same thing, with the same glyph: **nf-fa-bolt, U+F0E7**, the
character in that config line.

### Why a glyph and not a colour, and why not an animation

**A hue would be unreadable on two of the nine palettes he wears.** Measured off
`Themes.qml`'s own curated list: `Theme.good` and `Theme.accent` are *the same
colour* on Everforest — `#a7c080` both — and 1.02:1 apart on Nord. A ring that
said "charging" by turning its arc green would say nothing at all on either.

| | Tokyo Night | Gruvbox | Catppuccin | Gruvbox Light | Rosé Pine Dawn | Nord | Rosé Pine | Everforest | Kanagawa |
|---|---|---|---|---|---|---|---|---|---|
| good vs accent | 1.38 | 1.20 | 1.42 | 1.36 | 1.61 | **1.02** | 1.23 | **1.00** | 1.27 |

**And a green bolt would spend contrast the wash has already claimed** — the way
designs 6, 12 and 19 died. `Theme.good` at the ring's centre floors at 2.83:1 on
a plain ground and **1.86:1** under the critical wash, which is the state a
charging low battery is actually in. Drawn in `Theme.fg` the mark introduces no
new (ink, ground) pair at all: it is the same ink in the same place as the number
it replaces, so it inherits that number's measured budget exactly and there is
nothing new to score.

**No animation, deliberately.** Six of the reference shells move something while
charging. This rail already has one rule about motion, and it is his:
`warning-states.md` — blink what he can answer, colour what he cannot, which is
why `#memory` in his own stylesheet carries the timing properties and is never
given a keyframe. Charging is not a thing to answer. A mark that moves whenever
the laptop is plugged in is a mark that is moving most of the time, and the whole
value of the blink is that it is rare.

### It composes with the warning states

Charging at 8% is a real state and it is the one that had to be got right.
Captured on the live rail with the states forced through
`~/.config/erikshell/metrics.json` and faked values, ground colour read out of
the screenshot at the ring's centre:

| state | ring ground | middle | caption | blink |
|---|---|---|---|---|
| 70%, on battery | `#32302f` — plain | `70` | `bat` | no |
| 70%, on mains | `#32302f` — plain | **bolt** | `bat 70` | no |
| 8%, on mains | `#623730` — **full** critical wash | **bolt** | `bat 8` | no, held steady |
| 8%, on battery | `#503430` — mid-breath | `8` | `bat` | yes |

`#623730` is `Theme.bad` at 0.24 over `Theme.bgHi` to the byte, which is the
check that the charging ring is wearing the *full* wash rather than a softened
one: the ground still shouts the charge, and the bolt over it says which way it
is going. Nothing was taken off the warning to make room for the mark.

The two grounds never argue because they answer different questions. The wash is
how much is left. The middle is which way it is moving. And the caption is the
number, wherever it happens to be sitting.

### Contrast, plain and washed

The mark is `Theme.fg` at 14px in the ring's middle, so it stands where the
centre number stands and scores as the centre number scores. The caption is
`Theme.dim` at 8px and — verified by pixel, not by assumption — **never stands on
a wash**: at 8% charging the caption ground sampled `#32302f` at both ends while
the ring's own middle was `#623730`. The wash is a disc on the 28px ring box and
the caption is anchored below its bottom edge.

| ink / ground | Gruvbox dark | Everforest | Tokyo Night | Gruvbox Light | floor over all nine |
|---|---|---|---|---|---|
| centre number or bolt, plain | 9.57 | 5.57 | 10.34 | 5.14 | **5.14** |
| centre number or bolt, warning wash | 6.38 | 3.98 | 7.14 | 4.50 | **3.98** |
| centre number or bolt, critical wash | 7.31 | 4.14 | 6.97 | 3.37 | **3.37** |
| caption, plain ground — its only ground | 3.58 | 2.90 | 4.00 | 3.80 | 2.41 |
| *rejected:* a `Theme.good` bolt, plain | 6.36 | 4.70 | 7.97 | 2.83 | **2.83** |
| *rejected:* a `Theme.good` bolt, critical wash | 4.86 | 3.49 | 5.37 | 1.86 | **1.86** |

3.37 is the same floor `warning-states.md` measured across all 335 schemes and
the same one the sheet above measured across the curated nine, unmoved: the
charging state adds no ink this rail was not already carrying. The caption's 2.41
is the shell's existing caption floor on a plain ground and is not this sheet's
to relitigate; what matters is that the charging state does not move it either.

### Two things to know about it

**`Sys.charging` means "not discharging", not "Charging".** `Sys.qml:378` reads
`v.st !== "Discharging"`, so the bolt is up at `Full` and at the `Not charging` a
laptop held at a charge limit reports. That is the same fact the blink and the
low-battery notification are already gated on, and splitting it would mean two
names for one reading in three places. If he wants a strict `Charging`,
`Sys.qml` needs `readonly property bool onMains: v.st !== "Discharging"` kept as
it is and a new `charging: v.st === "Charging"` beside it, with the ring reading
the second and the blink and the notification keeping the first — one property,
one line in the same `onStreamFinished` block that already parses `st`.

**Time-to-full is not worth a fork and is not cheap from sysfs.** Every reference
shell that shows one — Ricelin `Singletons/Battery.qml:37-38`, whisker
`services/Power.qml:20-28`, josecriane `modules/popups/Battery.qml:37`, Zaphkiel
`PowerInfo.qml:47-50` — takes it from UPower's `timeToFull`, and **not one of the
thirteen computes it from `charge_now`/`current_now`**. Doing that arithmetic
here would mean two more sysfs reads on a poll that is already the shell's
second-most expensive, to produce a figure that swings by tens of minutes with
the load, for a row the caption does not have anyway: `bat 2h14` is 34px and
would have to displace the charge to get there. The bolt says it is charging;
the panel is a click away and 430px wide.

## The ground was widened: `Theme.groupWidth` 46 → 50

Erik, on the shipped rail: *"see here needs to be extended a bit, that
background colour — 'bat' text is going too far."* The sheet above had already
measured why. `data 2.0T` puts down 43px of ink in a 44px advance box on a 46px
ground: **1px of air on the left, 2 on the right.** Ink that close to the edge of
the surface it stands on does not read as fitting, it reads as overflowing, and
the sheet's own answer at the time — keep 46, the pill lives there too — rested
on a fact that turns out not to be true.

**The ground is 50 now, and nothing else moved.**

### What 50 buys, measured on the live rail

Gruvbox dark, 1920×1080, ink bounding boxes read off `grim` captures of the
`0,0 58x1080` strip and counted per pixel column, not off the layout.

| | ground x | rail either side | `data 2.0T` ink x | air L / R |
|---|---|---|---|---|
| before, `groupWidth` 46 | 6..51 | 6, 6 | 7..49 | **1 / 2** |
| after, `groupWidth` 50 | 4..53 | 4, 4 | 7..49 | **3 / 4** |

The caption does not move — it is centred on a ring that is centred on a group
that is centred on the rail, so all three share x=28.5 and the ground grows
symmetrically around the ink. Every other caption gains the same 2px a side:
`root 947` goes from 4/3 to 6/5, `ram 31` from 9/8 to 11/10, and the naked ones
(`cpu`, `fan`, `°c`) were never close.

All four grounds still start and end on the same x — 4..53 for the metrics, the
player, the radios and the clock — measured in the same capture. The workspaces
block is full rail width and is a different shape on purpose (see `Group.qml`).

### Why 50 and not 52, and not 48

The rail is **58 and is not moving**: it is the exclusive zone, and a panel
attaches flush to its right edge and tucks a pixel under it
(`CardShape.qml:91`, `x: -overlap`). So every pixel the ground takes is a pixel
of rail channel given up, and the only question is where that trade stops
paying.

- **48** gives the caption 2/3 and leaves 5px of rail. It is half a fix — one
  pixel more than the state Erik complained about.
- **50** gives 3/4 and leaves 4px of rail. Three to four times the air, and 4px
  is still a channel: it is wider than the 3px stroke the rings are drawn with,
  so the eye still reads a rail with grounds on it.
- **52** gives 4/5 and leaves 3px. One further pixel of air for a quarter of the
  channel, with a 10px corner radius (`Theme.radiusS`) curving into a 3px gap
  and the panel seam a pixel beyond that. At that point the group reads as
  having slipped off the rail rather than as sitting on it.

### The rail did not move

Read live off the running instance, before and after, same host, same tray, no
VPN:

| | ringBox | playerGroup | clockGroup | rail.fixed | inner | elastic | trayMax | rail |
|---|---|---|---|---|---|---|---|---|
| before | 262 | 163 | 48 | 595 | 1072 | 477 | 14 | 58×1080 |
| after | 262 | 163 | 48 | 595 | 1072 | 477 | 14 | 58×1080 |

`hyprctl monitors` reads `reserved: [58,0,0,0]` after the change, with one shell
instance running. Width is the only thing that changed and no height depends on
it.

### The two groups that size themselves from it are better for it

`RailPlayer.qml:112` and `RailClock.qml:109` both draw their open-panel ground
at `Theme.groupWidth - 4`, so it went 42 → 46 with no edit. Measured with each
panel open: the box is x 6..51 inside a ground at 4..53, still exactly 2px in on
each side, which is what those comments say it is for. The clock is the one that
gains: its digits are 42px wide, so the old 42px box put the wash's edge
*exactly* on the outermost glyphs and the new one leaves 2px of ground between
them. Their comments still say "46px ground" and now mean the box rather than
the ground; neither file was in scope to re-word.

### Correction: the workspace pill is not on this ground

Two passages of this sheet — the struck sentences under "Is the 9px flank
wasted" and "The total is not abbreviated" — both said the 44px pill
(`Workspaces.qml:158`) stands on the same 46px ground with the same pixel of air
a side, and used that as the precedent for leaving the caption at 44. **It does
not.** The pill is
inside `wsBlock`, which is `Layout.fillWidth: true` on a 58px rail — it is the
one block that is deliberately full width and runs square into two screen edges.
Measured: the pills render at x 7..50, which is 44px with **7px of rail on each
side**, before and after this change, untouched by `Theme.groupWidth` in either
direction. Nothing in `Workspaces.qml` needs adjusting for a wider ground, and
the pill was never the thing that was short of room.

### Still open: the last ring's caption hangs off the *bottom* of the ground

Widening fixes the direction Erik's words point in — the caption had no air
sideways — but the ring he named is the one that shows the other direction, and
this sheet should say so rather than leave it to be rediscovered.

The caption is anchored to the ring's bottom edge and hangs about 11px below it
(`Ring.qml`), which the 9px spacing between rings pays for. The **last** ring in
the group has no next ring under it, only `Theme.groupPad` = 6 of ground and
then a 10px corner radius. So its caption is drawn partly on bare rail. Measured
on the live rail, last ring `data 2.0T`:

| row | ground x | caption ink x |
|---|---|---|
| y666 | 6..51 | 10..49 |
| y667 | 7..50 | 8..48 |
| y668 | 26..49 | 7..48 |
| y669 | 20..46 | 7..48 |
| y670 | 20..39 | 7..48 |
| y671 | — | 7..48 |
| y672 | — | 8..48 |

Five of the caption's seven ink rows have ends outside the ground, and its last
two rows have no ground under them at all. On a laptop the last ring is the
battery, so the caption that does this is `bat` — which is the word Erik used,
and which at 29px cannot be the one that is too wide.

Two ways to close it, neither taken here because both need a decision this pass
did not have:

1. **Pad the bottom of the group.** `ringBox.implicitHeight` is
   `rings.implicitHeight + 12`; about `+6` on the bottom side puts the whole
   caption on the ground with a pixel to spare. It costs 6px of `rail.fixed`,
   which the overflow ladder spends out of the workspaces' room, and the height
   budget was frozen for this change.
2. **Height-free: move the 6px rather than add it.** The rings' spacing is 9 and
   there are six gaps between seven rings; at 8 that is exactly the 6px the
   bottom needs, so `ringBox` stays 262 and `rail.fixed` stays 595. The cost is
   that the overhang between rings tightens from 1px of slack to 2px of overlap,
   which is a look question and wants an eye on it, not a table.
