# Requirements audit 3

Third pass over `docs/REQUIREMENTS.md`, written after seven background agents
stopped without reporting. The first two audits were treated as suspect and
nothing in them was taken on trust: every line below was settled by reading the
code, and where behaviour was in question, by measuring the running shell.

Two earlier ticks were wrong in ways that cost a day each — a wifi list bound to
a Quickshell property that does not exist, and a "pinning is for tray icons
only" commit that touched only the requirements file and no code. Both failure
modes were looked for again specifically. Neither recurs; one new instance of
the *first* pattern was found and fixed (`Sys.net`, below).

## How things were checked

The shell was already running the working tree under `erikshell-dev`, one
instance owning the D-Bus name, and it was left that way — no second Quickshell
was started, because duplicate instances produced false findings earlier in the
session.

Screenshots could not be looked at this session, so anything visual was settled
numerically: `grim` to PNG, `ffmpeg` to raw RGB, and a pixel count of the exact
palette hexes in a measured crop. That is stronger than looking for the two
questions it was asked, because it distinguishes `#fb4934` from every other red.

One caveat worth recording for the next audit: **exact-colour counting cannot
see 11px text.** Antialiasing blends every glyph pixel toward the background, so
a `Theme.dim` label produces zero exact `#928374` pixels. Solid fills — bars,
arcs, grounds — count reliably; text does not. Where text mattered, the state
behind it was measured instead.

## The seven that stopped

### 1. TrayMenu fade-through-black — was PARTIAL, now DONE

The working tree carried an uncommitted, half-finished fix. The colour change
itself was right and matched the shipped pattern in `Btn.qml:47` and
`Workspaces.qml:167-169`, but it had been left with `duration: 8000` — a value
for watching the ramp in slow motion, not for using the menu. Committing it as
it stood would have shipped an eight-second hover fade.

The brief counted four occurrences of the literal `"transparent"` in the file.
Only one was ever the defect. Of the other three, two are comment text
describing the fix, and the two remaining *code* occurrences are both correct
and were deliberately left alone:

- `TrayMenu.qml:48` — the layershell window's own background, which has to be
  transparent or the menu would paint over the whole screen.
- `TrayMenu.qml:292` — an unanimated checkbox fill. There is no `Behavior on
  color` anywhere near it; the only `Behavior` in the file is the row highlight.
  Transparent black is harmless where nothing interpolates it.

Fixed and committed as `ba82912`.

### 2. Bluetooth — DONE, and one reported bug does not exist

`494b685` landed and is on `main`.

**The reported latent `Binding` bug is not real.** `panels/Bluetooth.qml`
contains no `Binding` element at all — `grep -n Binding panels/Bluetooth.qml`
returns nothing. Line 17, named in the brief, is `property bool
powerWhenUnblocked: false`.

The close hook that stops discovery is `panels/Bluetooth.qml:28`, a plain
assignment in `Component.onDestruction`, with nothing binding `discovering`
that could restore it. The panel that genuinely hit the restore-mode trap is
`panels/Network.qml:29-38`, which already carries `restoreMode:
Binding.RestoreNone` and a comment recording the measurement. No change made,
because there is nothing here to change.

### 3. Light theme and the base16 browser — DONE, both were unticked

Both boxes were open in `REQUIREMENTS.md` and both are actually finished.

*The browser:* `schemes.js` holds all 335 schemes tinted-theming publishes at
spec 0.11, 237 dark and 98 light, as data rather than code. `Themes.qml:82-90`
concatenates them onto nine curated palettes and filters them, with All / Dark /
Light pills at `Themes.qml:127-129` and a count readout of "n of 344". It is
reached from `LooksWindow.qml:85`, the centred overlay, which is exactly the
shape asked for.

*Light themes:* two are curated and marked favourite — Gruvbox Light and Rosé
Pine Dawn, `Themes.qml:72-73` — taken verbatim from upstream rather than
eyeballed.

*Whether the shell survives one* was the open question, so it was answered two
ways.

Statically, the shell has no brightness assumption anywhere to survive. Every
colour resolves through `Theme.qml`, which maps base16 slots by **role** and not
by brightness — `bg` is base00 and `fg` is base05 whichever way the scheme runs.
Across every `.qml` in the repo and in `panels/` there are zero `Qt.darker` or
`Qt.lighter` calls, zero `Qt.rgba` literals, and zero hardcoded hex colours,
with one exception noted below.

Empirically, Gruvbox Light was written to the live shell's `theme.json`, held
for two seconds, measured, and the previous palette restored. The rail flipped
to `base00 #fbf1c7` and `base02 #d5c4a1`, dark text rendered over it, and the
reload logged no warning. The decisive number is that the pixel counts are
*identical* either way — 25525 pixels of `base00` in the rail under both the
light and the restored dark palette, 29397 against 29439 of `base02`. The
palette flip changes colour and moves no geometry, which is what "the shell
survives it" means. Dark was restored and confirmed restored.

The one hardcoded colour is `panels/WallMatch.qml:111`, which derives base06 by
lerping the foreground toward `"#ffffff"`. In a dark scheme base06 is lighter
than base05 and that is right; in a light scheme base06 runs *darker*, so a
wallpaper-matched light palette publishes a base06 pointing the wrong way. The
shell itself never reads base06, so nothing here changes appearance — the cost
falls on other applications reading the published palette. Small, real, and left
alone because `WallMatch.qml` was not in scope. See "Handover" below.

### 4. Wallpaper and theme-switcher survey — DONE

`docs/surveys/wallpaper-survey.md` exists, 38KB, committed.

### 5. Wallpapers moved to `~/wallpapers` — PARTIAL, and the missing half bites on rebuild

The shell half is done: `panels/Wallpapers.qml:21` reads `$HOME/wallpapers`,
`~/wallpapers` exists with 17 files, and `~/Pictures/wallpapers` is gone.

The dotfiles half is committed but **stranded on an unmerged branch.** The fix
is `ce9b1755`, on `claude/notifications-dark-mode-fix-2b275e`. On `main` —
which is what `/home/erikf/.dotfiles` has checked out and what a rebuild would
use — `modules/nixos/syncthing.nix:81` still declares `path =
"~/Pictures/wallpapers"`.

So the next `nixos-rebuild switch` from `main` puts syncthing back on the old
path, recreates `~/Pictures/wallpapers`, and leaves the picker pointing at a
`~/wallpapers` that nothing syncs any more. New wallpapers from the laptop would
land where the shell does not look. The stranded commit's own message predicts
this: "when they disagree the picker is empty while the disk is full."

Not fixed here, because the fix already exists and the action needed is a merge
decision on a branch carrying unrelated commits.

### 6. Clock redesign — DONE

Superseded and landed. `RailClock.qml` measures 30px and documents how it gets
there (`RailClock.qml:13-20`); it is instantiated at `shell.qml:852`.

### 7. Network panel VPN and IP — DONE, with one thing left behind

`ce20efc` and `64d5e6a` both landed. The leftover is item 1 of the known-open
list, below.

## Known-open items

### `panels/Monitor.qml:145-146` read a property nothing fills — FIXED

This is the same failure mode as the wifi list that sat empty and ticked for a
day, and it is worth naming precisely because it is the pattern to keep
hunting.

`Sys.net` is filled from the output of `~/.local/bin/network-status.sh`
(`Sys.qml:222-234`). **That script does not exist on this machine** — verified
by `ls`. The `Process` fails, the `catch` sets the property to `""`, and the
readout therefore said "offline" in `Theme.bad` over a live gigabit link,
permanently and silently. Nothing logs, because a failed `Process` and a caught
`JSON.parse` are both quiet.

Ground truth measured rather than assumed: `ip -j route` gives a default route
via `eno1`, and `/sys/class/net/eno1/speed` reads 1000.

Rewritten onto the `Net` singleton, which works the interface out from the
default route — the same source `64d5e6a` moved the rail glyph onto, so the two
now cannot disagree. Committed as `4f2ced3`.

Verified on the running shell. The rail glyph is tinted `Theme.bad` when
`Net.online` is false; a pixel count over the rail crop finds **zero** `#fb4934`,
so `Net.online` is true and `Net.link` is populated. The reload logged no
binding warning, which is what a property that failed to resolve would have
produced — the check that would have caught the original wifi bug.

One number that misleads, recorded so the next audit does not chase it: the
monitor panel crop *does* contain 898 exact `Theme.bad` pixels. Those are the
disk bar, which `Theme.heat` turns red at 90% and the disk is at 95%. It is not
the network readout.

### `Sys.qml:222-234` — now dead code, NOT DONE, not owned

`panels/Monitor.qml` was the only reader of `Sys.net` in the entire shell. With
it moved, the `netProc` `Process` and the `net` property are unreachable: the
shell still forks a shell every sample tick to run a script that does not exist.
`Sys.qml` belongs to another agent this session, so the deletion is written up
in "Handover" rather than made.

### `Ring.qml` keeps the old accent after a theme switch — CONFIRMED, not owned

Real, and confirmed by reading it. `Ring.qml:50-51` requests a repaint on
`onValueChanged` and `onHeatChanged` and on nothing else. `Canvas` caches its
scene graph node, so the arcs — drawn in `Theme.line` and `Theme.heat(...)` at
`Ring.qml:35` and `Ring.qml:43` — keep the previous palette until some *value*
happens to move, which is up to a full sample tick later. The file's own comment
already says "Canvas does not repaint on property change by itself"; the two
handlers cover geometry and nothing covers colour.

`Ring.qml` is owned by another agent. Exact change in "Handover".

### `panels/Widgets.qml` — reachable, DONE

It exists and is live. `panels/Control.qml:102` instantiates it as
`Pages.Widgets`, the control centre's tray page. The chevron being gone did not
strand it — the clock is the control centre's button now, and this is the page
behind it. Its content matches the tray-only rule: it lists
`SystemTray.items` and nothing else, pinned first, with the pin button as the
only control.

## Requirements that were unticked and are actually done

Four boxes were open in `REQUIREMENTS.md` that the code has satisfied. All four
are ticked in this pass.

- **Panels go full height and drop the fillets when content fills the screen.**
  Implemented, and it encodes his own threshold verbatim: `shell.qml:929-934`
  drops a corner "exactly when the screen edge would start cutting it — Erik's
  rule". `room` is `win.height` (`shell.qml:896`), so a card may run the whole
  screen, and `squareTop`/`squareBottom` (`shell.qml:935-937`) square the ends.
  His worry that it would "snap between the two looks as a list populates" is
  addressed at `shell.qml:907-913`: the clamp engages only at the moment the
  free position equals the bound, so a panel growing while open slides into the
  edge instead of jumping.
- **At least one light theme, and the shell survives it.** Two, and it does.
  Evidence under item 3.
- **A centred overlay listing every published base16 scheme.** All 335, under
  item 3.

## Requirements that remain genuinely open

- **"Rail is not cramped"** — left unticked deliberately. The slot unification
  in `Theme.qml:60-77` was aimed straight at it and says so: one 28px slot with
  a 5px gap for every control, which "gains the pills four pixels and takes six
  back off every button, which is the direction the rail was wrong in: cramped
  at the top, loose at the bottom." So work has been done and the reasoning is
  sound. But this is a judgement he makes by eye from a screenshot, and he has
  not made it. Ticking it would be an agent grading its own homework, which is
  how this file went wrong before.
- **Battery over 24h** — deferred by him, and the quote is already in the file:
  *"that is an entirely different application, won't be doing that now."* No
  action.
- **Build the keyboard cheatsheet** — never asked for. He asked whether it was
  possible; `docs/keyboard.md` answers yes three times. Leave open.

## Handover — exact changes, in files this pass did not own

**`Ring.qml`** — repaint the arcs when the palette changes. `Theme.palette` is a
plain property, so it has a change signal already:

```qml
    // Canvas caches its node, so a colour that changed underneath it is not
    // noticed by anything: the two handlers above cover geometry and nothing
    // covered the palette. A theme switch left the arcs on the old accent
    // until the next sample tick happened to move a value.
    Connections {
        target: Theme
        function onPaletteChanged() { c.requestPaint(); }
    }
```

**`Sys.qml`** — delete the `netProc` `Process` block (lines 222-234) and the
`net` property it writes. Nothing reads either since `4f2ced3`, and the block
forks a shell per tick for a script that is not on disk. Check for a `netProc`
trigger in whatever timer drives the sampling and remove that call too.

**`modules/nixos/syncthing.nix` in the dotfiles** — already fixed by `ce9b1755`
on `claude/notifications-dark-mode-fix-2b275e`. Needs a merge to `main`, not a
new edit. Until then a rebuild silently undoes the wallpaper move.

**`panels/WallMatch.qml:111`** — `base06: root.lerp(fg, "#ffffff", 0.3)` should
lerp toward the scheme's own background rather than white, so a wallpaper-matched
light palette publishes a base06 that runs the right way. Cosmetic for this
shell, which never reads base06; it matters to applications consuming the
published palette.
