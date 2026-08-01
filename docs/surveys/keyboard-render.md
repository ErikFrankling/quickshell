# Drawing a Dactyl Manuform: who renders splay, and from what data

2026-08-02. The keys overlay drew the board from `keyboard.json` and it read as
a flat grid. This is the survey of why, what everyone else does, and what the
board is actually shaped like.

The short version: **the rotation was never missing, it was in a different
file.** `keyboard.json` has no `r`, but `vial.json` — the KLE payload Vial
itself renders, and the one whose bytes are in the flashed firmware — carries
two ±15° thumb clusters. Switching the renderer's input fixed the picture.

## The board's real geometry

Deserialising `keymaps/vial/vial.json`'s `layouts.keymap` as KLE, and joining
to `keyboard.json` by matrix address:

| measure | value |
|---|---|
| keys | 64 (KLE) = 64 (`keyboard.json`), all 64 matrix labels resolve |
| rotation clusters | 2 |
| left thumb | `r: 15`, `rx: 5.25`, `ry: 4` — keys `4,4 4,5 5,4 5,5 5,2 5,3` |
| right thumb | `r: -15`, `rx: 12.75`, `ry: 4` (inherited) — `11,0 11,1 10,0 10,1 11,2 11,3` |
| bounds, rotated corners | 18.000 × 6.998 u |
| at the 46 px pitch the overlay uses | 828 × 322 px |
| min centre-to-centre | 1.0000 u |
| overlapping caps, as drawn | **0** |
| overlapping caps, rotation ignored | **2** — `5,5`/`11,0` and `5,3`/`11,2` |

That last row is the whole argument. The two thumb clusters are 0.75 u into
each other in raw KLE coordinates; only the rotation pulls them apart. A flat
drawing of this board is not a simplification of it, it is a **geometrically
invalid** drawing of it, and `keyboard.json` avoids the collision by hand-
translating the twelve thumb keys instead (−1.25/+0.25 u on the left,
+1.00/+0.25 u on the right). 52 of the 64 positions agree between the two
files; the 12 that disagree are exactly the 12 that are rotated.

`keyboard.json` did not lose the rotation, it never had it: it descends from
`ErikFrankling/keyboard-layout-v2.json`, a manually de-rotated fork made to
feed kbfirmware.com. `vial.json`'s keymap is byte-identical to
`ErikFrankling/keyboard-layout-cords.json`, which kept it. The board does not
exist in `qmk/qmk_firmware` or `vial-kb/vial-qmk` at all — it is his own — so
there is no upstream copy to recover anything from, and none is needed.

## Who renders rotation, and from what

| tool | pitch | body | radius | cap inset L/R | cap inset T/B | rotation |
|---|---|---|---|---|---|---|
| KLE (reference) | 54 px | 54 (gap 0) | 5 | 6 / 6 | 3 / 9 | yes |
| VIA | 54×56 | 52×54 | 3 | 6 / 6 | 2 / 10 | yes |
| Vial GUI | font·3.4 | 0.941 u | 0.08 u | 0.1 u | 0.05 / 0.15 u | yes |
| keymap-drawer | 56 | 52 | 6 | — | — | yes |
| kbplacer | 52 | 52 | 5 | 6 / 6 | 4 / 8 | yes |
| QMK Configurator | 45 | 40 (gap 5) | 6 | — (box-shadow) | — | **no** |
| `qmk info --ascii` | char grid | — | — | — | — | **no**, overwrites |

Three constants everyone converged on independently: a **0.111 u side inset**
on the cap top, a **~0.10 u corner radius**, and an **asymmetric vertical inset
biased upward, roughly 1:3 top to bottom**. Nobody centres the cap in the key.
That last one is the entire 3D effect and costs one rectangle.

The cascade is `cell 1.0 u → body ~0.93 u → cap ~0.78 u → text box ~0.67 u`.

**Nobody draws a Dactyl with splay** — not because renderers cannot, but
because the data cannot. QMK's `keyboard.jsonschema` does define `r`/`rx`/`ry`,
and `docs/reference_info_json.md` says of all three *"Currently not
implemented."* Across ~2000 QMK boards only 15 files use `r` and 4 use `rx`;
exactly one is a Dactyl (`5x7_2_6`), and it sets `r` with no `rx`/`ry`, which
under KLE semantics rotates about the board origin. In his local `vial-qmk`
checkout the split is stark: **85 `vial.json` files carry rotation against 4
`keyboard.json`/`info.json` files.** Rotation lives in Vial definitions and
essentially nowhere else.

## The KLE deserialiser, and the bug not to copy

`ijprest/kle-serial` master is **wrong** and should not be the reference:
it omits the `current.x = rotation_x` reset at end of row, so rotated clusters
land one row low (its issue #7, PR #1 unmerged). KLE's own `serial.js` and
Vial's `kle_serial.py` are line-for-line correct. The rules that matter:

- `x`/`y` are **deltas**; `w`/`h` are absolute and last one key only.
- `rx` or `ry` — **either one** — snaps the cursor to the persistent cluster
  origin, so the right thumb inherits `ry: 4` from the left without restating it.
- End of row is `y += 1; x = rx`, **not** `x = 0`. KLE's own wiki says `x = 0`
  and is wrong.
- `r`/`rx`/`ry` are sticky across rows, which is how a two-row cluster works.
- Transform is `T(o)·R(r)·T(−o)` about `(rx, ry)`, degrees, clockwise on screen.

QML's `Rotation { origin.x; origin.y; angle }` is that transform exactly, so
porting it costs nothing.

## Why not the other two routes

**keymap-drawer** does preserve rotation — `PhysicalKey(pos, width, height,
rotation)`, emitted as `transform="translate(…) rotate(…)"` — and it is in
nixpkgs at 0.23.0. But it reads rotation from QMK `info.json`, which for this
board has none, so it would draw the same flat grid unless fed the KLE first.
And QtSvg would still need help: it ignores `dominant-baseline` (legends ride
high), `paint-order` (layer headers are destroyed — the 4 px stroke paints over
the fill), `tspan` `x`/`dy` (multi-line legends collapse onto one line),
`font-size` in `%` (`64%` becomes 64 px), root-element selectors, and `@media`
(so `dark_mode: auto` always renders light). A working post-processor was
prototyped at ~65 lines, not the ~30 `docs/keyboard.md` guessed, and it still
cannot do the icon glyphs or `clip-path`. The `dy` trick does not work either —
the offset has to be baked into `y`.

**A build-time raster** was on the table and is genuinely viable —
`librsvg`, `resvg` and `inkscape` are all packaged. It was not taken because it
buys nothing the QML render does not already have, and costs the thing the
current version gets free: `FileView { watchChanges: true }` means a re-flash
shows up in the overlay the moment the file changes, with no rebuild.

## What shipped

`Keymap.qml` reads three files — `vial.json` for shape, `keyboard.json` for
matrix addresses, `keymap.c` for keycodes — and joins them on the matrix
address, since KLE labels every key `"row,col"` and `keyboard.json`'s nth entry
is the nth `LAYOUT()` argument. `KeyBoard.qml` draws Vial's two-rectangle cap
and puts each key through its own `Rotation`. No `qmk`, no `keymap-drawer`, no
derivation, no build step.

`keyboard-render.png` is the result; `keyboard-render-fn.png` is the Fn layer,
where the transparent keys drawn as ghost outlines make the splay easiest to
read.
