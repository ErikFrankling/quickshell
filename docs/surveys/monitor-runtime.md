# Runtime monitor control on the laptops: why docking needs replugs, and what to build

**The question:** on samsung-ablo the home KVM (two Samsungs over one USB-C
cable) needs about five replugs before every screen comes up at the right
mode. What causes that, how do others make dock/KVM laptops easy on Hyprland,
and what should the shell add beyond positioning (`monitor-arrangement.md`):
resolution, refresh and scale pickers, on/off, re-detect, a revert timer and
settings saved per connected set?

Researched 2026-11-22 on samsung-ablo (Hyprland 0.57.2, aquamarine 0.16.0,
kernel 7.3.5 `xe`, kanshi 1.9.0) with read-only probes, plus Hyprland v0.57.1
and current master, kanshi, shikane and fifteen shells' source. Claims marked
*guess* were not tested.

---

## 0. Diagnosis on this machine (verified live)

The machine is a Galaxy Book6 Pro, Panther Lake (`8086:b0a0`, `xe`). The KVM
dock's hub is a Kinetic KTM50x0 MST branch (OUI 0060ad, fwupd `kinetic_dp`,
firmware 0.013.18). Both Samsungs are MST streams: their DRM connectors carry
a `PATH` property, which is why the names rotate (DP-3, DP-4, DP-5 ...).

**A ghost stream holds a pipe.** `/sys/kernel/debug/dri/*/i915_display_info`:

```
[CRTC:272:pipe B]:
	uapi: enable=yes, active=yes, mode="2560x1440": 60 241500 ...
	pipe src=2560x1440+0+0, dither=yes, bpp=18
	port_clock=810000, lane_count=2
	[ENCODER:527:DP-MST B]: connectors:
		[CONNECTOR:575:DP-4]
...
[CONNECTOR:575:DP-4]: status: disconnected
```

Pipe B is still scanning out the U28D590's previous session on a connector
that no longer exists. `drm_info` shows that connector with
`link-status: Bad`. The MST payload table (`i915_dp_mst_info`) still allocates
22 of 63 slots to it ("Local", sink "Unknown"), and the hub's own table is
empty there.

**How it got there (Hyprland log).** On undock aquamarine's
`SDRMConnector::disconnect()` sends a blocking disable; the kernel returns
EINVAL, the log says `Failed to disable KMS output DP-4 before disconnect`,
then `clearing stale crtc 272`: aquamarine forgets the pipe, the kernel keeps
it. The kernel log has `xe ... Failed to get ACT after 3000 ms, last status: 00`
at each such event (the hub never accepted the payload table update).

**What the next plug sees.** DP-3 was given CRTC 272, the ghost's pipe. Every
atomic TEST_ONLY commit fails with EINVAL for every mode, 3840x2160 down to
640x480, so `REJECTED available mode ...`, `NO FALLBACK MODES`, then
`scheduleModeRetry ... (3/3)` and Hyprland gives up with DP-3 enabled at 0x0.
Later it came back on another pipe, 4K@30 no longer fit beside the ghost's
bandwidth, and it fell back to 1920x1080.

So the replugs are a lottery on whether the new pipe assignment avoids the
ghost. Neither kanshi nor the mode list is at fault.

### Bandwidth: the target only fits at 6 bpc

Link: DP alt mode, pin assignment D, **2 lanes** (USB 3 shares the cable) at
HBR3 (`port_clock=810000`). That gives `pbn_div 30`, 63 usable slots.

| Configuration | Slots of 63 | Fits |
|---|---|---|
| 4K30 + 1440p60, both 8 bpc | ~67 | no |
| 4K30 + 1440p60, both 6 bpc (today, dithered) | ~50 | yes |
| same + the 22-slot ghost | ~72 | no (why 4K was refused) |
| same on a fallback HBR2 x2 link | ~73 | no |

Pixel clocks from the EDIDs (297.0 and 241.5 MHz); slot cost scaled from the
kernel's measured 660 PBN for 1440p at 18 bpp. 8 bpc needs a 4-lane mode
(USB 2 on the cable) or a lower mode on one screen.

---

## 1. Fixing the replug loop

| Remedy | Clears the ghost | Notes |
|---|---|---|
| Replug | sometimes | what happens now |
| `hyprctl reload`, `dpms off/on`, re-applying a rule, `kanshictl reload` | no | Hyprland has no handle on the orphaned pipe; aquamarine#429 reports all return ok and change nothing |
| **VT switch** (Ctrl+Alt+F2, back) | yes | fbcon does a full modeset that drops stale pipes, Hyprland restores (aquamarine#438) |
| Restart Hyprland | yes | loses the session |
| `AQ_NO_ATOMIC=1` | *guess: partly* | legacy SETCRTC goes through `drm_atomic_helper_set_config`, which steals conflicting encoders (v7.3 `drm_atomic_helper.c:3509,3525`); fixes "every mode EINVAL", not the ghost's bandwidth on another pipe. Listed as a workaround in aquamarine#454/#481/#483 |
| `xe.enable_dp_mst=0` | n/a | single stream: one screen only |
| udev rule on the dock's USB device that runs `chvt 2; chvt 1` a few seconds after plug-in | yes | from aquamarine#438 |
| Upstream fix | — | aquamarine#386 (closed by PR #410, the patch `overlays/aquamarine.nix` backported for 0.15.0) added the disable; why the kernel rejects that disable on 0.16.0 is unreported. Needs a `drm.debug=0x16` capture of an undock. Related open: aquamarine#384, #429, #431, #438, #440; reconciliation PRs #436 and #465 closed unmerged |

Kernel side: the Sept 2026 MST FEC/TU fixes for disconnected streams
(acbe9a3b60b9, a443e0b8d647) are already in v7.3; nothing newer for ACT was
found in v7.4-rc. Trackers: drm/i915 #17741, #16303, #2432; drm/xe #8169,
#8631. i915 #17848 (7.3 dock regression) is Thunderbolt, not DP alt mode.

Hyprland's mode retry: `src/output/Monitor.cpp:1032-1060`,
`MAX_MODE_RETRIES = 3`, 1 s apart (PR #14927 for #10678). After the last
failure `applyMonitorRule` returns true with the monitor enabled at 0x0
(`:908-912`). More retries cannot help while a ghost holds the pipe.

Separate, smaller: at the office every dock modesets twice (`office`, then its
exec switches to `office-lid-open` when the lid is open).

---

## 2. Who owns the outputs (verified in source)

- Hyprland keeps a wlr-output-management state **per client binding**, keyed
  by connector name, merged on each apply, never dropped on unplug, only when
  that client disconnects; it survives `hyprctl reload`
  (`src/protocols/OutputManagement.cpp:316-323,378-424,598-600,644-652`).
- Resolving a monitor's rule, the **first** client (connection order) with
  state for that connector wins wholesale, including on/off; its mode,
  position, scale, transform and VRR replace the Hyprland rule's
  (`src/config/shared/monitor/MonitorRuleManager.cpp:43-82`).
- The protocol's `test` request always succeeds (`OutputManagement.cpp:351-354`),
  so a dry run cannot catch a bad mode. Hence the revert timer.

Consequences on the laptops, where kanshi binds at session start:

- `hyprctl eval 'hl.monitor{...}'`, wlr-randr and wdisplays change nothing on
  an output kanshi configured. Every runtime change must go through kanshi.
- *Guess:* a state saved for "DP-3" at one dock applies to whatever monitor
  gets that name next. Set status, mode (`mode preferred` exists since 1.9),
  scale and position for every output in every profile.

---

## 3. Tools

| Tool | Runtime change | Saved per connected set | Match key | Hyprland 0.57 | nixpkgs / HM | Verdict |
|---|---|---|---|---|---|---|
| **kanshi** 1.9.0 | edit config + `kanshictl reload\|switch` | exact-set profiles, first match wins; no export | name or `"make model serial"` glob, `...` | works | yes / `services.kanshi`, includes | **keep** |
| shikane 1.1.1 | `shikanectl switch\|reload` | exact set incl. modes; `export NAME` prints TOML | regex/substring on name, vendor, model, serial | works; FALLBACK bug (Hyprland #15774) | yes / `services.shikane` (read-only file) | no gain over kanshi |
| hyprmoncfg 1.30 | TUI + IPC `preview`, `commit{save:true}`, `scale up` | lid-aware daemon, scored partial matches | `make\|model\|serial` | native Lua, `hyprctl reload` each apply | 1.22.1 / unit only | the only "edit live, save for this set" tool; replaces kanshi, wants to edit `hyprland.lua`, treats AGENT-1 as a real monitor (*guess*) |
| monique 0.8.3 | GUI + daemon | remembers choice per set, fuzzy EDID match | description | Lua | not in nixpkgs | — |
| hyprdynamicmonitors 1.4 | TUI | profiles, `freeze` | description, regex | Lua only via own template (#151) | own flake | stale since 2026-02 |
| hyprmon 0.0.17 | TUI | profiles, no daemon | `desc:` | open bug #92 overwrote `hyprland.lua` | no | — |
| way-displays 2.0.1 | `-s`, `-w` | one global file | name/description | "Hyprland explicitly not supported" | yes | — |
| nwg-displays, wdisplays, wlr-randr | GUI / one-shot | none | — | wlr ones shadowed by kanshi | yes | — |

Desktop models for the match key: KWin (`kwinoutputconfig.json`,
`src/outputconfigurationstore.cpp`) stores mode/scale/transform per physical
monitor by EDID (MST path and connector only to break ties) and position/on/off
per set **plus lid state**. GNOME `monitors.xml` keys the set by
(connector, vendor, product, serial), so a renamed MST connector loses it.
KWin's split is the right model for this KVM.

---

## 4. Shell code worth taking

| Repo (commit) | License | Take |
|---|---|---|
| AvengeMedia/DankMaterialShell a265f0a | MIT | `Common/OutputModel.js:1143-1206` `cleanScaleNumerators` (every n with `w*120 % n == 0 && h*120 % n == 0`), `formatScaleOption` ("1.333x · 1920x1080"), `hyprlandScaleValue` (`:349-360`); `DisplayConfirmationModal.qml:11-38` 10 s revert; `canDisableOutput()` (`DisplayConfigState.qml:1422-1439`) |
| omacom/omarchy `quattro` c848212 | MIT | `shell/plugins/panels/monitor/Model.js:90-161` mode/refresh lists; `default/hypr/monitor-settings.lua:117-156` per-monitor settings file applied at load and on `hl.on("monitor.added")` (the pc's persistence); `bin/omarchy-hyprland-monitor-watch:28-62` reload with backoff while an enabled monitor is 0x0 |
| SDcold/etea-shell 4c602a9 | GPL-3.0 (ideas) | `services/Screens.qml`: mode/scale per monitor, off-list/positions per set (`:176-194`); outputs turning on sent before outputs going dark (`:227-229`); keep timer only for changes that can blank a screen |
| monishbl/tessera a2c7484 | GPL-3.0 (ideas) | a second change while confirming keeps the oldest snapshot (`Displays.qml:236-265`); position-only changes resend the current mode so no modeset |
| alexparlett/isle ae7fd27 | none (ideas) | KVM re-detect: disable every output, `sleep 1`, `hyprctl reload` (`Displays.qml:70-92`); useless on kanshi hosts |
| CryptixMC/nix-dots 39260d8 | none (ideas) | the same NixOS + kanshi setup: per-set profile written to a state file included first, then `kanshictl reload` (`SystemDisplay.qml:7-110`) |

Hyprland facts the pickers must respect (v0.57.1):

- A scale that gives fractional logical pixels is *corrected*, not refused:
  rounded to n/120, then searched ±89 steps with a red "Invalid scale"
  notification (`src/output/Monitor.cpp:942-997`). Offer only clean values.
- Disabling a monitor moves its workspaces to the **first other monitor**
  (`src/state/workspace/LifecyclePolicy.cpp:95-120`), which can be AGENT-1.
  Move them first with `hl.dsp.workspace.move`.
- `hl.dsp.dpms` sets a global flag, so a key press wakes every screen, and a
  misspelt action silently becomes `toggle`. It is not an off switch.
- `availableModes` strings carry 2 decimals (`2560x1440@59.95Hz`), `refreshRate`
  carries 3. The eDP model has a trailing space; eDP-1 and the U28D590 have an
  empty serial (kanshi spells that `Unknown`, J3R3-MY's shell got it wrong).

---

## 5. Recommendation

1. **Replug loop first**, because no UI fixes it: try a VT switch after a bad
   dock; if it reliably restores, automate it (udev on the dock's USB hub, or
   from the shell when an enabled monitor reports 0x0). Try `AQ_NO_ATOMIC=1`
   as a separate experiment. Report upstream to aquamarine with a
   `drm.debug=0x16` capture (draft only; posting needs Erik).
2. **Keep kanshi, add a shell-owned saved-profiles include** listed before the
   Nix profiles: `{ include = "$HOME/.local/state/kanshi/saved"; }`, seeded
   empty like `positions`. The displays window writes one
   `profile "saved <sorted criteria>" { ... }` per connected set, every output
   with status, mode, scale and position, AGENT-1 included; then
   `kanshictl reload`. Re-detect is the same reload (plus the VT switch for
   the MST ghost). Session-only changes go in a second include under
   `$XDG_RUNTIME_DIR`. Not handled: a saved profile replaces the Nix profile's
   `exec` hooks (move workspace routing to `hl.on("monitor.added")`), kanshi
   has no lid state (put it in the profile name), duplicate names must be
   replaced, not appended.
3. **Window additions** (`DisplaysWindow.qml`): resolution and refresh from
   `availableModes`, DMS clean scales, on/off greyed out for the last real
   output, a 15 s Keep/Revert bar for mode, scale and on/off that keeps the
   oldest snapshot, re-glue neighbours after a size change.
4. **pc** (no kanshi): the same window via `hyprctl eval`, persisted by an
   Omarchy-style Lua module that reads a state file at load and on
   `monitor.added`, so rebuild reloads keep it.

## Sources

- Hyprland: https://github.com/hyprwm/Hyprland (v0.57.1 and master 6d6e935)
- aquamarine: https://github.com/hyprwm/aquamarine issues 384, 386, 429, 431,
  438, 440, 454, 481, 483; PRs 410, 436, 465
- Linux v7.3 `drivers/gpu/drm/display/drm_dp_helper.c:1024-1048`,
  `drivers/gpu/drm/drm_atomic_helper.c`
- https://gitlab.freedesktop.org/drm/i915/kernel and drm/xe/kernel work items
  above
- kanshi: https://gitlab.freedesktop.org/emersion/kanshi (`config.c`,
  `main.c`, `doc/`); shikane: https://gitlab.com/w0lff/shikane
- https://github.com/crmne/hyprmoncfg, https://github.com/ToRvaLDz/monique,
  https://github.com/fiffeek/hyprdynamicmonitors, https://github.com/erans/hyprmon,
  https://github.com/alex-courtis/way-displays
- KWin `src/outputconfigurationstore.cpp`, mutter `src/backends/meta-monitor.c`
- Shells: links in section 4 (GitHub, commits as listed)
