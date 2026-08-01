# A keyboard shortcut cheatsheet: what is possible

Erik asked whether three things could be read and rendered as one cheatsheet —
his Dactyl Manuform's QMK/Vial layers, his Hyprland binds, and his Neovim
keymaps. This is the answer to that question, and — since 2026-08-01 — the
record of the two thirds of it that shipped.

All three are possible. The difficulty is not where you would guess.

## What shipped

`KeysWindow.qml` — a centred overlay in the launcher's shape, Escape to
dismiss, on `qs ipc call keys toggle` and a `GlobalShortcut`, no rail button.
It shows the Dactyl's two layers on a drawn board, and all of Hyprland's binds
under it, grouped by modifier. `Keymap.qml` is the data behind both;
`KeyBoard.qml` draws the board. Three files, none over 250 lines.

Neovim is deliberately not in it. Being right about his keymaps means RPC into
a live instance — every offline number below is wrong — and a keymap list that
is quietly wrong is worse than none. Adding it is the third section of this
document plus a `Process` running `nvim --server $SOCK --remote-expr`, a
`$NVIM_LISTEN_ADDRESS` to find, and a decision about what the sheet shows when
no instance is running. Perhaps sixty lines and a real design question, against
the roughly two hundred the other two cost together.

Measured on the running shell the day it shipped: 61 binds in four modifier
groups (Super 32, Super+Shift 16, no modifier 9, Super+Alt 4), 64 keys, 2
layers. Card 860×840 on a 1862×1080 output; board 792×275 at a 44px key pitch.

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

The keymap is at
`~/projects/3d/vial-qmk/keyboards/handwired/dactyl_manuform/5x6_64/keymaps/vial/`:
two layers, 64 keys, no macros or tap-dances. The repo matches what is actually
flashed — the LZMA blob inside the hex matches `vial.json` byte for byte — so
reading the repo is reading the keyboard.

`qmk c2json --no-cpp` converts it offline in 256 ms, and `pkgs.keymap-drawer`
0.23.0 renders it correctly including the split thumb clusters. A 6.8 MB stub
QMK tree is enough for a hermetic derivation; the 2 GB `vial-qmk` repo does
**not** need to be a flake input.

The one real obstacle is rendering. QtSvg ignores `dominant-baseline` and
`paint-order`, so keymap-drawer's SVG comes out with the legends sitting too
high. Three ways out: rasterise it, post-process about thirty lines of SVG, or
skip the SVG and draw the keys natively in QML from a 6.7 KB joined JSON. The
last is probably right for a shell that already draws everything else itself.

**It was the third, and it did not even need the joined JSON.** `keyboard.json`
in the keyboard directory already gives every key an `x` and a `y` in key units
— including the splay and both thumb clusters — and the `LAYOUT()` macro is
*generated from that array*, so the nth argument in `keymap.c` is the nth
position in `keyboard.json` and no matrix arithmetic is involved. `KeyBoard.qml`
is a `Repeater` over 64 positions; `Keymap.qml` reads the two files with
`FileView` and `watchChanges: true`, splits the `LAYOUT(...)` arguments on
depth-zero commas after stripping comments, and maps the 46 keycodes whose name
is not already their legend. So there is no `qmk`, no `keymap-drawer`, no
derivation and no build step, and re-flashing shows up in the overlay the moment
the file changes.

Two things that will bite the next person: `MO(1)` and `UP(AA_LOWER, AA_UPPER)`
contain commas, so the argument split has to track parenthesis depth; and
`keymap.c` keeps a whole commented-out old keymap below the live one, so block
and line comments have to go first or you parse four layers instead of two.

Reading the layout live over HID with Vial's protocol also works — about sixty
lines of stdlib Python, and the existing `/etc/udev/rules.d/50-qmk.rules`
already grants access. Only worth it if he starts editing in the Vial GUI,
which is what would make `keymap.c` go stale.

## Hyprland binds — yes, with one trap

`hyprctl binds` returns all sixty in 0.8 ms, and `configreloaded` on socket2 is
the refresh signal, so nothing has to poll.

The trap is descriptions. None of the sixty binds have one today, and under a
Lua config a bind reports `dispatcher: __lua` and an opaque integer — only the
modifier mask, the key and the description survive. **Converting `bind` to
`bindd` has to happen before the Lua migration, or the data the cheatsheet
needs no longer exists.** That is roughly sixty lines in
`modules/home-manager/hyprland/default.nix`.

## Neovim — the fiddly one

His config is nixCats plus lazy.nvim, which makes a build-time dump silently
wrong. A bare headless run sees 106 normal-mode maps; a live instance sees
118–120; `Lazy! load all` over-reports at 132. None of those numbers is the
answer.

The working path is RPC to a live instance, which returns valid JSON with 215
described entries. which-key is present but has no dump API and contributes
only group labels on top of `nvim_get_keymap` — read
`require("which-key.config").mappings` filtered to `m.group == true` for the
seven group names and nothing else. Whitelist the fields when encoding: raw
non-UTF-8 bytes in `lhsraw` will break `JSON.parse`.

## Unrelated bug found while doing this

`voxtype_suppress` is declared as an empty submap in
`modules/home-manager/hyprland/default.nix:161`, and Hyprland does not register
empty submaps — `hyprctl dispatch submap voxtype_suppress` answers *"submap
doesn't exist (wasn't registered!)"*. The keystroke guard is therefore inert,
so synthetic keystrokes during dictation can still trigger window binds. This
is the dictation-crashes-the-desktop problem.
