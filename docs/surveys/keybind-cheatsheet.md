# Keybind cheatsheets, in sixteen other shells

Prior art read before writing `KeysWindow.qml`, `KeyBoard.qml` and `Keymap.qml`.
Everything below cites a file and a line in a real project.

Of the sixteen shells surveyed — noctalia plus the fifteen clones under the
session scratchpad — **two** have a keybind cheatsheet, **one** has a keybind
*editor* that reads `hyprctl binds -j` but never displays it, and **none**
render a physical keyboard.

| Shell | File | LOC | Where the binds come from | Refresh | Render | Grouping | Window |
|---|---|---|---|---|---|---|---|
| whisker | `windows/keybinds/KeybindsListWindow.qml` | 274 | its own shipped `.conf`, plus `#` comments | none | nested `Repeater` | `## Header ##` | fullscreen `PanelWindow`, 800×600 card, IPC |
| Ricelin | `pill/Keybinds.qml` + `lib/binds.js` | 928 | the user's `binds.lua`, parsed | `watchChanges: true` | `ListView`, filtered | none — search instead | pill surface, 460px, IPC |
| Brain_Shell | `config_tab/KeybindService.qml` + `KeybindsPage.qml` | 405 + 609 | hardcoded defaults; `hyprctl binds -j` only to detect conflicts | after its own write | `Column` + `Repeater` | a `group` field | embedded settings tab |
| skwd-wall | `settings/KeybindsSettings.qml` | 55 | hardcoded literals | none | `Flow` of cards | two cards | embedded settings |
| noctalia | `Commons/Keybinds.qml` | 201 | n/a — shell navigation keys only | n/a | n/a | n/a | n/a |

## Nobody renders binds from `hyprctl`

The only production reader is Brain_Shell:

```qml
// Brainitech_Brain_Shell/src/services/config_tab/KeybindService.qml:54-63
property var _hyprBindsProc: Process {
    command: ["hyprctl", "binds", "-j"]
    running: false
    stdout: StdioCollector {
        onStreamFinished: {
            try   { root._hyprBinds = JSON.parse(text.trim()) }
            catch (e) { root._hyprBinds = [] }
        }
    }
}
```

and it keeps only the modmask and the key, to warn when a bind it is about to
write collides with one already there. It never shows a bind to anybody. Its
filters are worth quoting anyway, because they are the same three a cheatsheet
wants and does not want (`KeybindService.qml:91-93`): skip submaps, skip mouse
binds, skip the shell's own `qs ipc` binds.

Note the `try`/`catch` around `JSON.parse` in that snippet, which is doing more
work than its author knew — see the next section.

The reason nobody else reads `hyprctl` is the same reason the description
problem is hard: `hyprctl binds` gives you `dispatcher`, `arg` and `modmask`,
and — until you write `bindd` — nothing a human wrote. So both shells that do
show a cheatsheet parse a *config file* instead, for the comments.

## `hyprctl binds -j` does not emit JSON on Hyprland 0.56.0

Measured on the running compositor, `Hyprland 0.56.0 built from branch main at
commit 36b2e0c`, on 2026-08-01:

```
$ hyprctl binds -j | jq .
jq: parse error: Invalid numeric literal at line 15, column 22
```

The writer emits the *values* one position out of step with the key names, so
`modmask` gets `false`, `submap` gets the modmask, `key` gets the submap and
`keycode` gets the key — and it prints that key unquoted:

```
"submap": "64",
"submap_universal": "",
"key": "false",
"keycode": Return,          <- bare token, not a string
"catch_all": 0,
"description": "false",
"allow_input_capture": ,    <- no value at all
"dispatcher": "exec",
```

`JSON.parse` throws on it, which is why Brain_Shell's `catch` returns an empty
array and its conflict detection has presumably been silently off. The plain
`hyprctl binds` output is correct and well formed, one `bind` header per record
and `\tkey: value` under it, so that is what `Keymap.qml` parses. This is not a
detail of this machine: it is the shipped 0.56.0 writer.

## What each does when a bind has no description

This is the whole problem, and the three answers are quite different.

- **whisker** resets `currentDescription` to `""` after each bind
  (`KeybindsListWindow.qml:67`), so a bind with no preceding `#` comment renders
  with an empty label. It gets away with it because it only ever lists its own
  six binds, all of which are commented.
- **Ricelin** has the best answer: an explicit trailing Lua comment as the name,
  and failing that a *derived* label. `binds.js:52-77` pattern-matches the
  action — `window.kill` → `"kill window"`, a workspace-relative focus →
  `"workspace +1"`, an `exec_cmd` reduced to the basename of the script it runs
  (`binds.js:55-57`) — and falls back at `binds.js:76` to
  `action.replace(/^hl\.dsp\./, "").replace(/\(\)$/, "")`.
- **Brain_Shell** never has the problem, because it authored every bind itself.

`Keymap.qml` takes the middle road but declines Ricelin's pattern table: 59 of
this machine's 61 binds have no description, and a table of guesses about what
`exec` means would be sixty lines of code asserting things the shell cannot
know. The dispatcher and its argument stand in, and are drawn dim and italic so
the sheet cannot be misread as claiming somebody wrote that label. The two binds
that *do* have one are the two `bindd` lines pointing at this shell's own
`GlobalShortcut`s — which is the argument for converting the rest, in the
dotfiles, where it belongs.

## Nobody refreshes on `configreloaded`

`configreloaded` is subscribed in three of the sixteen —
`Gakuseei_Ricelin/configs/quickshell/pill/Singletons/Workspacerules.qml:55`,
`doannc2212_quickshell-config/monitor-manager/MonitorService.qml:228`,
`noct4/Services/Compositor/HyprlandService.qml:580` — and all three use it for
monitor state only. Ricelin's `watchChanges: true` on the config file
(`Keybinds.qml:276-284`) is the closest thing to live bind refresh in the corpus.
`Keymap.qml` uses the event, because a bind list that is stale after a reload is
a bind list that is wrong exactly when he changed something.

## Nobody uses `ScriptModel`

All four bind lists bind a plain JS array straight to `model:`. Ricelin's
`filtered` (`Keybinds.qml:67-74`) rebuilds the whole array on every keystroke and
rebinds the `ListView` to it. That is fine here too — a plain array is not a
live `.values`, which is the thing that needs `ScriptModel` — but it is worth
knowing that the corpus is not evidence either way.

One left-in bug worth not copying: whisker calls `Log.info(...)` *inside* its
model binding (`KeybindsListWindow.qml:169`), so the entire keybind list is
re-serialised to JSON every time the binding re-evaluates.

## Nobody draws a keyboard

Grepping all sixteen for `qwerty`, `keymap-drawer`, `qmk`, `keyboardLayout` and
literal key-row arrays finds nothing. The only hits are
`josecriane_quickshell-config/services/Niri.qml:90,94,99-100`, which handles
niri's `KeyboardLayoutsChanged` to put a layout *name* — "us", "se" — in the bar.

The closest anything gets to a keycap is whisker's per-key chip
(`KeybindsListWindow.qml:198-217`): a bordered rect with a 3px bottom bar to
suggest a keycap edge, laid out in a row. Not positioned on a board.

So `KeyBoard.qml` has no prior art in this corpus to copy, which is why it copies
the *data* instead: `keyboard.json` already states every key's `x` and `y` in key
units, and the generated `LAYOUT()` macro in `keymap.c` lists keycodes in exactly
that order. Drawing is then a `Repeater` over 64 positions. See `docs/keyboard.md`
for why the `keymap-drawer` SVG was not used.

## Two ideas taken from the survey

- **whisker's window shape** is the same shape this repo already uses for the
  launcher and the themes browser — fullscreen `PanelWindow`, centred card,
  `Math.min(win.width - 80, 800)` (`KeybindsListWindow.qml:109-110`), IPC to
  open. That agreement is why `KeysWindow.qml` did not need designing.
- **whisker ships no bind that opens its own cheatsheet.** `IpcHandler` at
  `KeybindsListWindow.qml:84-89` is the only door, so you must type
  `whisker ipc keybinds toggle` to read the list of keys you have forgotten.
  `KeysWindow` gets a `GlobalShortcut` as well, for that reason.

## Where the sources are

noctalia at `.claude/worktrees/notifications-dark-mode-fix-2b275e/noct4/`; the
rest under the session scratchpad's `clones/` directory —
`corecathx_whisker`, `Gakuseei_Ricelin`, `Brainitech_Brain_Shell`,
`liixini_skwd-wall`, `josecriane_quickshell-config`,
`doannc2212_quickshell-config` and the others. Both are deleted with the
session, which is why the quotes above are here rather than a link.
