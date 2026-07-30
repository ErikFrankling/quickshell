import ".."
import QtQuick
import Quickshell
import Quickshell.Io

// Optional: derive the palette from the wallpaper instead of picking one.
//
// wallust reads a terminal palette out of an image. It is pywal's maintained
// successor, and the right tool here rather than a Material You generator,
// because this palette has to colour terminals too — Material You gives
// semantic roles, not sixteen ANSI hues, and terminals come out grey.
// It needs declaring in flake.nix runtimeDeps.
//
// The derived palette goes through Theme.apply like any hand-picked one, so it
// reaches the state file, ~/.cache/wal and the open terminals by exactly the
// same path, with no special case anywhere else.
QtObject {
    id: root

    property bool on: false
    property var prev: null
    signal failed

    // wallust caches the palette it computed, as JSON. A throwaway
    // XDG_CACHE_HOME gets that printed without touching wallust's real cache or
    // its config, and -s keeps it away from the terminals, which Scheme owns.
    //
    // lchansi with the ansidark16 palette is the combination that keeps tty
    // colour order — red stays red, green stays green, only tinted by the
    // image. Any other palette shuffles the hues by salience instead, which
    // reads fine as a wallpaper but makes a terminal's colours lie.
    property Process gen: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    Theme.apply(root.base16(JSON.parse(text)));
                } catch (e) {
                    root.failed();
                }
            }
        }
    }

    property FileView store: FileView {
        path: Quickshell.statePath("wallmatch.json")
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.on = s.on === true;
                root.prev = s.prev ?? null;
            } catch (e) {}
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => root.store.setText("{}"));
        }
    }

    function toggle(wallpaper) {
        // Remember the theme being left behind, so switching back off returns
        // to it rather than to whatever the default happens to be.
        if (!root.on)
            root.prev = Theme.palette;
        root.on = !root.on;
        root.store.setText(JSON.stringify({ on: root.on, prev: root.prev }));

        if (root.on)
            root.derive(wallpaper);
        else if (root.prev && root.prev.base00)
            Theme.apply(root.prev);
    }

    function derive(path) {
        if (!path)
            return;
        root.gen.running = false;
        root.gen.command = ["sh", "-c",
            'd=$(mktemp -d) && XDG_CACHE_HOME="$d" wallust run -N -q -s -T ' +
            '-c lchansi -p ansidark16 ' +
            JSON.stringify(path) + ' >/dev/null 2>&1; ' +
            'f=$(grep -rl \'"color0"\' "$d" 2>/dev/null | head -1); ' +
            '[ -n "$f" ] && cat "$f"; rm -rf "$d"'];
        root.gen.running = true;
    }

    function lerp(a, b, t) {
        const ch = h => [1, 3, 5].map(i => parseInt(h.substr(i, 2), 16));
        const x = ch(a), y = ch(b);
        return "#" + x.map((v, i) => Math.round(v + (y[i] - v) * t)
            .toString(16).padStart(2, "0")).join("");
    }

    // Scheme.qml's base16-to-ANSI table read backwards. base01, base02, base04,
    // base06, base09 and base0F have no ANSI colour to come from, so they are
    // mixed out of the ones that do — the backgrounds and foregrounds stepped
    // off base00 and base05, orange between red and yellow, brown between red
    // and magenta.
    function base16(w) {
        const bg = w.background, fg = w.foreground;
        return {
            name: "Wallpaper",
            base00: bg,
            base01: root.lerp(bg, fg, 0.07),
            base02: root.lerp(bg, fg, 0.14),
            base03: w.color8,
            base04: root.lerp(w.color8, fg, 0.5),
            base05: fg,
            base06: root.lerp(fg, "#ffffff", 0.3),
            base07: w.color15,
            base08: w.color1,
            base09: root.lerp(w.color1, w.color3, 0.5),
            base0A: w.color3,
            base0B: w.color2,
            base0C: w.color6,
            base0D: w.color4,
            base0E: w.color5,
            base0F: root.lerp(w.color1, w.color5, 0.5),
            line: root.lerp(bg, fg, 0.2),
            accent: w.color4
        };
    }
}
