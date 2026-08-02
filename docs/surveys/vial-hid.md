# Reading the Dactyl over HID, the way Vial does

Written 2026-08-02, because the keys sheet said **"0 keys · 0 layers"** on the
Framework while Vial Web, in a browser on the same machine, drew the board
perfectly. Nothing was wrong with the keyboard. `Keymap.qml` had

```qml
readonly property string board: "/home/erikf/projects/3d/vial-qmk/keyboards/handwired/dactyl_manuform/5x6_64"
```

hard-coded, and that checkout is on the PC. Three `FileView`s found nothing,
`placed` and `layers` stayed empty, and the page rendered an empty card.

Fixing the path would have been the wrong fix. The board was plugged in. The
board knows its own layout. Ask it.

## Vial's protocol, from Vial's source

All quotes fetched over HTTP from `vial-kb/vial-gui@main` and
`vial-kb/vial-qmk@vial`; nothing was cloned. The command bytes are
`src/main/python/protocol/constants.py`:

```python
CMD_VIA_GET_LAYER_COUNT      = 0x11
CMD_VIA_KEYMAP_GET_BUFFER    = 0x12
CMD_VIA_VIAL_PREFIX          = 0xFE
CMD_VIAL_GET_KEYBOARD_ID     = 0x00
CMD_VIAL_GET_SIZE            = 0x01
CMD_VIAL_GET_DEFINITION      = 0x02
BUFFER_FETCH_CHUNK = 28
```

The firmware agrees, `quantum/vial.c`:

```c
void vial_handle_cmd(uint8_t *msg, uint8_t length) {
    /* All packets must be fixed 32 bytes */
    if (length != VIAL_RAW_EPSIZE)
        return;
    /* msg[0] is 0xFE -- prefix vial magic */
    switch (msg[1]) {
```

So a Vial command is `FE <sub> <args…>`, a VIA command is `<cmd> <args…>`, and
everything is padded to exactly 32 bytes in both directions.

**The layout is an LZMA-compressed JSON blob**, delivered in 32-byte chunks.
`protocol/keyboard_comm.py`, `reload_layout()`:

```python
data = self.usb_send(self.dev, struct.pack("BB", CMD_VIA_VIAL_PREFIX, CMD_VIAL_GET_SIZE), retries=20)
sz = struct.unpack("<I", data[0:4])[0]

payload = b""
block = 0
while sz > 0:
    data = self.usb_send(self.dev, struct.pack("<BBI", CMD_VIA_VIAL_PREFIX, CMD_VIAL_GET_DEFINITION, block),
                         retries=20)
    if sz < MSG_LEN:
        data = data[:sz]
    payload += data
    block += 1
    sz -= MSG_LEN

payload = json.loads(lzma.decompress(payload))
```

Note `lzma.decompress` with no format argument. The producer,
`vial-qmk/util/vial_generate_definition.py`, calls `lzma.compress` with no
arguments either — Python's default `FORMAT_XZ`, preset 6 — so auto-detection
is correct and raw filters are not needed. The KLE layout is at
`definition["layouts"]["keymap"]`, and `definition["matrix"]` gives the rows
and cols needed to size the next request.

The keycodes are VIA's, not Vial's. `reload_keymap()`:

```python
size = self.layers * self.rows * self.cols * 2
for x in range(0, size, BUFFER_FETCH_CHUNK):
    data = self.usb_send(self.dev, struct.pack(">BHB", CMD_VIA_KEYMAP_GET_BUFFER, offset, sz), retries=20)
    keymap += data[4:4+sz]
...
offset = layer * self.rows * self.cols * 2 + row * self.cols * 2 + col * 2
keycode = Keycode.serialize(struct.unpack(">H", keymap[offset:offset+2])[0])
```

One flat layer-major buffer of big-endian `uint16`, 28 bytes at a time, and the
response echoes the four request bytes before the payload. The layer count is
`0x11`, at **response byte 1** — not byte 0.

## Finding the right hidraw node

Vial matches usage page `0xFF60` and usage `0x61` (`util.py`'s `is_rawhid`),
which is QMK's raw-HID interface, `tmk_core/protocol/usb_descriptor_common.h`:

```c
#ifndef RAW_USAGE_PAGE
#    define RAW_USAGE_PAGE 0xFF60
#endif
#ifndef RAW_USAGE_ID
#    define RAW_USAGE_ID 0x61
#endif
```

**No ioctl is needed.** `/sys/class/hidraw/hidrawN/device/report_descriptor` is
mode 0444 and world-readable, and byte-for-byte identical to what
`HIDIOCGRDESC` returns — both come from `hdev->rdesc`. One trap: its `stat`
size is 4096, the sysfs page size, and lies; what `read()` returns is the
descriptor. Parsing it takes about twenty lines — short items are a prefix byte
with the size in bits 0–1 (where 3 means four bytes), the type in 2–3 and the
tag in 4–7, data little-endian.

Matching the exact pair matters. This machine has four other vendor-defined
usage pages on it — a FiiO DAC's `0xFF00`, an Asus LED controller's `0xFF72`,
and a Logitech keyboard and mouse on `0xFF43` — every one of which a "vendor
page" heuristic would claim as a keyboard. Matching `0xFF60`/`0x61` rejects all
eight nodes here, correctly, because there is no QMK board on this machine.

## The write framing, which is the one silent failure

`Documentation/hid/hidraw.rst`:

> The first byte of the buffer passed to write() should be set to the report
> number. If the device does not use numbered reports, the first byte should be
> set to 0.

QMK does not use numbered reports, so **a 32-byte report is a 33-byte write**
behind a leading zero. Leave the zero off and `usbhid_output_report` treats the
first real byte as the report ID, strips it, puts 31 bytes on the wire — and
then adds the stripped byte back to the return value:

```c
	if (buf[0] == 0x0) {
		/* Don't send the Report ID */
		buf++;
		count--;
		skipped_report_id = 1;
	}
	...
		if (skipped_report_id)
			ret++;
```

Demonstrated live on this machine: `os.write(fd, bytes(32))` returns 32 while
sending 31. QMK requires exactly `RAW_EPSIZE`, so the board answers nothing and
`write()` reports success. Read into a buffer larger than 32, too — `hidraw_read`
truncates to `count` and discards the remainder of the queued report.

Unplugged, the errnos are asymmetric and both need catching: `open` gives
`ENODEV`, `read` gives **`EIO`** (`hidraw.c`: `if (!list->hidraw->exist) { ret =
-EIO; }`), `write` gives `ENODEV`. `poll` on a dead device sets `EPOLLERR |
EPOLLHUP`, which `select` reports in the *read* set — so readable is not proof
of data, and the `os.read` after it raises.

## Keycode numbers back into keycode names

The board reports `0x5221`; `keymap.c` says `MO(1)`; the legend table is keyed
by name. `vial.py` carries a 147-entry table plus the quantum ranges, and every
entry was checked against the header of the firmware that is actually flashed —
`vial-qmk@vial`'s `quantum/keycodes.h`, whose local blob hash matches the branch
head. Zero mismatches. The ranges that matter:

| range | meaning |
| --- | --- |
| `0x0000–0x00FF` | basic |
| `0x0100–0x1FFF` | `LCTL(kc)` — five mod bits at 8–12, bit 12 makes the set right-handed |
| `0x2000–0x3FFF` | `MT(mod, kc)` |
| `0x4000–0x4FFF` | `LT(layer, kc)` — four layer bits |
| `0x5200`+`0x20` each | `TO`, `MO`, `DF`, `TG`, `OSL`, `OSM`, `TT` — five layer bits |
| `0x7C00` | `QK_BOOT` |
| `0x8000–0xBFFF` | `UM(i)` |
| `0xC000–0xFFFF` | `UP(i, j)` — `i` in bits 0–6, `j` in bits 7–13 |

The short aliases are deliberate — `KC_ENT`, not `KC_ENTER` — because those are
what a hand-written `keymap.c` uses, and the two sources have to agree on one
spelling or the legends only work on one of them.

**`UP()` is the one place the two sources genuinely cannot agree.** A unicode
pair keycode names two entries of the board's own `unicode_map` enum, and over
HID the board can only ever report their indices. So the source side is
rewritten to indices as well: `UP(AA_LOWER, AA_UPPER)` becomes `UP(4, 5)`, and
`Keymap.qml`'s legend table is keyed by the index form. `å ö ä` render on the Fn
layer from either source.

Two caveats that cannot be resolved and are not worth pretending about.
`QK_UNICODE` and `QK_UNICODEMAP` are both `0x8000`, and which one a keycode
means depends on how the firmware was built, not on the keycode — this board
uses a `unicode_map`, so the pair form is assumed. And `KC_BRMU` is an alias of
`KC_PAUSE` (`0x48`), not of `KC_BRIGHTNESS_UP` (`0xBD`); if the two sources ever
disagree on a brightness key, that is why.

## What was tested, and what could not be

The board is on the laptop. This machine has no QMK device at all — the full
USB tree is a Logitech G502 and G512, a FiiO K11, an Asus AURA controller, two
CH340 serials and four hubs, and all eight hidraw nodes parse to something
other than `0xFF60`/`0x61`.

So `docs/surveys/vial-hid-test.py` stands a Dactyl up that is not there: a
`SOCK_SEQPACKET` socketpair, which preserves message boundaries the way an
interrupt endpoint does, with a thread on the far end speaking the protocol out
of the real `vial.json` and the real `keymap.c`. It asserts the 33-byte framing
and the leading zero, walks the LZMA chunks and the 28-byte buffer, and then
checks that reading "the board" gives byte-for-byte what reading the QMK tree
gives:

```
definition: 404 bytes of LZMA in 2 layers
keys placed: 13 KLE rows, 64 labelled positions
keyboard and config agree on all 64 positions, 2 layers, and the KLE
usage matcher: QMK raw HID -> (65376, 97)  a mouse -> (1, 2)
```

Rendered in the running shell, all three states: **"64 keys · 2 layers · from
the config"** off the committed baseline, **"from the keyboard"** with the fake
board wired to the helper's stdout, and **"no keyboard found"** with neither.
Board 828×322 at a 46 px pitch in an 880-wide card, unchanged.

What is untested is the only thing that needs the hardware: whether a real
Dactyl on a real USB bus answers these reports. The framing, the descriptor
parse, the permissions and the errnos are all verified against this machine's
kernel; the exchange itself is verified against a simulation of the firmware,
not the firmware.

## Permissions

`/etc/udev/rules.d/50-qmk.rules:71`, from `pkgs.qmk-udev-rules`:

```
KERNEL=="hidraw*", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"
```

Unconditional on every hidraw node, which is why all eight here carry an ACL:

```
$ getfacl /dev/hidraw0
user::rw-
user:erikf:rw-
```

`erikf` is **not** in `plugdev` — that group is empty. Access comes entirely
from `uaccess`, which is seat-bound: it grants the ACL to whoever owns the
active session on the device's seat, at device-add time. In a graphical session
that is always him. Over SSH with no seat, or if the board is plugged in while
the session is inactive, there is no ACL and `open` gives `EACCES`. Adding
`erikf` to `plugdev` would make it seat-independent; nothing today needs that.

`modules/nixos/qmk.nix` is imported through `modules/nixos/default.nix` by
**both** `hosts/pc/configuration.nix:15` and `hosts/framework/configuration.nix:15`,
so the rule is already on the laptop. No dotfiles change is needed for
permissions.

## Why not the other options

**A packaged tool.** `qmk_hid` is in nixpkgs and already commented out in
`modules/nixos/qmk.nix`, but it speaks VIA's keycode commands and cannot fetch
the Vial definition blob, so it answers half the question. There is no
`vial-cli`; vial-gui is a PyQt application, ~40 MB of closure, and its protocol
layer is not importable on its own.

**A compiled helper.** Anything needing a compiler needs a derivation, and a
derivation is a build step. `nix run .` from the working tree is the whole
development loop here and it does not build anything.

**Python.** `lzma`, `json`, `struct`, `select` and `glob` are all standard
library; the helper needs no hidapi and no pyusb, which is what makes it 240
lines and no packaging. `pkgs.python3` joins `runtimeDeps` in `flake.nix` — it
was not on the PATH before, so **the shell has to be rebuilt once** before the
live read can work. Until then the helper fails to start, which is the same
code path as an unplugged board, and the baseline draws.

## Why a committed baseline and not a cache

The board is the only source that cannot be stale, but it is only there when it
is plugged in — and a laptop that has never had it plugged in still has to draw
something. Three ways to have an offline answer:

- **Vendor `vial.json` + `keyboard.json` + `keymap.c`.** 13 KB, three parsers
  in QML, and the join between them re-done on every shell start.
- **A flake input on his vial-qmk fork.** `keyboard.json` names
  `git@github.com:ErikFrankling/dactyl-manuform-keyboard.git`, a different repo
  from the checkout; a build on a machine that cannot reach it fails, and a
  network fetch to draw a keyboard is absurd.
- **Commit the joined result.** `vial.py --config <board>` emits exactly the
  same JSON the HID path emits, and `dactyl.json` is that, 3 KB, committed.

The third one won, and it is smaller than it looks: because both sources emit
one shape, `Keymap.qml` lost the `keyboard.json` reader, the `keymap.c` parser
and the `LAYOUT()` argument split entirely. There is no derivation and no build
step — the honest answer to "generate it at build time" is that the generation
already happened, once, and its output is a committed file.

No cache of the last live read. The baseline is already the offline answer, and
a cache would only add the question of which keyboard it came from. Regenerate
`dactyl.json` when the QMK tree changes:

```
python3 vial.py --config ~/projects/3d/vial-qmk/keyboards/handwired/dactyl_manuform/5x6_64 > dactyl.json
```

and if it is ever forgotten, the board itself is still right.
