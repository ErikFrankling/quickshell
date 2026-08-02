#!/usr/bin/env python3
# The Dactyl's shape and its keycodes, read from the board itself over Vial's
# raw-HID protocol — or, with --config, out of the QMK tree the firmware was
# built from. Both modes print the same JSON, so the shell has one parser and
# two sources:
#
#   {"source": "keyboard"|"config", "name": str, "layers": int,
#    "keymap": [...KLE rows...], "codes": {"row,col": [code per layer]}}
#
# The protocol is what vial-gui does and nothing more — keyboard_comm.py's
# reload_layout() and reload_keymap(). docs/surveys/vial-hid.md has the whole
# of it, with sources.

import glob
import json
import lzma
import os
import re
import select
import struct
import sys

# QMK's raw-HID interface announces itself as usage page 0xFF60, usage 0x61
# (tmk_core/protocol/usb_descriptor_common.h). Match that pair exactly and not
# "some vendor page" — a Logitech keyboard, an Asus LED controller and a DAC
# all have one and none of them is this. The report descriptor is a
# world-readable file in sysfs, so no ioctl and no hidapi. Its stat size is a
# lie (one page); what read() returns is the descriptor.
def usage(desc):
    i, page = 0, None
    while i < len(desc):
        head = desc[i]
        if head == 0xFE:  # long item, which nothing in the wild emits
            i += 3 + desc[i + 1]
            continue
        n = head & 3
        n = 4 if n == 3 else n
        val = int.from_bytes(desc[i + 1:i + 1 + n], "little")
        if head & 0xFC == 0x04:  # global tag 0 — usage page
            page = val
        elif head & 0xFC == 0x08:  # local tag 0 — usage
            return (val >> 16, val & 0xFFFF) if n == 4 else (page, val)
        i += 1 + n
    return (None, None)


def find():
    for node in sorted(glob.glob("/sys/class/hidraw/hidraw*")):
        try:
            with open(node + "/device/report_descriptor", "rb") as f:
                if usage(f.read()) == (0xFF60, 0x61):
                    return "/dev/" + os.path.basename(node)
        except OSError:
            pass
    return None


class Board:
    # hidraw takes the first byte of a write as a report number and QMK uses
    # none, so a 32-byte report goes out as 33 bytes behind a leading zero.
    # Leave the zero off and the kernel eats the first real byte, puts 31 on
    # the wire, and still returns 32 from write() — usbhid/hid-core.c adds the
    # stripped byte back to the count. The board then answers nothing, which is
    # the least debuggable failure available.
    def __init__(self, path):
        self.fd = os.open(path, os.O_RDWR | os.O_NONBLOCK)

    def ask(self, req):
        while select.select([self.fd], [], [], 0)[0]:
            os.read(self.fd, 64)  # anything already queued is not our answer
        os.write(self.fd, b"\x00" + req.ljust(32, b"\x00"))
        if not select.select([self.fd], [], [], 1.0)[0]:
            raise OSError("the keyboard did not answer")
        # Unplugged mid-read, select reports readable and this raises EIO.
        return os.read(self.fd, 64)[:32]


def read_board(path):
    board = Board(path)
    size = struct.unpack("<I", board.ask(b"\xfe\x01")[:4])[0]
    blob, block = b"", 0
    while len(blob) < size:
        blob += board.ask(struct.pack("<BBI", 0xFE, 0x02, block))
        block += 1
    definition = json.loads(lzma.decompress(blob[:size]))

    layers = board.ask(b"\x11")[1]
    rows = definition["matrix"]["rows"]
    cols = definition["matrix"]["cols"]
    want = layers * rows * cols * 2
    buf = b""
    while len(buf) < want:
        n = min(28, want - len(buf))
        buf += board.ask(struct.pack(">BHB", 0x12, len(buf), n))[4:4 + n]

    codes = {}
    for row in range(rows):
        for col in range(cols):
            codes["%d,%d" % (row, col)] = [
                name(struct.unpack(">H", buf[(at * rows * cols + row * cols + col) * 2:][:2])[0])
                for at in range(layers)
            ]
    return {
        "source": "keyboard",
        "name": definition.get("name", ""),
        "layers": layers,
        "keymap": definition["layouts"]["keymap"],
        "codes": codes,
    }


# --- keycode numbers back into keycode names ---

# The board reports numbers; keymap.c is written in names; the shell's legend
# table is keyed by name. Values are vial-qmk's own `quantum/keycodes.h` on the
# `vial` branch, and the short aliases are chosen deliberately — KC_ENT and not
# KC_ENTER — because those are what a hand-written keymap.c uses, and the two
# sources have to agree on one spelling or the legends only work on one of them.
BASIC = {0x00: "KC_NO", 0x01: "KC_TRNS"}


def fill(base, names):
    for i, n in enumerate(names):
        BASIC[base + i] = "KC_" + n


fill(0x04, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
fill(0x1E, "1234567890")
fill(0x28, "ENT ESC BSPC TAB SPC MINS EQL LBRC RBRC BSLS NUHS SCLN QUOT GRV COMM DOT SLSH CAPS".split())
fill(0x3A, ["F%d" % i for i in range(1, 13)])
fill(0x46, "PSCR SCRL PAUS INS HOME PGUP DEL END PGDN RGHT LEFT DOWN UP NUM PSLS PAST PMNS PPLS PENT".split())
fill(0x59, "P1 P2 P3 P4 P5 P6 P7 P8 P9 P0 PDOT NUBS APP".split())
fill(0x68, ["F%d" % i for i in range(13, 25)])
fill(0xA5, "PWR SLEP WAKE MUTE VOLU VOLD MNXT MPRV MSTP MPLY MSEL EJCT MAIL CALC MYCM WSCH WHOM"
           " WBAK WFWD WSTP WREF WFAV MFFD MRWD BRIU BRID CPNL".split())
fill(0xE0, "LCTL LSFT LALT LGUI RCTL RSFT RALT RGUI".split())

# The five-bit mod mask is one nibble plus a flag: bit 4 makes the whole set
# right-handed, which is why a keycode can never mix a left and a right mod.
def mods(mask):
    side = "R" if mask & 0x10 else "L"
    return "+".join(side + n for i, n in enumerate(("CTL", "SFT", "ALT", "GUI")) if mask & (1 << i)) or "0"


LAYER = {0x5200: "TO", 0x5220: "MO", 0x5240: "DF", 0x5260: "TG", 0x5280: "OSL", 0x52C0: "TT"}


def name(kc):
    if kc <= 0xFF:
        return BASIC.get(kc, "0x%04X" % kc)
    if kc < 0x2000:
        return "%s(%s)" % (mods((kc >> 8) & 0x1F), name(kc & 0xFF))
    if kc < 0x4000:
        return "MT(%s, %s)" % (mods((kc >> 8) & 0x1F), name(kc & 0xFF))
    if kc < 0x5000:
        return "LT(%d, %s)" % ((kc >> 8) & 0xF, name(kc & 0xFF))
    if kc & 0xFFE0 in LAYER:
        return "%s(%d)" % (LAYER[kc & 0xFFE0], kc & 0x1F)
    if kc == 0x7C00:
        return "QK_BOOT"
    # 0x8000 and up is unicode, and which half is which cannot be told from the
    # keycode alone — it depends on how the firmware was built. This board uses
    # a unicode_map, so the pair form is the one that shows up.
    if 0x8000 <= kc < 0xC000:
        return "UM(%d)" % (kc & 0x3FFF)
    if kc >= 0xC000:
        return "UP(%d, %d)" % (kc & 0x7F, (kc >> 7) & 0x7F)
    return "0x%04X" % kc


# --- the same thing, from the QMK tree ---

# Each `LAYOUT(...)` lists its keycodes in exactly the order keyboard.json
# lists positions — that is what the generated macro is — so the nth argument
# is the nth matrix address. `MO(1)` and `UP(AA_LOWER, AA_UPPER)` contain
# commas, so the split has to count parentheses.
def layouts(src):
    out, at = [], 0
    while True:
        start = src.find("LAYOUT(", at)
        if start < 0:
            return out
        depth, tok, cur, i = 1, "", [], start + 7
        while i < len(src):
            c = src[i]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    break
            if depth == 1 and c == ",":
                cur.append(tok.strip())
                tok = ""
            else:
                tok += c
            i += 1
        cur.append(tok.strip())
        out.append(cur)
        at = i + 1


# A `UP()` keycode names two entries of the board's own `unicode_map` enum, and
# the board can only ever report their indices. So the source side is rewritten
# to indices as well, and the two modes speak one vocabulary.
def indices(src):
    found = re.search(r"enum\s+unicode_names\s*\{(.*?)\}", src, re.S)
    if not found:
        return {}
    return {n.strip(): i for i, n in enumerate(found.group(1).split(",")) if n.strip()}


def unify(code, by_name):
    pair = re.match(r"UP\(\s*(\w+)\s*,\s*(\w+)\s*\)$", code)
    if not pair or pair.group(1) not in by_name or pair.group(2) not in by_name:
        return code
    return "UP(%d, %d)" % (by_name[pair.group(1)], by_name[pair.group(2)])


def read_config(board):
    with open(board + "/keymaps/vial/vial.json") as f:
        vial = json.load(f)
    with open(board + "/keyboard.json") as f:
        order = [k["matrix"] for k in json.load(f)["layouts"]["LAYOUT"]["layout"]]
    with open(board + "/keymaps/vial/keymap.c") as f:
        src = f.read()
    # keymap.c keeps a whole commented-out old keymap below the live one, so
    # the comments go first or you get four layers instead of two.
    src = re.sub(r"//[^\n]*", " ", re.sub(r"/\*.*?\*/", " ", src, flags=re.S))

    by_name = indices(src)
    layers = [[unify(a, by_name) for a in one] for one in layouts(src)]
    codes = {}
    for i, m in enumerate(order):
        codes["%d,%d" % (m[0], m[1])] = [l[i] if i < len(l) else "KC_NO" for l in layers]
    return {
        "source": "config",
        "name": vial.get("name", ""),
        "layers": len(layers),
        "keymap": vial["layouts"]["keymap"],
        "codes": codes,
    }


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--config":
        out = read_config(sys.argv[2].rstrip("/"))
    else:
        node = find()
        if node is None:
            sys.exit("no keyboard found")
        out = read_board(node)
    json.dump(out, sys.stdout)
