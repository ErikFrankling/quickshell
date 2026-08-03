pragma Singleton

import Quickshell
import Quickshell.Io

// Publishes the palette in the formats the rest of the desktop already reads,
// so picking a theme here recolours everything else too.
//
// Two channels, because only two of them actually work. The files go in
// ~/.cache/wal/ — pywal's layout, and the most widely `source`d, `@import`ed
// and `include`d colour convention on Linux; a kitty `include` or a waybar
// `@import` pointed there needs no further cooperation. Nothing watches those
// files, so terminals that are already open get OSC escape sequences written
// straight to their /dev/pts, which every terminal understands by virtue of
// being a terminal. `sequences` is kept on disk so a new shell can `cat` it and
// match the ones already running.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.cache/wal"

    // base16 slot -> ANSI colour, the mapping base16-shell has always used.
    // The bright half repeats the normal half; only black and white differ.
    readonly property var ansi: ["base00", "base08", "base0B", "base0A", "base0D", "base0E", "base0C", "base05", "base03", "base08", "base0B", "base0A", "base0D", "base0E", "base0C", "base07"]

    // Perceived luminance of the default background. base16 backgrounds sit at
    // the ends of the range — Gruvbox light is 0.94, Gruvbox dark 0.12 — so the
    // midpoint is nowhere near anything real.
    function isLight(hex) {
        const c = String(hex).replace("#", "");
        const r = parseInt(c.slice(0, 2), 16) / 255;
        const g = parseInt(c.slice(2, 4), 16) / 255;
        const b = parseInt(c.slice(4, 6), 16) / 255;
        return 0.299 * r + 0.587 * g + 0.114 * b > 0.5;
    }

    // The sixteen colours last written out. Publishing is reached from two
    // directions now — the picker, and any write to the state file from
    // outside the shell — and one theme change fires both, so the second has
    // to be a no-op or every terminal on the machine is sent the escape
    // sequences twice. Comparing what would be written against what is there
    // is also what makes it safe to publish on startup: if the files already
    // say this palette nothing runs, and if they are stale they are put right
    // without anybody having to ask.
    property string current: ""

    function publish(p) {
        if (!p.base00)
            return;

        const c = root.ansi.map(k => p[k]);
        if (c.join("\n") === root.current)
            return;
        root.current = c.join("\n");

        const bg = p.base00;
        const fg = p.base05;
        const each = fmt => c.map((v, i) => fmt("color" + i, v)).join("\n");
        const esc = (i, v) => "\u001b]" + i + ";" + v + "\u001b\\";

        const files = {
            "colors": c.join("\n"),

            "colors.sh": "background='" + bg + "'\nforeground='" + fg + "'\ncursor='" + fg + "'\n" + each((k, v) => k + "='" + v + "'"),

            "colors.json": JSON.stringify({
                alpha: "100",
                special: {
                    background: bg,
                    foreground: fg,
                    cursor: fg
                },
                colors: c.reduce((o, v, i) => (o["color" + i] = v, o), {})
            }, null, 4),

            "colors.css": ":root {\n  --background: " + bg + ";\n  --foreground: " + fg + ";\n  --cursor: " + fg + ";\n" + c.map((v, i) => "  --color" + i + ": " + v + ";").join("\n") + "\n}",

            // GTK's own CSS dialect — what waybar, mako and a gtk.css want.
            "colors-waybar.css": "@define-color background " + bg + ";\n@define-color foreground " + fg + ";\n" + each((k, v) => "@define-color " + k + " " + v + ";"),

            "colors-kitty.conf": "background " + bg + "\nforeground " + fg + "\ncursor " + fg + "\n" + each((k, v) => k + " " + v),

            // The scheme itself in tinted-theming's base16 format, which is
            // what the few hundred base16 app templates are all built from.
            "colors-base16.yaml": // Derived from base00, which is the default background by definition.
// Hardcoding "dark" here published a light scheme as dark and made every
// consumer that trusts the field render unreadably.
'system: "base16"\nname: "' + p.name + '"\nvariant: "'
                + (root.isLight(p.base00) ? "light" : "dark") + '"\npalette:\n' + Object.keys(p).filter(k => k.startsWith("base")).sort().map(k => '  ' + k + ': "' + p[k] + '"').join("\n"),

            // 4;n palette, 10 foreground, 11 background, 12 cursor, 17/19 selection.
            "sequences": c.map((v, i) => esc("4;" + i, v)).join("") + esc(10, fg) + esc(11, bg) + esc(12, fg) + esc(17, p.base02) + esc(19, fg)
        };

        let sh = "d=" + JSON.stringify(root.dir) + '; mkdir -p "$d"\n';
        for (const f in files)
            sh += 'cat > "$d/' + f + '" <<\'QSEOF\'\n' + files[f] + "\nQSEOF\n";

        // The command substitution drops the newline the heredoc added, which
        // would otherwise print a blank line in every terminal on the machine.
        sh += 's=$(cat "$d/sequences"); printf %s "$s" > "$d/sequences"\n';
        sh += 'for t in /dev/pts/[0-9]*; do printf %s "$s" > "$t" 2>/dev/null; done\n';

        write.running = false;
        write.command = ["sh", "-c", sh];
        write.running = true;
    }

    Process {
        id: write
    }

    // `colors` is the shortest of the files and holds exactly the sixteen,
    // so it is the cheapest way to ask what the desktop is currently wearing.
    // Read once at startup and never watched: after that this shell is the
    // only thing writing it.
    FileView {
        path: root.dir + "/colors"
        onLoaded: {
            if (root.current === "")
                root.current = text().trim();
        }
    }
}
