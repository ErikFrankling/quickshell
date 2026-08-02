# A keyboard shortcut cheatsheet: what is possible

Erik asked whether three things could be read and rendered as one cheatsheet —
his Dactyl Manuform's QMK/Vial layers, his Hyprland binds, and his Neovim
keymaps. This is the answer to that question, and — since 2026-08-01 — the
record of the two thirds of it that shipped.

All three are possible. The difficulty is not where you would guess.

## What shipped

`KeysWindow.qml` — a centred overlay in the launcher's shape, Escape to
dismiss, on `qs ipc call keys toggle` and a `GlobalShortcut`, no rail button.
**Three pages behind a chip strip**, in `panels/Control.qml`'s shape: the
Dactyl's layers, Hyprland's binds, Neovim's keymaps. The card takes its height
from the page showing, so the board — wide and short — does not sit in a window
sized for the bind list. Left and right walk the pages; Tab flips the Dactyl's
layers on the board page and walks the pages elsewhere.

`Keymap.qml` is the Dactyl's data; `KeyBoard.qml` draws the board; each page
under `keys/` owns its own source, because `hyprctl binds` answers in under a
millisecond and there is nothing to cache between openings.

Measured on the running shell: 61 binds in four modifier groups (Super 32,
Super+Shift 16, no modifier 9, Super+Alt 4), 64 keys, 2 layers, 402 Neovim
entries. Board 828×322 at a 46px key pitch, in an 880-wide card.

### The one thing the research got wrong

`hyprctl binds -j` **is not JSON** on Hyprland 0.56.0. The writer emits the
value list one position out of step with the key names, prints `keycode` as a
bare token and leaves `allow_input_capture` with no value at all; `jq` gives up
at line 15 and so does `JSON.parse`. The plain `hyprctl binds` output is
correct, and is what `Keymap.qml` parses. `docs/surveys/keybind-cheatsheet.md`
has the offending bytes, and notes that the one other shell in the wild reading
`binds -j` has a `catch` that has been silently swallowing this.

Two of the 61 binds now carry a description — the two `bindd` lines pointing at
this shell's own `GlobalShortcut`s. The other 59 fall back to their dispatcher
and argument, drawn dim and italic so the sheet is never read as claiming
somebody wrote that label. Converting the rest to `bindd` is still the fix, and
still belongs in the dotfiles rather than here.

## The keyboard — easier than expected

Two layers, 64 keys, no macros or tap-dances.

**Where it is read from changed on 2026-08-02**, and the rest of this section
is the record of how it used to work. The sheet said "0 keys · 0 layers" on the
Framework, because the QMK checkout it read is on the PC and only the PC. It
now reads the layout **off the keyboard over Vial's raw-HID protocol**, and
falls back to a committed baseline when no board answers.
`docs/surveys/vial-hid.md` is the full record: the protocol with sources, the
descriptor match, the write framing, what was tested against a simulated board
and what could not be tested without the hardware.

`qmk c2json --no-cpp` converts it offline in 256 ms, and `pkgs.keymap-drawer`
0.23.0 renders it correctly including the split thumb clusters. A 6.8 MB stub
QMK tree is enough for a hermetic derivation; the 2 GB `vial-qmk` repo does
**not** need to be a flake input.

The one real obstacle is rendering, and the first answer to it was wrong in two
ways. `docs/surveys/keyboard-render.md` is the full record; both corrections
matter.

**`keyboard.json` is the wrong file to draw from.** It gives every key an `x`
and a `y`, but with the rotation stripped: it descends from a manually
de-rotated KLE export made to feed kbfirmware.com. `keymaps/vial/vial.json`
descends from the export that kept it, and carries **two ±15° thumb clusters**
(`r: 15, rx: 5.25, ry: 4` and `r: -15, rx: 12.75`). That is not decoration —
in raw coordinates the two clusters overlap by 0.75 u, and only the rotation
separates them, so a flat drawing of this board is an invalid one rather than a
simplified one. Drawn rotated, no two caps overlap; drawn flat, two pairs do.
`vial.json` is also what the Vial GUI itself renders and what is in the flashed
firmware, so it is the truth in every sense.

**The SVG obstacle was understated, not settled.** QtSvg ignores far more than
`dominant-baseline` and `paint-order`: also `tspan` `x`/`dy` (multi-line
legends collapse to one line), `font-size` in percent (`64%` becomes 64 px),
root-element selectors, and `@media` (so dark mode never applies). A working
post-processor came to ~65 lines, not thirty, and still could not do the icon
glyphs or `clip-path`; baking the offset into `y` is required because Qt
ignores `dy` on `text` too. keymap-drawer *does* preserve rotation — that part
of the worry was unfounded — but it reads rotation from QMK `info.json`, which
for this board has none, so it would draw the same flat grid anyway.

So it is still a native QML render, and still no `qmk`, no `keymap-drawer`, no
derivation and no build step.

The three-file join described above — `vial.json` for shape, `keyboard.json`
for matrix addresses, `keymap.c` for keycodes, joined on the matrix address —
now happens in `vial.py`, once, and its output is the committed `dactyl.json`.
The board answers in the same shape, so `Keymap.qml` has one parser and two
sources rather than three parsers and one. The join itself is unchanged and the
KLE reader in `kle.js` is untouched.

`KeyBoard.qml` puts each key through its own `Rotation` — both clusters carry
their own origin, so a key turns about a point usually outside itself — and
draws Vial's two-rectangle keycap: a dark base and a lighter top inset a tenth
of a unit at the sides, a twentieth at the top and three twentieths at the
bottom. The bottom inset being three times the top is the whole 3D effect, and
KLE, VIA and kbplacer all independently landed on the same 1:3.

Three things that will bite the next person, beyond the two below: KLE's `x`
and `y` are *deltas*; setting either `rx` or `ry` snaps the cursor to a
persistent cluster origin, which is how the right thumb inherits `ry: 4`
without restating it; and the end of a row is `x = rx`, not `x = 0` — KLE's own
wiki says `x = 0` and is wrong, and `ijprest/kle-serial` master has the same
bug. Port KLE's `serial.js` or Vial's `kle_serial.py`, not the npm package.

Two things that will bite the next person: `MO(1)` and `UP(AA_LOWER, AA_UPPER)`
contain commas, so the argument split has to track parenthesis depth; and
`keymap.c` keeps a whole commented-out old keymap below the live one, so block
and line comments have to go first or you parse four layers instead of two.
Both still apply — they moved to `vial.py`.

### Reading it off the board

`vial.py` asks the keyboard directly, which is the only source that cannot be
stale: it is what is flashed, whether it was flashed from the QMK tree or typed
into the Vial GUI five minutes ago. It finds its own hidraw node by usage page
`0xFF60` and usage `0x61` — the exact pair, because this machine alone has four
other vendor pages on it that a looser match would claim — pulls the
LZMA-compressed definition in 32-byte chunks and the keycodes out of VIA's
keymap buffer, and prints the same JSON `--config` prints. Standard library
only, so `pkgs.python3` in `runtimeDeps` is the whole dependency. **That is new,
so the shell needs one rebuild before the live read can work**; until then the
helper fails to start, which is the same code path as an unplugged board.

`dactyl.json` is the baseline, committed, generated by `vial.py --config`. It
exists so a machine that has never had the keyboard plugged in still draws the
board. Regenerate it when the QMK tree changes; if that is forgotten, the board
itself is still right, which is the point of having both. The page says which
one it is showing — "from the keyboard" or "from the config" — and says "no
keyboard found" when it has neither, because an empty card looks like a board
with nothing on it, and that is a different bug.

There is no cache of the last live read. The baseline is already the offline
answer and a cache would only raise the question of which keyboard it came
from.

The existing `/etc/udev/rules.d/50-qmk.rules` already grants access, and
`modules/nixos/qmk.nix` is imported by both hosts, so nothing in the dotfiles
has to change. The ACL comes from `uaccess` and is seat-bound — over SSH, or
plugged in while the session is inactive, there is no ACL and the open fails.

## Hyprland binds — yes, with one trap

`hyprctl binds` returns all sixty in 0.8 ms, and `configreloaded` on socket2 is
the refresh signal, so nothing has to poll.

The trap is descriptions. None of the sixty binds have one today, and under a
Lua config a bind reports `dispatcher: __lua` and an opaque integer — only the
modifier mask, the key and the description survive. **Converting `bind` to
`bindd` has to happen before the Lua migration, or the data the cheatsheet
needs no longer exists.** That is roughly sixty lines in
`modules/home-manager/hyprland/default.nix`.

## Neovim — a dump, and the page for it

**The earlier claim here — that a build-time dump is silently wrong and only
RPC to a live instance is correct — was itself wrong**, and so were its
numbers. `-c` runs before `VimEnter` and `qa!` exits before it fires, which is
what made a headless run undercount. Add a `VimEnter` handler plus one
`nvim_exec_autocmds('UIEnter', {})` so lazy.nvim fires `VeryLazy`, and a
headless run reproduces a real TUI session exactly — verified against a genuine
pty, identical per-mode counts, 1.3 s. `Lazy! load all` was not over-reporting
either; it adds exactly one map. 132 was always right for normal mode.

which-key is a *better* source than `nvim_get_keymap`, not a worse one, and the
claim that it has no dump API was wrong too:
`require('which-key.buf').get({mode='n'}).tree:walk(…)` enumerates fully — 111
real keymap nodes plus 121 annotations describing Vim's own motions that
`nvim_get_keymap` cannot see (`w` "Next word", `%` "Matching (){}[]"), plus the
eight real groups, which are the page's headings. Descriptions were never the
blocker: coverage is 232 normal-mode entries with **one** undescribed.

A superset is safe, because lazy.nvim registers each spec's `desc` at startup
*before* loading the plugin — `neo-tree` reports `NOT LOADED` while its
`<leader>tr` is in the dump and works when pressed.

**`keys/Nvim.qml` reads `$XDG_CACHE_HOME/erikshell/nvim-keymaps.json`** with a
`FileView`, the same shape `Keymap.qml` uses for `keymap.c`. It collapses the
modes of one key onto one row, buckets by which-key group with the longest
prefix winning, puts the named groups first and the remainder last, and
separates his own maps from Vim's own annotations behind two chips. When the
file is absent it says so and shows nothing else — a quietly incomplete keymap
list is worse than no list.

### What the dotfiles still need

The writer does not live here. It wants a Home Manager **activation script**
running the real profile `nvim` headless once per rebuild:

```
NVIM_KEYMAP_OUT=… nvim --headless --cmd "luafile $driver"
```

writing `{generated, config, count, maps[]}` to
`$XDG_CACHE_HOME/erikshell/nvim-keymaps.json`, with a `systemd.user.path`
watching it. Whitelist the fields before `vim.json.encode` — `callback` is a
function and will not serialise.

**Not** a hermetic derivation: 47 of his 48 plugins are store paths, but
`harpoon` is a lazy.nvim git clone in `~/.local/share/nvim/lazy/`, so an
offline build either fails or silently undercounts. It happens to cost nothing
today only because every harpoon keymap is commented out.

The one thing no dump can do is filetype-local maps — the 11 LSP bindings, and
the markdown and tex sets — because they do not exist until a buffer of that
type is open. The page says so rather than implying completeness.

## Unrelated bug found while doing this

`voxtype_suppress` is declared as an empty submap in
`modules/home-manager/hyprland/default.nix:161`, and Hyprland does not register
empty submaps — `hyprctl dispatch submap voxtype_suppress` answers *"submap
doesn't exist (wasn't registered!)"*. The keystroke guard is therefore inert,
so synthetic keystrokes during dictation can still trigger window binds. This
is the dictation-crashes-the-desktop problem.
