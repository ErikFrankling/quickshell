#!/usr/bin/env python3
# A Dactyl Manuform that is not there.
#
# The board lives on the laptop, so the HID half of `vial.py` was written on a
# machine that has never seen it. This stands a fake one up on a SOCK_SEQPACKET
# socketpair — which preserves message boundaries the way an interrupt endpoint
# does — speaking the same protocol vial-gui speaks, built out of the real
# vial.json and the real keymap.c. It exercises the 33-byte write framing, the
# LZMA chunking, the layer count, the 28-byte keymap-buffer walk and the
# keycode decode, and then asserts that reading the board gives byte-for-byte
# what reading the QMK tree gives.
#
# Run:  python3 docs/surveys/vial-hid-test.py

import importlib.util
import json
import lzma
import os
import socket
import struct
import sys
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
# The QMK tree, which is on the PC. Pass another as argv[1] from anywhere else.
BOARD = (sys.argv[1] if len(sys.argv) > 1 else
         "/home/erikf/projects/3d/vial-qmk/keyboards/handwired/dactyl_manuform/5x6_64")

spec = importlib.util.spec_from_file_location("vial", os.path.join(HERE, "../../vial.py"))
vial = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vial)

# --- name back into number, only for the test ------------------------------

NUM = {n: k for k, n in vial.BASIC.items()}


def encode(code):
    if code in NUM:
        return NUM[code]
    if code == "QK_BOOT":
        return 0x7C00
    if code.startswith("MO("):
        return 0x5220 | int(code[3:-1])
    if code.startswith("UP("):
        i, j = (int(x) for x in code[3:-1].split(","))
        return 0xC000 | (i & 0x7F) | ((j & 0x7F) << 7)
    raise SystemExit("test cannot encode " + code)


# --- the fake board ---------------------------------------------------------


def firmware(sock, definition, layers, rows, cols, codes):
    blob = lzma.compress(json.dumps(definition, separators=(",", ":")).encode())
    buf = bytearray(layers * rows * cols * 2)
    for at in range(layers):
        for row in range(rows):
            for col in range(cols):
                got = codes.get("%d,%d" % (row, col))
                kc = encode(got[at]) if got else 0
                struct.pack_into(">H", buf, (at * rows * cols + row * cols + col) * 2, kc)
    while True:
        msg = sock.recv(64)
        if not msg:
            return
        assert len(msg) == 33, "a report must be 33 bytes on the wire, got %d" % len(msg)
        assert msg[0] == 0, "the leading report id must be zero"
        msg = msg[1:]
        if msg[0] == 0xFE and msg[1] == 0x01:
            out = struct.pack("<I", len(blob))
        elif msg[0] == 0xFE and msg[1] == 0x02:
            page = struct.unpack("<I", msg[2:6])[0] * 32
            out = blob[page:page + 32]
        elif msg[0] == 0x11:
            out = bytes([0x11, layers])
        elif msg[0] == 0x12:
            off, size = struct.unpack(">HB", msg[1:4])
            out = msg[:4] + bytes(buf[off:off + size])
        else:
            out = b""
        sock.send(bytes(out).ljust(32, b"\x00"))


def main():
    want = vial.read_config(BOARD)
    definition = {
        "name": want["name"],
        "matrix": {"rows": 12, "cols": 6},
        "layouts": {"keymap": want["keymap"]},
    }
    ours, theirs = socket.socketpair(socket.AF_UNIX, socket.SOCK_SEQPACKET)
    threading.Thread(
        target=firmware,
        args=(theirs, definition, want["layers"], 12, 6, want["codes"]),
        daemon=True,
    ).start()

    # read_board opens the node itself, so the socket goes in through the
    # constructor rather than through a path.
    vial.Board.__init__ = lambda self, path: setattr(self, "fd", ours.fileno())
    got = vial.read_board("ignored")

    # The board only knows indices and the tree only knows names, so the two
    # agreeing on `UP(4, 5)` is the point of the rewrite in vial.py.
    live = {k: v for k, v in got["codes"].items() if k in want["codes"]}
    print("definition:", len(lzma.compress(json.dumps(definition, separators=(",", ":")).encode())),
          "bytes of LZMA in", got["layers"], "layers")
    print("keys placed:", len(want["keymap"]), "KLE rows,", len(want["codes"]), "labelled positions")
    bad = {k: (want["codes"][k], live[k]) for k in want["codes"] if want["codes"][k] != live[k]}
    if bad or got["name"] != want["name"] or got["keymap"] != want["keymap"]:
        for k, (a, b) in sorted(bad.items())[:10]:
            print("  MISMATCH", k, a, "!=", b)
        sys.exit("the two sources disagree")
    print("keyboard and config agree on all %d positions, %d layers, and the KLE"
          % (len(want["codes"]), got["layers"]))

    # And the descriptor matcher, against the bytes QMK actually emits.
    qmk = bytes([0x06, 0x60, 0xFF, 0x09, 0x61, 0xA1, 0x01, 0x75, 0x08, 0xC0])
    mouse = bytes([0x05, 0x01, 0x09, 0x02, 0xA1, 0x01, 0xC0])
    assert vial.usage(qmk) == (0xFF60, 0x61), vial.usage(qmk)
    assert vial.usage(mouse) == (0x01, 0x02), vial.usage(mouse)
    print("usage matcher: QMK raw HID ->", vial.usage(qmk), " a mouse ->", vial.usage(mouse))


if __name__ == "__main__":
    main()
