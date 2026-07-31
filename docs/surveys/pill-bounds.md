# Where does one workspace pill end? 19 designs, measured

> "there should be some border around even the unselected ones, idk — show me a
> bunch of designs. want to see where one workspace starts and ends."

Source: `pill-bounds.qml`. Run it with

    quickshell -p docs/surveys/pill-bounds.qml

Nineteen designs drawn at the rail's true 58px width, on the real `Theme.bgHi`
ground the pills stand on, with the content that is actually in his rail: a
focused pill with two icons, an idle pill with one, an idle pill with two, the
empty workspace 9, and a two-digit "10". Five rows, so four boundaries between
adjacent pills are visible in every column. Every number below is printed by
that file — the geometry off the mocks, the colour off the live `Theme`
singleton, and the cross-theme sweep off `Themes.qml`'s own `curated` list
(`Themes.qml:53-78`) rather than a second copy of the palettes.

---

## 0. What is actually wrong

`Workspaces.qml:167-169`, before this session:

```qml
color: ws.here ? Qt.alpha(Theme.accent, hover.containsMouse ? 0.34 : 0.22)
     : hover.containsMouse ? Theme.line
     : Qt.alpha(Theme.line, 0)
```

An idle pill is the hover hue at **zero alpha**. It draws nothing. The pill is
44x28 with 5px under it, and the only ink in it is a 13px number and up to two
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
it exists because a 140px outline and a 1232px fill cannot otherwise be
compared at all. A 1px border on a 44x28 pill is `44*28 - 42*26` = 140px; a
fill is 1232px; a 24px rule is 24px.

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

## 3. The nineteen

Geometry first, because it is the constraint that cannot be argued with. `h` is
the pill's measured height, `gap` the measured distance between two adjacent
pills, `col` the measured height of the five-pill column.

Every design except #14 measures **h 28, gap 5, col 160** — a `Rectangle`'s
border draws inside its bounds and an overlay anchored across the gutter is not
in the layout, so neither costs the rail a pixel. #14 measures **gap 11, col
184**: putting the rule in the column costs `1 + Theme.slotGap` = 6px per
boundary.

dL of the mark against the ground, per theme, from the sweep:

| # | Design | Tokyo Night | Gruvbox | Everforest | **Gruvbox Light** | **Rosé Pine Dawn** | Catppuccin | Nord | Rosé Pine | Kanagawa | min-max | spread | ratio range | ink | verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | shipped — nothing | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | — | 1.00 | 0 | **the complaint** |
| 2 | 1px border `Theme.line` | 3.7 | 3.8 | 4.3 | 4.7 | 4.6 | 9.3 | 4.3 | 11.8 | 13.4 | 3.7-13.4 | **3.63x** | 1.12-1.62 | 516 | **rejected** |
| 3 | 1px border `a(fg,0.12)` | 9.7 | 9.2 | 6.6 | **5.4** | **6.3** | 8.7 | 8.9 | 10.3 | 8.4 | 5.4-10.3 | 1.90x | 1.17-1.38 | 1355 | rejected — light schemes |
| **4** | **1px border `a(dim,0.25)`** | **10.6** | **9.5** | **7.7** | **9.5** | **10.1** | **9.1** | **7.5** | **12.1** | **6.3** | **6.3-12.1** | **1.91x** | **1.25-1.47** | **1487** | **shipped** |
| 5 | same, idle pills only | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 1487 | rejected — geometry |
| 6 | 1px border `a(dim,0.45)` | 18.7 | 16.8 | 13.7 | 17.3 | 18.4 | 16.0 | 13.3 | 21.2 | 11.2 | 11.2-21.2 | 1.88x | 1.49-2.04 | 2612 | rejected — too loud |
| 7 | ground `a(dim,0.10)` | 4.3 | 3.9 | 3.1 | 3.8 | 4.0 | 3.7 | 3.0 | 4.9 | 2.6 | 2.6-4.9 | 1.94x | 1.09-1.15 | 5344 | rejected — beats hover |
| 8 | ground `a(line,0.5)` (noctalia) | 1.9 | 1.9 | 2.2 | 2.3 | 2.3 | 4.7 | 2.1 | 6.0 | 6.8 | 1.9-6.8 | 3.68x | 1.06-1.27 | 2285 | rejected — invisible |
| 9 | ground `Theme.bgAlt` | 4.3 | 3.9 | 3.9 | 8.0 | 5.7 | 5.4 | 3.1 | 3.3 | 5.6 | 3.1-8.0 | 2.56x | 1.09-1.25 | 5327 | rejected — sinks |
| 10 | ground `Theme.bg` | 8.3 | 8.0 | 8.2 | 15.2 | 3.7 | 9.4 | 6.3 | 6.5 | 11.1 | 3.7-15.2 | **4.12x** | 1.10-1.51 | 10238 | rejected — a hole |
| 11 | rule `Theme.line`, 24px | 3.7 | 3.8 | 4.3 | 4.7 | 4.6 | 9.3 | 4.3 | 11.8 | 13.4 | 3.7-13.4 | 3.63x | 1.12-1.62 | 88 | rejected — same token |
| 12 | rule `a(dim,0.25)`, 24px | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 255 | rejected — see §5 |
| 13 | rule `a(dim,0.25)`, full 44px | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 467 | rejected — see §5 |
| 14 | the same rule, in the column | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 467 | **rejected — +42px of rail** |
| 15 | alternating ground `a(dim,0.10)` | 4.3 | 3.9 | 3.1 | 3.8 | 4.0 | 3.7 | 3.0 | 4.9 | 2.6 | 2.6-4.9 | 1.94x | 1.09-1.15 | 5344 | rejected — unstable |
| 16 | left marker `a(dim,0.45)` | 18.7 | 16.8 | 13.7 | 17.3 | 18.4 | 16.0 | 13.3 | 21.2 | 11.2 | 11.2-21.2 | 1.88x | 1.49-2.04 | 560 | rejected — collides |
| 17 | ground + radius = h/2 | 4.3 | 3.9 | 3.1 | 3.8 | 4.0 | 3.7 | 3.0 | 4.9 | 2.6 | 2.6-4.9 | 1.94x | 1.09-1.15 | 5344 | rejected — see #7 |
| 18 | inset: `a(fg,0.06)` / `a(bg,0.55)` | 4.9 | 4.7 | 3.3 | 2.7 | 3.1 | 4.4 | 4.5 | 5.2 | 4.2 | 2.7-5.2 | 1.94x | 1.08-1.18 | 433 | rejected — invisible |
| 19 | border + ground | 10.6 | 9.5 | 7.7 | 9.5 | 10.1 | 9.1 | 7.5 | 12.1 | 6.3 | 6.3-12.1 | 1.91x | 1.25-1.47 | 1487 | rejected — carries #7 |

And the two marks it has to live beside, measured the same way:

| | Tokyo Night | Gruvbox | Everforest | Gruvbox Light | Rosé Pine Dawn | Catppuccin | Nord | Rosé Pine | Kanagawa |
|---|---|---|---|---|---|---|---|---|---|
| focused fill `a(accent,0.34)` | 18.4 | 17.0 | 16.0 | 14.4 | 12.6 | 18.7 | 16.7 | 21.4 | 14.8 |
| hover fill `Theme.line` | 3.7 | 3.8 | 4.3 | 4.7 | 4.6 | 9.3 | 4.3 | 11.8 | 13.4 |

## 4. Why the whole "filled ground" family is out, with the number

This is the direction the prior art points, so it got the careful treatment, and
it fails on one line: **the hover fill is `Theme.line`, and `Theme.line` is
barely above the ground it sits on.** Row two of the table above: 3.7 on Tokyo
Night, 3.8 on Gruvbox, 4.3 on Everforest and Nord, 4.6 and 4.7 on the two light
schemes. There is almost no room underneath it.

Put a ground on the idle pill and you have to fit it into that room. Design #7
at `a(dim,0.10)` — already faint at 2.6-4.9 — is **4.3 against a 3.7 hover on
Tokyo Night and 3.9 against 3.8 on Gruvbox**: the idle pill would be *brighter
than the hovered one* on the two schemes he actually wears. Design #8, noctalia's
own idiom, is safe by construction because it is literally half the hover
colour, and that caps it at 1.9-6.8 dL — invisible on six of nine schemes.
Design #9 goes the wrong way on dark palettes, where `bgAlt` is *below* `bgHi`,
so the pill sinks into the group rather than standing on it. Design #10 punches
the rail's own colour through the group and reads as a hole, and its 4.12x
spread is the worst on the sheet.

A ground could be made to work by moving the hover colour as well — which is
re-opening `05b2f3a` for a cosmetic gain. A border cannot collide with the hover
fill at all, because it is a different property.

## 5. Border or separator? The honest answer is border, and here is why

A separator is genuinely the cheaper mark: **ink 255 against 1487**, one
hairline per boundary instead of four sides per pill, nearly six times less drawing
for the same dL. In a 58px column that argument deserves to win, and it does
not, for three measured reasons.

**It answers the wrong axis.** A rule says where a pill stops vertically. It
says nothing about how wide one is — and width is the varying dimension here.
The pill is 44px, centred in a 58px block with 7px of ground each side, but its
*content* runs from a single digit on the empty workspace 9 to a two-digit
number plus two 13px icons on a full one. A border makes all eight rows the same
44x28 rectangle. A rule leaves eight rows of different widths sitting between
hairlines.

**It fails on the pill he pointed at.** Workspace 9 is empty. Between two rules
it is still a floating digit with nothing round it; it is the one row a rule
cannot help. In a box it is visibly an empty box, which is what it is.

**It costs either a compromise or 42px.** Drawn as an overlay across the gutter
it costs no height (#12, #13: gap 5, col 160) but is then a mark that belongs to
neither neighbour and has to know which pill is last. Drawn honestly as a column
item (#14) the measured gap goes 5 to 11 and the column 160 to 184 — `1 +
Theme.slotGap` per boundary. On his eight workspaces that is **7 x 6 = 42px**,
taking `wsBlock` from 275 to 317 (live: `RAILMEASURE ... wsBlock=275 wsRoom=452
ringGap=134`). It fits, but it spends 42 of the 134px of slack that
`rail.ringGap` uses to centre the metrics — the rail's only unpromised height,
`shell.qml:330-333`.

And a border is one property on a `Rectangle` that already exists, against one
extra `Rectangle` per gap. `AGENTS.md` rule 1.

**Does the boundary need to be on every pill?** Yes, and for a reason that is
geometric rather than aesthetic. Design #5 — border on idle pills only, focused
keeps its fill — measures identically on colour, and is rejected because a
`Rectangle` with `border.width: 0` next to one with `border.width: 1` puts the
focused pill's fill 1px closer to its own edge than its neighbours'. The column
stops being a ladder of identical objects, which is the thing that made it
readable. The border costs nothing on the focused pill and the focused pill is
still unmistakable: its fill is 12.6-21.4 dL against the same ground, never
below the border's 6.3-12.1 on any scheme.

## 6. Why not `Theme.line`, which is what a border in this shell is

`LooksWindow.qml:59-60`, `TrayMenu.qml:138-139` and `LauncherWindow.qml:80-81`
all draw their 1px border in `Theme.line`, so #2 was the obvious answer. It is
the worst design on the sheet after doing nothing:

- **3.63x spread**, second worst of the nineteen. 3.7 dL on Tokyo Night and 3.8
  on Gruvbox — the two he wears — is not a border, it is a rumour. 13.4 on
  Kanagawa is 91% of that scheme's *focused fill* (14.8), so the idle pills would
  come within a whisker of shouting as loudly as the one he is on.
- `Theme.line` is defined as the hairline against `Theme.bg` (`Theme.qml:32-41`).
  These pills stand on `bgHi`, one step up. One token cannot be the hairline
  against two different grounds.
- It is **already spent here**: `line` is the hover colour, chosen in `05b2f3a`
  precisely because it is the step above `bgHi`. An idle border drawn in it
  disappears the instant the pointer arrives.

`a(fg,0.12)` (#3) fixes the spread — 1.90x — but collapses on the light schemes:
5.4 and 6.3 against a 6.6-10.3 dark range, because `fg` on a light palette is a
near-black whose small alphas move very little in L\*. Split by polarity, its
dark mean is 8.8 and its light mean 5.9: **1.51x weaker on light**.

`a(dim,0.25)` (#4) does not have that problem. Dark mean 9.0, light mean 9.8 —
**0.92x**, i.e. the light schemes land in the middle of the dark range rather
than below it. It is also the colour the idle number in the pill is already
drawn in (`Workspaces.qml:226`), so the box and its label are one ink at two
strengths, and it sits under the focused fill on every one of the nine schemes
with 2.5 dL of margin at the tightest (Rosé Pine Dawn, 10.1 against 12.6).

Rejected neighbours of it: `a(dim,0.45)` (#6) at 11.2-21.2 is up in the focused
fill's own band and reads as a scar; `a(dim,0.10)` as a ground (#7) is the one
that beats the hover.

## 7. What shipped

```qml
border.width: 1
border.color: Qt.alpha(Theme.dim, 0.25)
```

Two lines in `Workspaces.qml`. The `color` expression, its `Behavior`, the
`MouseArea` and its negative margins are untouched.

**Rail budget: unchanged.** `h` 28, `gap` 5, `wsBlock` 275 before and after; a
`Rectangle`'s border draws inside its bounds. No line in `shell.qml` needs
editing. Had #14 shipped instead, `shell.qml:386-389`
(`implicitHeight: wsBox.implicitHeight + 16`) and the `rail.wsRoom` /
`rail.ringGap` ladder at `shell.qml:316-333` would all have had to be re-derived
for a 317px block.

**Live, on Gruvbox, sampled off the screen with `grim`** at the pill's top edge
and its interior:

| point | RGB | is |
|---|---|---|
| group ground, left of the pills | `50 48 47` | `bgHi #32302f` |
| idle pill top edge | `74 69 64` | `a(dim,0.25)` over `bgHi` — predicted 74 / 68.75 / 64.25 |
| idle pill interior | `50 48 47` | still nothing, as designed |
| gutter between two pills | `50 48 47` | ground |
| focused pill interior | `86 71 44` | `a(accent,0.22)` |
| focused pill accent bar | `215 153 33` | `accent #d79921` |

**The hover flash did not come back.** Fill sampled at 16ms through a real enter
and a real exit, relative luminance:

```
enter  0.0300  0.0311  0.0323  0.0337  0.0363  0.0376  0.0389  0.0406  0.0406
exit   0.0406  0.0389  0.0366  0.0363  0.0347  0.0327  0.0314  0.0300  0.0300
```

Monotonic in both directions, no sample outside the two endpoints, settling
exactly on `Theme.line` `#3c3836` = `60 56 54` and back on `bgHi` = `50 48 47`.
The bug this replaced dipped 15.6 luminance units below both.

**The hit areas still tile.** Walking the cursor down through the 5px gutter
between pill 1 (rows 8-35) and pill 2 (rows 41-68), exactly one pill is lit at
every position and the handover is at row 38, the gutter's midpoint:

| cursor row | pill 1 | pill 2 |
|---|---|---|
| 34, 36 | `106 84 42` hovered | `50 48 47` idle |
| 38, 40 | `86 71 44` unhovered | `60 56 54` hovered |

## 8. Rejected, in one line each

| # | Why not |
|---|---|
| 1 | Draws nothing. This is what he complained about. |
| 2 | `Theme.line` is 3.7 dL on Tokyo Night and 13.4 on Kanagawa — 3.63x spread, invisible on the schemes he wears, and it is already the hover colour. |
| 3 | 1.51x weaker on the light schemes than the dark ones. |
| 5 | Border on idle pills only makes the focused pill a different shape from its neighbours for no gain. |
| 6 | 11.2-21.2 dL is inside the focused fill's own band. |
| 7 | 4.3 dL against a 3.7 dL hover on Tokyo Night: the idle pill outshines the hovered one. |
| 8 | Half the hover colour by construction, so capped at 1.9-6.8 dL. Invisible on six of nine schemes. |
| 9 | `bgAlt` is below `bgHi` on dark palettes; the pill sinks into the group. |
| 10 | 4.12x spread, the worst on the sheet, and reads as a hole punched through the group. |
| 11 | A rule in the token that is already the hover colour. |
| 12, 13 | Cheaper ink (255 / 467 vs 1487) but answers the vertical axis only, and cannot help the empty workspace. |
| 14 | +6px per boundary, +42px on his eight workspaces, 275 to 317 — and `shell.qml`'s budget would have to be re-derived. |
| 15 | Which pill is marked changes every time a workspace appears or goes away. |
| 16 | A second left-edge marker where the focused pill already has one; two marks in one place meaning two different things. |
| 17 | Carries #7's ground. The radius alone marks nothing when the fill is invisible. |
| 18 | 2.7 dL on Gruvbox Light. An emboss at 6% is not a boundary. |
| 19 | Carries #7's ground for a boundary the border already provides. |
