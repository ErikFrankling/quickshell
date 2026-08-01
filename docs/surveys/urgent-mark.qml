//@ pragma ShellId urgentmark

// The fifth pill state, measured. `pill-bounds.qml` settled four rungs of one
// ink — idle, hover, focused, focused+hover — and proved them monotonic on
// nine palettes. Urgency is a fifth thing a pill can be, and it arrives from
// outside: Hyprland sets it on a window that asked for attention and nobody
// gave it any. So the question this file answers is not "is the mark visible"
// — a 44x24 ground is never invisible — it is the two the ladder cannot
// answer:
//
//   1. Does the urgent ground stay clear of every rung of the shipped ladder,
//      so an urgent pill is never read as a merely hovered one?
//   2. Is it far enough from the *focused* pill, which is the same shape at
//      the same alpha in a different hue? That is not a lightness question at
//      all — a(bad,.30) and a(accent,.30) can land within a point of each
//      other in L* and still be obviously different colours, or not. So this
//      one is dE, the Lab distance, and not dL.
//
// dL is kept for everything measured against the ground, because that is the
// number pill-bounds.md is written in and the two files have to be readable
// side by side.
//
// Console only. The sheet pill-bounds.qml draws answers "which of twenty",
// and there are not twenty of these — there is one shape, and the whole of
// the argument is in the numbers.
//
// Harness only. Nothing here ships.
//
//   quickshell -p docs/surveys/urgent-mark.qml
//
import QtQuick
import Quickshell
import "file:///home/erikf/projects/personal/quickshell" as Shell

ShellRoot {
    id: root

    // ---- colour maths, verbatim from pill-bounds.qml ---------------------

    function lin(v) { return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
    function lum(c) {
        return 0.2126 * root.lin(c.r) + 0.7152 * root.lin(c.g) + 0.0722 * root.lin(c.b);
    }
    function lstar(c) {
        const y = root.lum(c);
        return y <= 216 / 24389 ? y * 24389 / 27 : Math.pow(y, 1 / 3) * 116 - 16;
    }
    function over(fg, a, bg) {
        return Qt.rgba(fg.r * a + bg.r * (1 - a),
                       fg.g * a + bg.g * (1 - a),
                       fg.b * a + bg.b * (1 - a), 1);
    }
    function step(mark, ground) { return Math.abs(root.lstar(mark) - root.lstar(ground)); }
    function wcag(mark, ground) {
        const x = root.lum(mark), y = root.lum(ground);
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
    }

    // ---- Lab, for the one question lightness cannot answer ---------------
    //
    // Two pills side by side, same size, same alpha, one accent and one bad.
    // Their L* can be equal and they are still plainly a different colour, so
    // the separation has to be measured in a space that has the other two
    // axes in it. CIE Lab under D65, and dE76 — the plain euclidean distance,
    // which is the crude one, and deliberately: dE2000's corrections shrink
    // large differences in saturated colour, and shrinking is the direction
    // that would flatter this design. Rule of thumb on dE76: ~2.3 is the
    // just-noticeable difference, 10 is "obviously not the same colour".
    function lab(c) {
        const f = t => t > 216 / 24389 ? Math.pow(t, 1 / 3) : (t * 24389 / 27 + 16) / 116;
        const r = root.lin(c.r), g = root.lin(c.g), b = root.lin(c.b);
        const x = f((0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047);
        const y = f(0.2126 * r + 0.7152 * g + 0.0722 * b);
        const z = f((0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883);
        return [116 * y - 16, 500 * (x - y), 200 * (y - z)];
    }
    function dE(a, b) {
        const p = root.lab(a), q = root.lab(b);
        return Math.sqrt(Math.pow(p[0] - q[0], 2) + Math.pow(p[1] - q[1], 2)
                       + Math.pow(p[2] - q[2], 2));
    }

    // Theme.qml's slot names over a raw base16 palette. Kept in step with
    // Theme.qml:26-49 by hand, the same way pill-bounds.qml keeps it.
    function pal(p) {
        const q = c => Qt.color(c);
        return {
            bg: q(p.base00), bgAlt: q(p.base01), bgHi: q(p.base02), dim: q(p.base04),
            fg: q(p.base05), line: q(p.line ?? p.base03),
            bad: q(p.base08), accent: q(p.accent ?? p.base0D)
        };
    }

    // ---- the states ------------------------------------------------------
    //
    // The four shipped rungs, then the candidates for the fifth. Urgent is
    // only ever drawn on a pill that is *not* focused — going to a workspace
    // is what clears its urgency — so the rung it must clear is the hover,
    // not the focused fill, and the thing it must not be confused with is the
    // focused fill of the pill next to it.
    readonly property var rungs: [
        { n: "idle    a(dim,.12)", k: "dim",    a: 0.12 },
        { n: "hover   a(dim,.22)", k: "dim",    a: 0.22 },
        { n: "focus   a(acc,.30)", k: "accent", a: 0.30 },
        { n: "focus+  a(acc,.40)", k: "accent", a: 0.40 }
    ]

    readonly property var candidates: [
        { n: "urgent  a(bad,.20)", k: "bad", a: 0.20 },
        { n: "urgent  a(bad,.30)", k: "bad", a: 0.30 },
        { n: "urgent  a(bad,.38)", k: "bad", a: 0.38 },
        { n: "urgent+ a(bad,.48)", k: "bad", a: 0.48 },
        { n: "urgent  a(bad,.60)", k: "bad", a: 0.60 },
        // The border. Not an alpha at all: waybar's own mark is `border-color:
        // #c9545d` at full strength, and a 1px line has no room to be faint.
        { n: "border  bad 1.00",   k: "bad", a: 1.00 }
    ]

    function head(rows, tag) {
        let h = "".padEnd(20);
        for (const r of rows) h += r.name.substr(0, 12).padStart(13);
        console.log(tag + " " + h);
    }

    function line(tag, label, rows, fn) {
        let s = label.padEnd(20), lo = 1e9, hi = 0;
        for (const r of rows) {
            const v = fn(root.pal(r.p));
            lo = Math.min(lo, v);
            hi = Math.max(hi, v);
            s += v.toFixed(1).padStart(13);
        }
        console.log(tag + " " + s + "  | " + lo.toFixed(1) + "-" + hi.toFixed(1));
    }

    function report(rows) {
        // 1. The shipped ladder, reprinted, so a change here can be checked
        //    against pill-bounds.md without running two files.
        root.head(rows, "LADDER");
        for (const g of root.rungs)
            root.line("LADDER", g.n, rows, p => root.step(root.over(p[g.k], g.a, p.bgHi), p.bgHi));

        // 2. Each candidate against the ground, in the ladder's own units.
        root.head(rows, "GROUND");
        for (const c of root.candidates)
            root.line("GROUND", c.n, rows, p => root.step(root.over(p[c.k], c.a, p.bgHi), p.bgHi));

        // 3. The margin over the hover rung — the rung an urgent pill can
        //    actually be sitting next to, since it is never focused.
        root.head(rows, "OVRHOV");
        for (const c of root.candidates)
            root.line("OVRHOV", c.n, rows, p =>
                root.step(root.over(p[c.k], c.a, p.bgHi), p.bgHi)
              - root.step(root.over(p.dim, 0.22, p.bgHi), p.bgHi));

        // 4. dE from the focused pill's fill: the pill it sits beside.
        root.head(rows, "SEPFOC");
        for (const c of root.candidates)
            root.line("SEPFOC", c.n, rows, p =>
                root.dE(root.over(p[c.k], c.a, p.bgHi), root.over(p.accent, 0.30, p.bgHi)));

        // 5. dE from the hovered idle pill, the other thing on the rail that
        //    is a tinted ground and not the focused one.
        root.head(rows, "SEPHOV");
        for (const c of root.candidates)
            root.line("SEPHOV", c.n, rows, p =>
                root.dE(root.over(p[c.k], c.a, p.bgHi), root.over(p.dim, 0.22, p.bgHi)));

        // 6. The number standing on it. WCAG ratio and not dL, because this
        //    one is text and text is the one place the ratio is the right
        //    instrument. The first two rows are the shipped design — the
        //    number goes Theme.bad and the ground under it does not move, so
        //    it is read against the two rungs an unfocused pill can be on.
        //    Then what it would have read at on a red ground, which is the
        //    row that costs the ground family the argument. Last, the shipped
        //    focused pill, which draws its accent on its own accent and is
        //    the precedent every row here has to be judged against.
        root.head(rows, "LABEL ");
        root.line("LABEL ", "bad on idle .12", rows, p =>
            root.wcag(p.bad, root.over(p.dim, 0.12, p.bgHi)));
        root.line("LABEL ", "bad on hover .22", rows, p =>
            root.wcag(p.bad, root.over(p.dim, 0.22, p.bgHi)));
        for (const c of root.candidates)
            root.line("LABEL ", "bad on " + c.n.substr(8), rows, p =>
                root.wcag(p.bad, root.over(p[c.k], c.a, p.bgHi)));
        root.line("LABEL ", "dim on a(bad,.38)", rows, p =>
            root.wcag(p.dim, root.over(p.bad, 0.38, p.bgHi)));
        root.line("LABEL ", "accent on focus", rows, p =>
            root.wcag(p.accent, root.over(p.accent, 0.30, p.bgHi)));

        // 7. Ink — dL times the pixels the mark covers, pill-bounds.md's own
        //    third number, because a 256px outline and a 1056px fill cannot
        //    otherwise be compared. The pill is 44x24: a 2px border is
        //    44*24 - 40*20 = 256, a 1px border 132, a fill 1056, and the
        //    focused pill's left marker 2 * round(24*.55) = 26.
        root.head(rows, "INK   ");
        root.line("INK   ", "2px border bad", rows, p => 256 * root.step(p.bad, p.bgHi));
        root.line("INK   ", "1px border bad", rows, p => 132 * root.step(p.bad, p.bgHi));
        root.line("INK   ", "marker bad (26px)", rows, p => 26 * root.step(p.bad, p.bgHi));
        root.line("INK   ", "ground a(bad,.38)", rows, p =>
            1056 * root.step(root.over(p.bad, 0.38, p.bgHi), p.bgHi));
        root.line("INK   ", "shipped a(dim,.12)", rows, p =>
            1056 * root.step(root.over(p.dim, 0.12, p.bgHi), p.bgHi));

        Qt.callLater(Qt.quit);
    }

    // Themes.qml's curated list is the one place the nine hand-picked
    // palettes exist; instantiated unseen so this reads them rather than
    // carrying a second copy that can drift. No window: the deliverable is
    // the numbers, and a survey that opens a panel on his screen to print
    // them is a survey that cannot be run while he is working.
    Shell.Themes {
        id: schemes
        Component.onCompleted: root.report(schemes.curated)
    }
}
