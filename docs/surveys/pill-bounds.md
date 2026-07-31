# Where does one workspace pill end? 20 designs, measured

> "there should be some border around even the unselected ones, idk — show me a
> bunch of designs. want to see where one workspace starts and ends."

and then, having seen it:

> "for the workspaces i did not mean like a literal border. i mean more like
> with the system tray icons that have, you know, a tinted background — like
> that i want the workspaces to be. and now you also made the workspaces
> bigger, you should not have done that."

Source: `pill-bounds.qml`. Run it with

    quickshell -p docs/surveys/pill-bounds.qml

Twenty designs drawn at the rail's true 58px width, on the real `Theme.bgHi`
ground the pills stand on, with the content that is actually in his rail: a
focused pill with two icons, an idle pill with one, an idle pill with two, the
empty workspace 9, and a two-digit "10". Five rows, so four boundaries between
adjacent pills are visible in every column. Every number below is printed by
that file — the geometry off the mocks, the colour off the live `Theme`
singleton, and the cross-theme sweep off `Themes.qml`'s own `curated` list
(`Themes.qml:53-78`) rather than a second copy of the palettes.

**This file is two rounds.** Round one shipped #4, a 1px border, and §4 below
explains at length why the whole filled-ground family lost to a measurement.
Round two is the quote above: a ground is what he wanted, so the measurement had
to be answered rather than repeated, and #20 is the answer. Round one's
reasoning is kept, because it is still true of a ground drawn under the *old*
hover colour, and that is the trap anybody re-opening this will fall into.

---

## 0. What is actually wrong

`Workspaces.qml:167-169`, before any of this:

```qml
color: ws.here ? Qt.alpha(Theme.accent, hover.containsMouse ? 0.34 : 0.22)
     : hover.containsMouse ? Theme.line
     : Qt.alpha(Theme.line, 0)
```

An idle pill is the hover hue at **zero alpha**. It draws nothing. The pill is
44 wide with 5px under it, and the only ink in it is a 13px number and up to two
13px icons — so an idle rail is a column of floating numbers whose widths
differ from row to row (workspace 9 is empty: one digit and nothing else). The
`Rectangle` is there, it is just invisible, and nothing says where it starts.

The ground it stands on is `Theme.bgHi` — `wsBlock` at `shell.qml:386-389`
draws it, the same ground every `Group` on the rail draws (`Group.qml:53`).
That matters for every number here: the boundary is not being measured against
the rail's `Theme.bg`, it is being measured against `bgHi`, which is a step
brighter.

## 1. The measuring stick

Two numbers per design, and they disagree, so both are printed.

**WCAG ratio** is the one the warning washes were floored at 3.3:1. It compresses
badly at the light end, which is exactly where this has to hold up: `Theme.line`
against its ground reads 1.15 on Gruvbox Light and 1.62 on Kanagawa — a 1.4x
spread that says those two are nearly the same design.

**dL** is the CIE L\* step, 0-100, perceptually even. The same two are 4.7 and
13.4 — a 3.6x spread, and that is the pair the eye actually reports. Everything
below leads with dL and carries the ratio beside it.

A third number, **ink**, is dL times the number of pixels the mark covers, and
it exists because a 132px outline and a 1056px fill cannot otherwise be
compared at all. A 1px border on the 44x24 pill is `44*24 - 42*22` = 132px; a
fill is 1056px; a 24px rule is 24px. (These are one pill height smaller than the
figures round one printed, because the pill is now 24 and not 28 — §6.)

Alpha marks are composited over the ground before being measured, because the
composite is the colour the eye is given.

## 2. What everyone else does about an idle workspace

`hover-survey.md` already read sixteen projects for the hover path; its
idle-colour column answers this question too, and the count is decisive.
**Nine of the fifteen third-party shells give every pill a visible ground** —
six an opaque theme token, three an alpha of a named colour — so the shipped
"nothing at all" is a minority of one plus three who never animate it.

Four read directly for this survey:

| Project | file:line | What marks an idle pill |
|---|---|---|
| noctalia v4 | `NOCT4/Modules/Bar/Extras/WorkspacePill.qml:94` | `Qt.alpha(Color.resolveColorKey(emptyColor), 0.3)` — an alpha ground on every pill, never `"transparent"` |
| noctalia v4, grouped mode | `NOCT4/Modules/Bar/Widgets/Workspace.qml:729-730` | `border.width: Style.borderS` (1px) and `border.color: ... Qt.alpha(Color.mOutline, groupedBorderOpacity)` — **an alpha border on every item**, idle included. The opacity is a settings slider, default 1.0 (`Services/UI/BarWidgetRegistry.qml:304`) |
| noctalia v4, the widget's capsule | `NOCT4/Modules/Bar/Widgets/Workspace.qml:540-541` | `border.color: Style.capsuleBorderColor`, which is `Color.mPrimary` or `"transparent"` behind a `showOutline` setting (`NOCT4/Commons/Style.qml:157-158`) |
| diinki/linux-retroism | `CLONES/diinki_linux-retroism/configs/quickshell/taskbar/Workspaces.qml:77-85` | `border.width: 1; border.color: Config.colors.outline` on the pill's `background`, unconditionally — **a 1px outline on every pill, focused or not**, with only the fill switching |
| josecriane | `CLONES/josecriane_quickshell-config/modules/bar/components/Workspaces.qml:141-145` | opaque `Foundations.palette.base02`, no border. Its pill is a 12px dot, so its extent was never in question |

So the two shapes with real prior art are **a ground on every pill** and **a 1px
border on every pill**. Nobody in any of these surveys draws a rule *between*
workspace pills. That is not a reason not to, but it is worth knowing that the
idea has no precedent in twenty shells.

And this shell has the idiom in it already, twice: a tray cell is a 26px disc of
`Theme.bgAlt` standing on the same `bgHi` (`shell.qml:752-760`, and the overflow
count at `:818-826`), and `Btn`'s `disc` gives the wifi and bluetooth buttons the
same one. Measured the same way as everything below, that disc is **3.1-8.0 dL**
over the nine schemes. That is the tone he pointed at, and it is what #20 has to
land in.

## 3. The twenty

Geometry first, because it is the constraint that cannot be argued with. `h` is
the pill's measured height, `gap` the measured distance between two adjacent
pills, `col` the measured height of the five-pill column.

Every design except #14 measures **h 24, gap 5, col 140** — a `Rectangle`'s
border draws inside its bounds and an overlay anchored across the gutter is not
in the layout, so neither costs the rail a pixel. #14 measures **gap 11, col
164**: putting the rule in the column costs `1 + Theme.slotGap` = 6px per
boundary.

dL of the mark against the ground, per theme, from the sweep:

| # | Design | Tokyo Night | Gruvbox | Everforest | **Gruvbox Light** | **Rosé Pine Dawn** | Catppuccin | Nord | Rosé Pine | Kanagawa | min-max | spread | ratio range | ink | verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | shipped — nothing | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | — | 1.00 | 0 | **the complaint** |
| 2 | 1px border `Theme.line` | 3.7 | 3.8 | 4.3 | 4.7 | 4.6 | 9.3 | 4.3 | 11.8 | 13.4 | 3.7-13.4 | **3.63x** | 1.12-1.62 | 486 | rejected |
| 3 | 1px border `a(fg,0.12)` | 9.7 | 9.2 | 6.6 | **5.4** | **6.3** | 8.7 | 8.9 | 10.3 | 8.4 | 5.4-10.3 | 1.90x | 1.17-1.38 | 1278 | rejected — light schemes |
| 4 | 1px border `a(dim,0.25)` | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 1402 | **round one — superseded by #20** |
| 5 | same, idle pills only | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 1402 | rejected — geometry |
| 6 | 1px border `a(dim,0.45)` | 18.7 | 16.8 | 13.7 | 17.3 | 18.4 | 16.0 | 13.3 | 21.2 | 11.2 | 11.2-21.2 | 1.88x | 1.49-2.04 | 2462 | rejected — too loud |
| 7 | ground `a(dim,0.10)` | 4.3 | 3.9 | 3.1 | 3.8 | 4.0 | 3.7 | 3.0 | 4.9 | 2.6 | 2.6-4.9 | 1.94x | 1.09-1.15 | 4581 | rejected — beat the old hover |
| 8 | ground `a(line,0.5)` (noctalia) | 1.9 | 1.9 | 2.2 | 2.3 | 2.3 | 4.7 | 2.1 | 6.0 | 6.8 | 1.9-6.8 | 3.68x | 1.06-1.27 | 1959 | rejected — invisible |
| 9 | ground `Theme.bgAlt` (the tray cell) | 4.3 | 3.9 | 3.9 | 8.0 | 5.7 | 5.4 | 3.1 | 3.3 | 5.6 | 3.1-8.0 | 2.56x | 1.09-1.25 | 4566 | rejected — sinks |
| 10 | ground `Theme.bg` | 8.3 | 8.0 | 8.2 | 15.2 | 3.7 | 9.4 | 6.3 | 6.5 | 11.1 | 3.7-15.2 | **4.12x** | 1.10-1.51 | 8775 | rejected — a hole |
| 11 | rule `Theme.line`, 24px | 3.7 | 3.8 | 4.3 | 4.7 | 4.6 | 9.3 | 4.3 | 11.8 | 13.4 | 3.7-13.4 | 3.63x | 1.12-1.62 | 88 | rejected — same token |
| 12 | rule `a(dim,0.25)`, 24px | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 255 | rejected — see §5 |
| 13 | rule `a(dim,0.25)`, full 44px | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 467 | rejected — see §5 |
| 14 | the same rule, in the column | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 467 | rejected — +42px of rail |
| 15 | alternating ground `a(dim,0.10)` | 4.3 | 3.9 | 3.1 | 3.8 | 4.0 | 3.7 | 3.0 | 4.9 | 2.6 | 2.6-4.9 | 1.94x | 1.09-1.15 | 4581 | rejected — unstable |
| 16 | left marker `a(dim,0.45)` | 18.7 | 16.8 | 13.7 | 17.3 | 18.4 | 16.0 | 13.3 | 21.2 | 11.2 | 11.2-21.2 | 1.88x | 1.49-2.04 | 485 | rejected — collides |
| 17 | ground + radius = h/2 | 4.3 | 3.9 | 3.1 | 3.8 | 4.0 | 3.7 | 3.0 | 4.9 | 2.6 | 2.6-4.9 | 1.94x | 1.09-1.15 | 4581 | rejected — see #7 |
| 18 | inset: `a(fg,0.06)` / `a(bg,0.55)` | 4.9 | 4.7 | 3.3 | 2.7 | 3.1 | 4.4 | 4.5 | 5.2 | 4.2 | 2.7-5.2 | 1.94x | 1.08-1.18 | 433 | rejected — invisible |
| 19 | border + ground | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 1402 | rejected — carries #7 |
| **20** | **ground `a(dim,0.12)`, hover moved** | **5.2** | **4.6** | **3.7** | **4.5** | **4.8** | **4.4** | **3.6** | **5.9** | **3.1** | **3.1-5.9** | **1.93x** | **1.11-1.19** | **5480** | **shipped** |

And the two marks it had to live beside, as they were before round two:

| | Tokyo Night | Gruvbox | Everforest | Gruvbox Light | Rosé Pine Dawn | Catppuccin | Nord | Rosé Pine | Kanagawa |
|---|---|---|---|---|---|---|---|---|---|
| focused fill `a(accent,0.34)` | 18.4 | 17.0 | 16.0 | 14.4 | 12.6 | 18.7 | 16.7 | 21.4 | 14.8 |
| hover fill `Theme.line` | 3.7 | 3.8 | 4.3 | 4.7 | 4.6 | 9.3 | 4.3 | 11.8 | 13.4 |

## 4. Why the filled-ground family was out, and what let it back in

Round one's finding stands and is the whole difficulty here: **the hover fill was
`Theme.line`, and `Theme.line` is barely above the ground it sits on.** Row two
of the table: 3.7 on Tokyo Night, 3.8 on Gruvbox, 4.3 on Everforest and Nord, 4.6
and 4.7 on the two light schemes. There was almost no room underneath it.

Put a ground on the idle pill and it has to fit into that room. Design #7 at
`a(dim,0.10)` — already faint at 2.6-4.9 — is **4.3 against a 3.7 hover on Tokyo
Night and 3.9 against 3.8 on Gruvbox**: the idle pill would be *brighter than the
hovered one* on the two schemes he actually wears. Design #8, noctalia's own
idiom, is safe by construction because it is literally half the hover colour, and
that caps it at 1.9-6.8 dL — invisible on six of nine schemes. Design #9 — which
is the tray cell's own colour, and therefore the most literal reading of what he
asked for — goes the wrong way on dark palettes, where `bgAlt` is *below* `bgHi`:
the pill sinks into the group, and the hover then has to cross back through the
ground, passing through invisible on the way. Design #10 punches the rail's own
colour through the group and reads as a hole.

Round one's last line was "a ground could be made to work by moving the hover
colour as well". That is the thing he has now asked for, so the hover moved.

**The ladder.** One ink, `Theme.dim`, at two strengths for the two idle states,
then the focused pill's accent at two more. Four rungs, and each has to clear the
one below it on all nine curated schemes — a ground that ties its own hover is
worse than no ground, and that is the failure mode this table exists to rule out.
Printed by `pill-bounds.qml`'s `ladder()`:

| | Tokyo Night | Gruvbox | Everforest | Gruvbox Light | Rosé Pine Dawn | Catppuccin | Nord | Rosé Pine | Kanagawa |
|---|---|---|---|---|---|---|---|---|---|
| idle `a(dim,0.12)` | 5.2 | 4.6 | 3.7 | 4.5 | 4.8 | 4.4 | 3.6 | 5.9 | 3.1 |
| hover `a(dim,0.22)` | 9.4 | 8.4 | 6.8 | 8.4 | 8.9 | 8.0 | 6.6 | 10.7 | 5.6 |
| *clears idle by* | +4.2 | +3.8 | +3.1 | +3.8 | +4.1 | +3.6 | +3.0 | +4.8 | **+2.5** |
| focused `a(accent,0.30)` | 16.4 | 15.0 | 14.2 | 12.7 | 11.1 | 16.6 | 14.8 | 19.0 | 13.1 |
| *clears hover by* | +7.0 | +6.6 | +7.3 | +4.3 | **+2.2** | +8.6 | +8.2 | +8.4 | +7.5 |
| focused + hover `a(accent,0.40)` | 21.5 | 19.9 | 18.7 | 16.9 | 14.8 | 21.8 | 19.6 | 25.0 | 17.3 |
| *clears focused by* | +5.2 | +4.9 | +4.6 | +4.2 | **+3.8** | +5.3 | +4.7 | +5.9 | +4.2 |

Monotonic on every scheme. The worst margins are +2.5 (Kanagawa, idle to hover),
+2.2 (Rosé Pine Dawn, hover to focused) and +3.8 (Rosé Pine Dawn again), against
a hover that used to be *below* the ground it would have needed to beat.

Three things fall out of it that are worth saying plainly:

- **The focused pill had to move too.** At its old `a(accent,0.22)` it measures
  9.3 on Gruvbox Light and 8.1 on Rosé Pine Dawn, and the new hover is 8.4 and
  8.9 — so on the light schemes a *hovered idle* pill would have equalled the
  focused one. 0.30 is the smallest step that clears it everywhere. The old 0.34
  becomes the new hovered value at 0.40, and the focused pill keeps two rungs of
  its own rather than one.
- **A faint ground is still more mark than a strong border.** #20 is 3.1-5.9 dL
  against #4's 6.3-12.1, and it draws **ink 5480 against 1402** — eight times the
  area at half the step. That is the whole reason a ground can afford to be quiet
  and a hairline cannot, and it is why the ground reads as an object where the
  outline read as a drawn-on box.
- **It lands in the tone he pointed at.** The tray cell is 3.1-8.0 dL (#9), the
  ground is 3.1-5.9 — the same band, and rather more even across themes (1.93x
  against 2.56x), because an alpha of `dim` tracks the palette where an opaque
  `bgAlt` does not.

`a(dim,·)` and not `a(fg,·)` for the same reason round one gave: `fg` on a light
palette is a near-black whose small alphas move very little in L\*, and #3 is
1.51x weaker on the light schemes than the dark ones. `dim` is also what the idle
number in the pill is already drawn in, so ground and label are one ink.

## 5. Border or separator? Round one's answer, kept

A separator was genuinely the cheaper mark: **ink 255 against 1402**, one
hairline per boundary instead of four sides per pill. In a 58px column that
argument deserves to win, and it did not, for three measured reasons — and none
of them changed when the border became a ground, because a ground answers all
three the same way an outline did.

**It answers the wrong axis.** A rule says where a pill stops vertically. It
says nothing about how wide one is — and width is the varying dimension here.
The pill is 44px, centred in a 58px block with 7px of ground each side, but its
*content* runs from a single digit on the empty workspace 9 to a two-digit
number plus two 13px icons on a full one. A ground makes all eight rows the same
44x24 rectangle. A rule leaves eight rows of different widths sitting between
hairlines.

**It fails on the pill he pointed at.** Workspace 9 is empty. Between two rules
it is still a floating digit with nothing round it; it is the one row a rule
cannot help. On a ground it is visibly an empty pill, which is what it is.

**It costs either a compromise or the rail's slack.** Drawn as an overlay across
the gutter it costs no height (#12, #13: gap 5, col 140) but is then a mark that
belongs to neither neighbour and has to know which pill is last. Drawn honestly
as a column item (#14) the measured gap goes 5 to 11 and the column 140 to 164 —
`1 + Theme.slotGap` per boundary, **7 x 6 = 42px** on his eight workspaces, out
of the slack `rail.ringGap` uses to centre the metrics (`shell.qml:330-333`).

**Does the mark need to be on every pill?** Yes. Design #5 — the mark on idle
pills only — measures identically on colour and is rejected because a
`Rectangle` with `border.width: 0` next to one with `border.width: 1` puts the
focused pill's fill 1px closer to its own edge than its neighbours'. The column
stops being a ladder of identical objects, which is the thing that made it
readable. As a ground the question does not even arise: the focused pill's fill
*is* the ground, one rung further up.

## 6. And the pill came back down to 24

> "and now you also made the workspaces bigger, you should not have done that."

`12d49e7` took the pill from 24 to 28 — `Theme.slot` — as part of putting every
rail control on one vertical rhythm, because at the time the workspaces were
"smushed together" with a "very small font" while the bottom of the rail was
"large and spaced far apart". That complaint was real and the fix was right about
the *gap*; it was wrong about the pill, and this is the other half of the same
sentence arriving three commits later.

**What shipped: the pill gets its own height, the rail keeps its rhythm.**
`implicitHeight: 24` in `Workspaces.qml`, `Theme.slot` untouched at 28, the gap
still `Theme.slotGap`. The alternative — dropping `Theme.slot` itself — moves
every button, ring, tray cell and chevron on the rail to fix a complaint about
one of them, and would undo `12d49e7` wholesale rather than the one line of it he
objected to. So the rail after this is: one slot, 28, for every control that is a
thing you click *once*, and one exception, the workspace pill, which is the only
control that appears eight times in a column and is a label rather than a button.
One gap, 5, everywhere, unchanged. `Btn`'s `disc` is already a 26px shape inside
its 28px slot, so a control drawing smaller than its stripe is an idiom this rail
has.

**The number stays at 13px.** It went 11 to 13 in `12d49e7` and he complained
about eleven by name; a shorter pill is not an argument for a smaller number. 13
is the size of the icons standing beside it in the same row, and a 13px line in a
24px pill still leaves three pixels of air top and bottom. `Layout.maximumWidth`
stays 20 — at 15 the very real workspace "10" elided, and the cap depends on the
font size and not the pill's height. Verified on screen: the last pill renders
both digits and its icon, unclipped.

**The rail's budget, measured off the screen** (Gruvbox, his eight workspaces,
1920x1080, sampling the rail's left column and run-length encoding it):

| | pill h | pill pitch | `wsBlock` | gap to the metrics | metrics group | rail |
|---|---|---|---|---|---|---|
| before | 28 | 33 | rows 0-274, **275** | 136 | rows 414-603 | 1080 |
| after | 24 | 29 | rows 0-242, **243** | 168 | rows 414-603 | 1080 |

The 32px comes off the workspace block and goes straight into `rail.ringGap`,
which is exactly what that property is for: **nothing below the workspaces moved
by a pixel**, the metrics group starts on the same row it did, and the rail is
full height either way. No number in `shell.qml` needs editing —
`implicitHeight: wsBox.implicitHeight + 16` (`:389`) is measured, and the
`rail.fixed` / `elastic` / `wsRoom` ladder never mentions the pill.

One line there is now imprecise rather than wrong: `shell.qml:300` holds
`rail.elastic - Theme.slot` back from the tray, described as "one workspace
pill's worth". That reserve is now 28 for a 24px pill — it over-reserves by 4px,
which fails safe, so it is left alone.

## 7. What shipped

```qml
implicitHeight: 24
radius: Theme.radiusS
color: ws.here ? Qt.alpha(Theme.accent, hover.containsMouse ? 0.40 : 0.30)
     : Qt.alpha(Theme.dim, hover.containsMouse ? 0.22 : 0.12)
```

Four states, two hues, one property. `border.width` and `border.color` are gone
with round one. The `Behavior`, the `MouseArea` and its negative margins are
untouched.

**Live, on Gruvbox, sampled off the screen with `grim`.** `bgHi` is `#32302f` =
`50 48 47`; every value below is the pixel that was actually on screen, with its
CIE L\* and the step from the ground beside it:

| state | RGB | L\* | dL vs ground | predicted |
|---|---|---|---|---|
| group ground, and the gutter between two pills | `50 48 47` | 20.03 | — | — |
| idle pill | `62 58 55` | 24.72 | **4.69** | 4.6 |
| idle pill, hovered | `71 66 63` | 28.37 | **8.34** | 8.4 |
| focused pill | `100 79 43` | 34.95 | **14.92** | 15.0 |
| focused pill, hovered | `116 90 41` | 39.89 | **19.86** | 19.9 |

The ladder is monotonic on the glass, and **the idle ground is 3.65 L\* weaker
than the hovered one** — the trap this whole file is about, measured shut.

**The hover flash did not come back.** The pill's fill sampled continuously
through a real `ydotool` enter and a real exit, 60 frames at ~23ms, relative
luminance:

```
idle   0.0434 x8
enter  0.0445 0.0463 0.0478 0.0504 0.0523 0.0528 0.0556 0.0561
hover  0.0561 x26
exit   0.0559 0.0543 0.0523 0.0507 0.0492 0.0477 0.0449 0.0434
idle   0.0434 x12
```

Monotonic in both directions, with no sample outside the two endpoints. It cannot
be otherwise now: both endpoints are the same hue at two alphas, so
`ColorAnimation` has only alpha to walk. The bug this replaced dipped 15.6
luminance units below both, because `"transparent"` is transparent *black*.

**The hit areas still tile.** Walking the cursor down through the 5px gutter
between pill 1 (rows 8-31) and pill 2 (rows 37-60), exactly one pill is lit at
every position and the handover is at row 34, the gutter's midpoint:

| cursor row | pill 1 | pill 2 |
|---|---|---|
| 30, 32 | `116 90 41` hovered | `62 58 55` idle |
| 34, 36, 38 | `100 79 43` unhovered | `71 66 63` hovered |

## 8. Rejected, in one line each

| # | Why not |
|---|---|
| 1 | Draws nothing. This is what he complained about. |
| 2 | `Theme.line` is 3.7 dL on Tokyo Night and 13.4 on Kanagawa — 3.63x spread, invisible on the schemes he wears, and it was the hover colour. |
| 3 | 1.51x weaker on the light schemes than the dark ones. |
| 4 | Round one. A drawn-on box where he wanted a tinted ground; superseded by #20. |
| 5 | The mark on idle pills only makes the focused pill a different shape from its neighbours for no gain. |
| 6 | 11.2-21.2 dL is inside the focused fill's own band. |
| 7 | 4.3 dL against a 3.7 dL hover on Tokyo Night. The right family, at the wrong strength, under a hover that had not moved yet — #20 is this design with the ladder built. |
| 8 | Half the hover colour by construction, so capped at 1.9-6.8 dL. Invisible on six of nine schemes. |
| 9 | The tray cell's own token, and the closest reading of what he asked for — but `bgAlt` is below `bgHi` on dark palettes, so the pill sinks into the group and the hover has to cross back through the ground. #20 keeps its tone (3.1-5.9 against 3.1-8.0) and not its direction. |
| 10 | 4.12x spread, the worst on the sheet, and reads as a hole punched through the group. |
| 11 | A rule in the token that was already the hover colour. |
| 12, 13 | Cheaper ink (255 / 467 vs 5480) but answers the vertical axis only, and cannot help the empty workspace. |
| 14 | +6px per boundary, +42px on his eight workspaces, out of the slack that centres the metrics. |
| 15 | Which pill is marked changes every time a workspace appears or goes away. |
| 16 | A second left-edge marker where the focused pill already has one; two marks in one place meaning two different things. |
| 17 | The radius is now #20's anyway — `Theme.radiusS` on a 24px pill is nearly a stadium — but as a design it is #7's ground with a shape change instead of a strength. |
| 18 | 2.7 dL on Gruvbox Light. An emboss at 6% is not a boundary. |
| 19 | Two channels for one boundary. Once the ground works, the border is the half that can go. |
