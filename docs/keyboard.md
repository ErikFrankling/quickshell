# A keyboard shortcut cheatsheet: what is possible

Erik asked whether three things could be read and rendered as one cheatsheet —
his Dactyl Manuform's QMK/Vial layers, his Hyprland binds, and his Neovim
keymaps. This is the answer to that question. Nothing here is built yet; it was
research for discussion, and the write-up previously existed only inside agent
transcripts, which do not survive.

All three are possible. The difficulty is not where you would guess.

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
