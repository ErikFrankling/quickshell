# A display settings GUI for the laptops: every option, measured against this setup

**The question:** Erik wants to click to change resolution, refresh, scale,
rotation and on/off and drag screens into place, with no text file and no
rebuild, remembered for each set of connected screens and re-applied on every
replug. Which existing app does that on Hyprland 0.57 (Lua) next to NixOS +
Home Manager, and what would extending `DisplaysWindow.qml` take instead?

Researched 2026-11-22 on samsung-ablo by reading source (Monique 1bba64dd,
wdisplays 1.3.0, hyprmoncfg 1.30.0, kanshi 424f454, Hyprland v0.57.2, DMS
a265f0a, Omarchy quattro c1e3553) and with read-only probes. Companion to
`monitor-runtime.md` (why the KVM needs replugs) and `monitor-arrangement.md`
(drag canvas). *Guess* marks what was not tested.

---

## 0. What decides it on this laptop (verified live)

- `~/.config/hypr/hyprland.lua` and `~/.config/kanshi/config` are Home
  Manager links into the read-only store. Any tool writes elsewhere and needs
  one include line added in Nix, once.
- kanshi (a wlr-output-management client) overrides every Hyprland monitor
  rule and every other client's change. One owner of the outputs, not two.
- AGENT-1 is a headless output, empty description, must stay on at 10000,0
  and never get Erik's workspaces; `agent`/`agent-park` stay on it.
- **The shell's current save path silently did nothing today.** At the office
  the Dell is connected twice (HDMI-A-1 and DP-1, same serial BX4V934), lid
  closed but eDP-1 on. No kanshi profile matches that set (`kanshictl status`:
  none; journal "no profile matched" since 13:40), so the three reloads from
  the displays window at 14:58 applied nothing. Also, the positions file holds
  one position per monitor, so eDP-1's 0,180 is shared by office and home.
- The KVM replug loop (MST ghost pipe, `monitor-runtime.md` §0) is not fixed
  by any of the options below.

---

## 1. Existing apps

| | Monique | wdisplays 1.3.0 + kanshi | hyprmoncfg 1.30 | DMS / dux-shell |
|---|---|---|---|---|
| Kind | GTK4 GUI + daemon | GTK3 GUI, kanshi stays the engine | **TUI** + daemon | whole shell |
| nixpkgs | no (own flake, NixOS module only) | **yes, 1.3.0 = upstream** | 1.22.1 (upstream 1.30, PR #563086 open) | `dms-shell` 2.1.2 |
| Saves per connected set | fuzzy (≥50% overlap), manual pick pinned per exact set | rewrites the kanshi profile that matches exactly, or adds a new one | scored profiles, make/model/serial | exact set |
| Auto-apply on replug | `moniqued`, 0.5 s debounce | kanshi (as now) | `hyprmoncfgd`, lid-aware | yes |
| How it applies | writes `~/.config/hypr/monitors.lua`, Hyprland `reload` | wlr-output-management, then writes kanshi file, `kanshictl reload` | writes its Lua file, `hyprctl reload`, verifies, reverts | writes `hypr/dms/outputs.lua`, reload |
| Revert timer | 10 s (GUI only) | no | yes | 10 s |
| Kanshi | must go | **kept** | must go | must go |

### Monique (GPL-3.0, 203★, last commit today, v0.8.3 + 33 unreleased)

Works on 0.57 Lua for the pickers: `require` of the written file is re-run on
every reload and watched for changes (Hyprland `ConfigManager.cpp:508-559`).
Breaks here:

- **Workspace moving is dead on 0.57**: `dispatch moveworkspacetomonitor`
  (`hyprland.py:137-139`) no longer exists and the error is not checked. Its
  "main monitor" is the first enabled one in profile order (`daemon.py:444`),
  which with eDP-1 off is AGENT-1.
- **Lid needs UPower, which is not running here**, and unknown counts as closed
  (`daemon.py:217`): docked, the built-in screen would always go off. Issue #48
  "Clamshell mode doesn't work" is open.
- **Scale is rounded to 2 decimals** (`properties_panel.py:167-172,557`): the
  Dell's 1.333333 becomes 1.33, then Hyprland corrects it.
- AGENT-1 is saved into every profile and can be dragged; the emergency
  all-off recovery never fires because AGENT-1 is always on (`daemon.py:287`).
- Two identical outputs (the doubled Dell) share one `desc:` rule.
- Its own nixpkgs pulls 1.5 GiB and builds; with `inputs.nixpkgs.follows` only
  the pure-Python package builds. NixOS polkit rule is for SDDM/greetd files
  this machine does not have (`enablePolkit = false`). Unit has a bare
  `ExecStart=moniqued` (*guess*: needs the store path on NixOS).

Integration: drop kanshi, lid binds and `kanshiPositions` from
`hosts/samsung-ablo/home.nix`; add `pcall(require, "monitors")` in
`extraConfig`; flake input with `follows`; user unit; `services.upower.enable`;
workspace moving rewritten as a Hyprland Lua `monitor.added` handler (still
needed).

### wdisplays 1.3.0 with "Save to kanshi Config" (GPL-3.0+, 289★)

Verified in the nixpkgs build: the binary carries `save-kanshi-config`,
`kanshictl` and `WDISPLAYS_KANSHI_CONFIG`. On Apply it rewrites the kanshi
profile whose outputs exactly match (keeping its name and `exec` lines) or adds
an unnamed one, then runs `kanshictl reload` (`src/store.c`). Outputs are named
make/model/serial, falling back to the connector for missing serials or
identical monitors.

- Blocker: the matching profiles live in the HM store file, so saving fails.
  Fix: profiles move to a writable file (seeded once from Nix, like
  `positions`) that kanshi includes, with `WDISPLAYS_KANSHI_CONFIG` pointing
  at it. Cost: the profiles stop being declarative; new profiles have no
  `exec` hooks, so workspace moving should move to Hyprland Lua anyway.
- Its own apply is shadowed by kanshi (first client wins), so the change
  takes effect through the `kanshictl reload`, not live. *Guess*: works, maybe
  with a flicker.
- No revert timer. Lid pairs (`office` / `office-lid-open`) are separate
  profiles with the same outputs: it rewrites whichever is active (*guess*).

### hyprmoncfg (MIT, 484★)

The most solid engine (EDID matching, lid-aware daemon, verify and revert,
detects a store-linked `hyprland.lua` and prints the one `dofile` line to add)
but a terminal UI, and nixpkgs is 8 releases behind. AGENT-1 must be saved on
at 10000,0 in every profile or it is pushed to the right edge or disabled
(`ExtendConnected`, `disable_unknown_outputs`); workspace planner must be off.
Release notes claim testing on 0.56.2 only.

### Others, ruled out

nwg-displays (GUI, no profiles), wlr-layout-ui (profiles but no daemon, eval
lost on reload), kanshi-gtk4 (one month old, not packaged, "partial" Hyprland),
kanshi_gui (Flutter, weak on Hyprland), HyprMod (whole-config profiles), hyprmon
(#92 may replace `hyprland.lua`), hyprdynamicmonitors (no Lua), monitui and
xwlm (removed `keyword` / legacy format), Noctalia (rejected upstream), Caelestia
and end-4 (nothing), HyprPanel (archived), Omarchy panel (per monitor, needs
Omarchy). KDE kscreen and GNOME display settings cannot run on Hyprland
(libkscreen has only KWin and fake backends; GNOME talks only to Mutter).

---

## 2. Extending the shell's window

Three architectures were weighed:

- **A. Keep kanshi, shell writes full per-set profiles into an include placed
  first.** Must write lid pairs together and name them after the Nix profiles;
  copied `exec` hooks embed store paths that go stale; the pc has no kanshi so
  needs a second mechanism. Two systems.
- **B. Per-monitor kanshi defaults only.** Cannot save position or on/off per
  set (today's bug). Rejected.
- **C. Drop kanshi; a ~130-line Hyprland Lua module from the shell repo
  applies a state file.** Recommended by the review.

C in detail:

- State file `~/.local/state/erikshell/displays`, tab-separated, KWin's split:
  `mon` lines (mode, scale, rotation per physical monitor, keyed by
  description, plus connector when two share one) and `set` lines (on/off,
  position, workspace screen per connected set).
- Rules issued as `desc:<description>`, so MST renames do not matter, and on
  load, so the first connect lands on the right mode in one modeset (today
  Hyprland's rule then kanshi's two profile switches modeset three times).
- `monitor.added` / `monitor.removed`: recompute the set (skip headless),
  re-issue positions (soft, no modeset), eDP-1 follows the lid read from
  `/proc/acpi/button/lid/LID0/state`, never disable the last real screen, move
  user workspaces (the existing `dock-workspaces` Lua, skipping
  `agent`/`agent-park`). Lid binds call the same Lua. Callbacks have a 50 ms
  limit (`LuaCaller.hpp:37`): file reads fine, `io.popen` not.
- Shell: preview with `hyprctl eval 'hl.monitor{...}'` (works once kanshi is
  gone), save = write the file + `hyprctl eval 'erikshell_displays.apply()'`,
  revert = old contents + apply. Rebuild reloads re-read the file.
- UI: click selects a screen; off screens in a grey strip; chips for On/Off
  (greyed for the last real screen, AGENT-1 not counted), resolution,
  refresh (down to 24 Hz, the KVM needs 4K/30), clean scales labelled with
  logical size, rotation, "gets workspaces". Keep/Revert bar for 15 s on mode,
  refresh, scale, on/off, keeping the oldest snapshot; position changes save
  at once.
- Code to take (MIT): Omarchy `Model.js` 22-80 (clean scales), 90-118, 137-158
  (modes, minus its 59.5 Hz floor), `monitor-settings.lua` structure; DMS
  `OutputModel.js` 1143-1156, 1205-1227, 349-358. GPL shells: ideas only.
- Size: ~420 new lines (Displays.js ~120, DisplaysControls.qml ~170, Lua ~130,
  Nix ~25). Same module on the pc and framework, so one mechanism everywhere.
- Rules to change: `docs/REQUIREMENTS.md:21` and AGENTS rule 1 say "No
  settings GUI, ever"; displays needs an explicit exception.
- Testing: JS against today's `hyprctl` fixtures; Lua and UI in a nested
  `LIBSEAT_BACKEND=none` Hyprland with `hyprctl output create/remove`
  (*guess*: headless outputs have no description, may need an override); then
  undocked on the laptop; then Erik at both docks (an agent cannot plug in).

---

## 3. Verdict

| | Clicks only | Per set + replug | Lid | AGENT-1 safe | Effort | Risk |
|---|---|---|---|---|---|---|
| Monique | yes | yes (fuzzy) | broken here (no UPower, #48) | no (workspace move dead, AGENT-1 can be main) | 1 session + patches or Lua handler | medium, young, needs fixes upstream |
| wdisplays + kanshi | yes, no revert | yes (exact, kanshi) | as now | yes (kanshi as now) | smallest, ~1 hour | profiles leave Nix; doubled-Dell style sets get new hook-less profiles |
| hyprmoncfg | TUI | yes, best engine | yes | with care | 1 session | TUI, nixpkgs behind |
| Shell option C | yes, revert | yes | yes | yes, by design | 2-3 sessions + Erik at docks | medium, our own hotplug code |

Cheapest real try: wdisplays with saving on, against a writable profiles file.
Most complete: shell option C. Monique only after the workspace-move and lid
fixes, which are as much code as C's Lua module.

## Sources

- https://github.com/ToRvaLDz/monique (1bba64dd), issues 48, 51, 52
- https://github.com/artizirk/wdisplays (1.3.0, `src/store.c`, CHANGELOG)
- https://github.com/crmne/hyprmoncfg (1.30.0, `hypr/monitor.go`,
  `profile/hotplug.go`, `profile/match.go`), issues 90, 132; nixpkgs PR 563086
- https://github.com/duxlabs-dev/dux-shell, https://duxlabs.dev/blog/v1-5-release
- https://github.com/grigio/kanshi-gtk4, https://github.com/nurkert/kanshi_gui,
  https://github.com/fdev31/wlr-layout-ui, https://github.com/BlueManCZ/hyprmod,
  https://github.com/erans/hyprmon (#92), https://github.com/fiffeek/hyprdynamicmonitors (#151)
- https://github.com/omacom/omarchy (quattro), PR 17159
- Hyprland v0.57.2: `ConfigManager.cpp`, `MonitorRuleManager.cpp`,
  `MonitorRule.cpp`, `Monitor.cpp`, `LifecyclePolicy.cpp`, `LuaCaller.hpp`,
  `OutputManagement.cpp`; Hyprland discussions 15493, 15526, PR 15570
- kanshi https://gitlab.freedesktop.org/emersion/kanshi (`main.c`, `config.c`, `ipc.c`)
- Home Manager `modules/services/window-managers/hyprland` (`lib.nix`, `default.nix`)
