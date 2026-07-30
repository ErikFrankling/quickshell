# The Hyprland-Lua session: what I found

## 1. Did I find it? No — because it is this session

I could not find a separate session about a Hyprland Lua rewrite. What exists is
**research done inside the current session**, and a written-up section in the
Quickshell repo. I think that is what you are remembering.

### What I searched

| Store | Scope | Result |
|---|---|---|
| `mcp__ccd_session_mgmt__search_session_transcripts` (the MCP tool) | query "hyprland lua" | **No matching sessions found** |
| `/home/erikf/.claude/projects/**/*.jsonl` | all 25 project dirs, ~200 transcripts incl. subagents | only the current session |
| `/home/erikf/.claude/history.jsonl` | 3,472 prompts you have typed into Claude Code, all projects, all time | 5 hits for "hypr" (GPU/VRAM crashes, MATLAB scaling), **zero** for Lua + Hyprland together |
| `/home/erikf/.codex/sessions` + `archived_sessions` | 2,085 Codex rollout files | hyprlang/`configType` appear only as build-warning text; no design discussion |
| `/home/erikf/.codex/history.jsonl` | 1,583 Codex prompts | 2 hits for "hypr", neither about Lua |
| Filesystem (`~/projects`, `~/.dotfiles`) | `hyprland.lua` / `configType.*lua` | one file: `docs/research.md` in the Quickshell repo |

I grepped raw JSONL (not filtered to `type=="user"`), so mid-turn
`queue-operation` messages were included. Method: ripgrep + jq. The MCP search
tool returned nothing, so everything below comes from grep.

### What actually exists, and where

Three research passes in **this** session, id `a86c222d-110d-4226-a5b0-f35e8c06695c`
(project dir `-home-erikf--dotfiles--claude-worktrees-notifications-dark-mode-fix-2b275e`):

- `subagents/agent-a62a95dd8f25e4a58.jsonl` — "Research the state of Hyprland's
  configuration language direction, specifically any move to Lua"
- `subagents/agent-ada8265ae6b82fe49.jsonl` — the Lua bind API specifically
- `subagents/agent-a5b6b180bc20707de.jsonl` — Omarchy's Lua bind helper

Their conclusions were written up as **§7 and §10 of
`/home/erikf/projects/personal/quickshell/docs/research.md`**. That is the
durable artefact — it survives the session.

---

## 2. What was decided, and what it says

Caveat, stated plainly: §7 is a written conclusion in your repo, not a verbatim
decision of yours. I found no message where you said what you wanted done. So
these are quotes from the document, not from you.

From `docs/research.md` §7, "Hyprland is already on Lua":

> Not a proposal — shipped in **0.55.0 (2026-05-09)**, and the wiki states
> *"Since Hyprland 0.55, hyprlang is deprecated in favor of lua"*, with support
> for **1–2 releases**. Current release is 0.56.1.

> **This should be a separate PR from the shell work**, and it is the more
> time-sensitive of the two — hyprlang has roughly one release left.

And §10, open question 4:

> **Hyprland-Lua migration: before, during, or after?** Recommendation: before,
> and separately. It is time-boxed by upstream deprecation and touches
> different files.

The load-bearing facts behind that:

- Config becomes `~/.config/hypr/hyprland.lua`, everything on a global `hl`
  table. Binds return handles (`:set_enabled(false)`), loops work, window rules
  become tables with a `match` block, `exec-once` becomes
  `hl.on("hyprland.start", fn)`.
- New capability, not available before: event callbacks
  (`hl.on("window.open", …)`), timers, in-process state queries
  (`hl.get_windows()`), and **layouts written in Lua** (`hl.register_layout`) —
  previously a C++ plugin.
- Home Manager already supports it. `wayland.windowManager.hyprland.configType`
  is an enum `[ "hyprlang" "lua" ]` and **defaults to `"lua"` at
  `stateVersion >= 26.05`**. You are on `25.05`
  (`modules/home-manager/default.nix:38`), so you are still on hyprlang and
  have only seen the deprecation warning during rebuilds.
- **`hyprctl dispatch` now evaluates its argument as Lua.**
  `hyprctl dispatch workspace 2` errors; it must be
  `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'`. This already silently
  broke Waybar's workspace clicks (Alexays/Waybar#5008).
- hyprlang was **fully removed upstream** in commit `a9902ea6` (2026-07-22,
  PR #15539), after 0.56.0. So **0.57 forces the migration** — this is a
  deadline, not a preference.

Nothing else about the desktop shell was discussed in a separate session,
because there wasn't one.

---

## 3. What a Lua Hyprland config means for the Quickshell shell

Short answer: **less than it sounds, and the tighter-integration win you're
imagining is real but comes from somewhere else.**

### What does not change

The Lua VM lives **inside the compositor process**. An external process cannot
register Lua callbacks in it. Quickshell's `Quickshell.Hyprland` is a C++
singleton talking over the same two unix sockets (`.socket.sock` for commands,
`.socket2.sock` for events) whether your config is hyprlang or Lua. The IPC
boundary is exactly where it was.

Concretely, in your repo today the entire Hyprland surface is four places:

- `Workspaces.qml:4,17,119,129` — `Hyprland.toplevels`, `Hyprland.workspaces`,
  `Hyprland.focusedWorkspace`
- `shell.qml:7` — the import
- `shell.qml:103` and `shell.qml:512` — `IpcHandler` blocks (`target: "panel"`
  with one function per page; `target: "launcher"` with `toggle()`), meant to be
  called from a keybind as `qs ipc call panel notifs`
- `panels/Wallpapers.qml:152` — a raw `hyprctl hyprpaper wallpaper …` shell-out

None of that breaks under Lua, with one exception: **`panels/Wallpapers.qml:152`
is a `hyprctl` call and will need checking**, since `hyprctl dispatch` changes
semantics. (`hyprctl hyprpaper` goes to hyprpaper, not the compositor, so it is
probably fine — but it is the one line to verify.) Note also that nothing in
`~/.dotfiles` currently launches or binds this shell at all;
`modules/home-manager/hyprland/default.nix:78` still has
`exec-once = my-shell`, the AGS shell. The Quickshell IPC handlers exist but no
keybind calls them yet.

### What becomes possible

1. **Binds get a real description field.** This is the big one, and it is the
   thing that connects to the cheatsheet you want. Lua has a native
   `description` on `hl.bind`:

   ```lua
   hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"), { description = "Open my favourite terminal" })
   ```

   Omarchy's `o.bind(keys, description, dispatcher, opts)` helper is a genuine
   pass-through to that field, not an Omarchy-side registry.

2. **The shell can be summoned by name, cleanly.**
   `hl.dsp.global("quickshell:sidebarLeftToggle")` fires a named global shortcut
   at an external process; Quickshell receives it with a `GlobalShortcut` item.
   Your shell doesn't use `GlobalShortcut` at all today — it uses `IpcHandler`,
   which means every keypress spawns a `qs ipc call` process. Named globals are
   the better channel and they are the idiomatic Lua-era pattern.

3. **Compositor-side logic you currently can't have.** `hl.on("window.open", …)`
   plus timers means rules that are conditional, stateful, or computed — instead
   of a static `windowrulev2` string list. Your 431-line
   `modules/home-manager/hyprland/default.nix` is largely Nix generating
   hyprlang strings; under Lua, Nix would generate Lua, and the parts that are
   already `map`/`lib.range` loops in Nix could just be loops in Lua instead.

4. **The shell can push Lua into the compositor over IPC** and have it run
   in-process. That is what end-4/dots-hyprland does (a Python bridge that
   rewrites `hl.config` calls, plus `hyprctl getoption -j` and `configreloaded`
   to keep QML in sync). It works. It is also, honestly, a hack.

### What it does not give you

There is **no prior art** of a desktop shell replacing IPC with in-compositor
Lua. None exists. The Lua VM is not scriptable from outside.

The genuinely tighter integration is a different thing entirely: **Omarchy's
single-process model**, where summoning a panel is an IPC call into an
already-warm shell process rather than a cold `quickshell -p` start. That is
available to you today, on hyprlang, with no Lua at all.

### The one real trap

Under a Lua config, Lua-registered binds **lose their dispatcher identity**.
From `src/config/lua/bindings/LuaBindingsToplevel.cpp:154-157`:

```cpp
kb.handler = "__lua";
kb.arg     = std::to_string(ref);   // opaque Lua registry integer
```

Every bind reports `dispatcher: __lua` and a meaningless integer. Only
`modmask`, `key` and `description` survive into `hyprctl binds`.

So: **if you migrate to Lua without adding descriptions first, `hyprctl binds`
becomes useless for a cheatsheet.** Today your 60 binds have zero descriptions
(the config uses `bind`, `bindl`, `bindle`, `bindm` — never `bindd`), so a
cheatsheet would have to fall back to reading `dispatcher` + `arg`. After
migration that fallback is gone and description is the only data there is.
Omarchy works around it by re-parsing `hyprland.lua` with a standalone Lua
interpreter and a faked `hl` global, joining on `modmask + description`.

Converting `bind` → `bindd` in
`modules/home-manager/hyprland/default.nix:209-310` is a mechanical edit of
about 60 lines and makes the cheatsheet survive the migration unchanged. Do that
first, whatever else you decide.

---

## 4. The keyboard-cheatsheet research: it was done, but there is no report file

`docs/REQUIREMENTS.md:149-153` ticks all three:

```
## Research, for discussion rather than implementation
- [x] Can the QMK/Vial layout of the Dactyl be rendered as a cheatsheet?
- [x] Can Hyprland's binds be read (via hyprctl, not by parsing config)?
- [x] Can Neovim's keymaps be read?
```

**The research genuinely happened and was thorough. The write-up does not exist
as a file.** It lives only inside this session's subagent transcripts:

- `…/subagents/agent-a33d93853f531c6a2.jsonl` — QMK/Vial
- `…/subagents/agent-a718eaa6c07bfcc8a.jsonl` — Hyprland binds + Neovim keymaps

There is no cheatsheet document in `docs/`. `docs/` contains only
`REQUIREMENTS.md`, `research.md`, `catalogue.md`, `gallery.html`, `index.html`,
`images/`. `docs/research.md` has no cheatsheet section. Working artefacts do
survive in the scratchpad at `…/scratchpad/kbcheat/` — `vialdump.py`,
`keymap.json`, `shell.json`, `cfg.yaml`, rendered `dark.png`/`fn.png`/`*.svg`,
and a `mintree/` stub QMK tree — but the scratchpad is temporary.

**That is the finding: three ticked boxes with nothing durable behind them.**

Conclusions, so they are not lost (all three: yes, possible):

**QMK/Vial — yes, and easier than expected.** Your keymap is at
`/home/erikf/projects/3d/vial-qmk/keyboards/handwired/dactyl_manuform/5x6_64/keymaps/vial/`,
2 layers, 64 keys, no macros or tap-dances. Repo state matches what is flashed
(the LZMA blob in the hex matches `vial.json` byte for byte).
`qmk c2json --no-cpp` works offline in 256 ms. `pkgs.keymap-drawer` 0.23.0
renders it correctly, including the split thumb clusters. A 6.8 MB stub QMK tree
is enough for a hermetic Nix derivation — you do **not** need the 2 GB vial-qmk
repo as a flake input. The one hard part: QtSvg ignores `dominant-baseline` and
`paint-order`, so keymap-drawer's SVG renders with legends sitting too high;
either rasterize, post-process ~30 lines of SVG, or draw natively in QML from a
6.7 KB joined JSON. Live HID readout via Vial's protocol also works
(`vialdump.py`, stdlib-only, ~60 lines) and your existing
`/etc/udev/rules.d/50-qmk.rules` already grants access — worth adding only if
you start editing in the Vial GUI, which would make `keymap.c` go stale.
Nothing in your keyboard repos was modified.

**Hyprland binds — yes.** `hyprctl binds` returns all 60 binds in 0.8 ms;
`configreloaded` on socket2 is the refresh signal, so no polling. The gap is
descriptions, covered above.

**Neovim — yes, but it is the fiddly one.** Your config is nixCats + lazy.nvim,
which means a build-time dump is silently wrong: a bare headless run sees 106
normal-mode maps, a live instance sees 118-120, `Lazy! load all` over-reports at
132. The working path is RPC to a live instance
(`nvim --server "$SOCK" --remote-expr "luaeval(join(readfile('dump.lua'), ' '))"`),
which returned 15 KB of valid JSON, 215 described entries. which-key is present
but has no dump API and adds only group labels over raw `nvim_get_keymap` —
read `require("which-key.config").mappings` filtered to `m.group == true` for
the 7 group names, nothing more. Whitelist fields when encoding, or raw
non-UTF-8 bytes in `lhsraw` will break `JSON.parse`.

**One unrelated bug surfaced by that research, worth knowing:** your
`voxtype_suppress` submap is declared empty in
`modules/home-manager/hyprland/default.nix:161`, and Hyprland does not register
empty submaps —
`hyprctl dispatch submap voxtype_suppress` → *"submap doesn't exist (wasn't
registered!)"*. So voxtype's keystroke guard is **inert**: synthetic keystrokes
during dictation can still trigger window binds. That is the crash-during-
dictation problem you described back in the voxtype session.

---

## 5. Same PR or separate?

**Separate. And the Hyprland one should go first.**

Reasons, in order of weight:

1. **It is on a clock and the shell work is not.** hyprlang is gone from
   upstream `main` as of 2026-07-22. Hyprland 0.57 will force it. The
   notifications/dark-mode PR has no deadline.
2. **Different repos.** The Lua migration is entirely `~/.dotfiles`
   (`modules/home-manager/hyprland/`, 431 lines of Nix generating hyprlang).
   The shell work is `projects/personal/quickshell`. Zero file overlap.
3. **It is a rebuild-and-reboot change, not a hot-reload change.** If the Lua
   config is wrong you lose your compositor. Debugging that while also
   debugging QML animations is a bad afternoon.
4. **The shell does not benefit.** Lua does not dissolve the IPC boundary. The
   Quickshell shell would work identically before and after.

The ordering that makes sense:

1. **Now, in `~/.dotfiles`, standalone and small:** convert `bind` → `bindd`
   across `hyprland/default.nix:209-310`, adding a description to each of the
   60 binds. Still hyprlang. Nothing breaks. `hyprctl binds` immediately starts
   returning legible data, and this is the piece that has to exist *before* the
   Lua migration or the data is lost.
2. **Then, separately:** the Lua migration — bump `home.stateVersion` or set
   `configType = "lua"` explicitly, port the config, audit anything calling
   `hyprctl dispatch`. Time-boxed by 0.57.
3. **Independently, whenever:** the Quickshell shell, including the cheatsheet
   panel, which by then has descriptions to read.

The only thing that belongs in your current PR is nothing at all from this. It
is a clean split.

**One thing to fix regardless of all the above:** write the cheatsheet research
down. Three boxes in `REQUIREMENTS.md` are ticked and the evidence lives in a
session transcript and a `/tmp` scratchpad. Either add a §11 to
`docs/research.md` or untick the boxes.
