pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Colour lives here and nowhere else.
//
// A theme is a base16 palette — base00, the darkest background, through base0F
// — which is the colour format tinted-theming, pywal, matugen and a few hundred
// application templates already agree on. The names below are only this shell's
// words for particular slots; Scheme writes the same palette out in the places
// other applications look, so a theme is not just a shell theme.
//
// The palette is read from a state file so the picker can change it at runtime;
// the values below are the fallback when that file does not exist yet.
Singleton {
    id: root

    property var palette: ({})

    function c(key, fallback) {
        return root.palette[key] ?? fallback;
    }

    readonly property color bg: c("base00", "#16181d")
    readonly property color bgAlt: c("base01", "#1d2027")
    readonly property color bgHi: c("base02", "#252932")
    readonly property color dim: c("base04", "#7c8796")
    readonly property color fg: c("base05", "#d3dae3")

    // Borders and hairlines. Not a base16 slot: base03 means "comments", a grey
    // that has to be *readable* against base00, and a border that readable is a
    // scar. So a theme names its border itself, the way it names its accent, and
    // base03 is left to mean what the spec says it means — this shell used to
    // keep the border in base03 and publish it as the comment colour, which every
    // application reading the palette correctly then got wrong. A palette that
    // names no border still falls back to base03: it is the dimmest colour in a
    // base16 scheme that is meant to be seen at all, and it is where the border
    // used to live, so palettes saved before the split still draw as they did.
    readonly property color line: c("line", c("base03", "#2c313b"))
    readonly property color bad: c("base08", "#f7768e")
    readonly property color warn: c("base0A", "#e0af68")
    readonly property color good: c("base0B", "#9ece6a")

    // base0D is the scheme's blue, and the accent for most of them. A theme
    // whose identity is a colour base16 keeps no slot for — Gruvbox's yellow,
    // Everforest's green — names its accent itself.
    readonly property color accent: c("accent", c("base0D", "#7aa2f7"))

    readonly property string name: c("name", "Tokyo Night")

    readonly property int rail: 58
    readonly property int panel: 430
    readonly property int radius: 20
    readonly property int radiusS: 10
    readonly property int pad: 14
    readonly property real panelOpacity: 0.82

    // The rail's vertical rhythm, and the only place it is decided.
    //
    // Every control on the rail stands `slot` tall with `slotGap` under it: a
    // workspace pill, a metric ring, a button and a tray cell all take the same
    // stripe of the bar, so scanning down the rail is scanning down one grid.
    // Widths still differ — a pill carries a number and up to two application
    // icons, a button carries one glyph — because equal *slot* is the point,
    // not equal shape. Noctalia's bar works the same way: one capsuleHeight,
    // 27px against a 33px bar, that every widget on the bar is measured from,
    // and one widgetSpacing between them.
    //
    // 28 is where the rail already was on average — the pills were 24, the tray
    // cells 26, the rings 30 and the buttons 34 — so unifying costs the rail no
    // height overall. It gains the pills four pixels and a two-point larger
    // number, and takes six back off every button, which is the direction the
    // rail was wrong in: cramped at the top, loose at the bottom.
    readonly property int slot: 28
    readonly property int slotGap: 5
    readonly property int icon: 15

    // A group's rounded ground: how far it is inset from the rail, and how much
    // air it keeps around its column.
    //
    // 50, not the 46 it was, because the widest thing standing on this ground
    // had stopped fitting on it. Design 9's captions put the metric's name and
    // its total on one row (docs/surveys/metric-centred.md) and the longest of
    // them, `data 2.0T`, lays down 43px of ink: on a 46px ground that is one
    // pixel of air on the left and two on the right, which Erik read off the
    // rail as the caption running out of its own background. Ink does not
    // touch a ground it belongs to.
    //
    // 50 is what the rail can afford. The rail is 58 and is not moving — it is
    // the exclusive zone, and a panel attaches flush to its right edge and
    // tucks one pixel under it (CardShape.qml:91) — so every pixel a group
    // gains is a pixel of that edge given up. At 50 the ground sits 4px inside
    // the rail on each side and the widest caption gets 3px of air on the left
    // and 4 on the right, three to four times what it had. 52 was drawn too
    // and buys one further pixel of air for a quarter of the rail's channel: 3px
    // between a 10px corner radius and the seam a panel attaches to is no
    // longer a margin, it is a hairline, and the group would read as having
    // slipped off the rail rather than as sitting on it.
    //
    // Every group inherits this — Group.qml:50, plus the metrics block at
    // shell.qml:560, which is a Group in all but name — so this is the number
    // that keeps the five grounds down a 58px strip on one vertical line, and
    // widening only the rings' would put one of five out of true. The two
    // groups that size themselves from it, RailPlayer.qml:112 and
    // RailClock.qml:109, follow at `groupWidth - 4` and are better for it: the
    // clock's open-state ground was 42px around 42px of digits, hairline hard
    // against the glyphs, and is now 46 around the same 42.
    readonly property int groupWidth: 50
    readonly property int groupPad: 6
    readonly property int groupGap: 8

    function heat(pct) {
        return pct >= 90 ? bad : pct >= 70 ? warn : accent;
    }

    function apply(p) {
        root.palette = p;
        store.setText(JSON.stringify(p));
        Scheme.publish(p);
    }

    FileView {
        id: store
        path: Quickshell.statePath("theme.json")
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        // Publishing here, and not only in apply(), is what makes the theme a
        // property of the machine rather than of this window. `erikshell-theme`
        // writes this file and nothing else; the shell recolours because the
        // watch fires, and the terminals, kitty, waybar and neovim recolour
        // because this line takes the same road apply() takes. Without it a
        // theme set from a terminal — which is the only way to set one over
        // SSH — would repaint the shell and leave every other application on
        // the palette it had, which is the half-fix.
        //
        // It costs nothing when the change came from apply(): Scheme compares
        // the sixteen colours against what it last wrote and returns.
        onLoaded: {
            try {
                root.palette = JSON.parse(text());
            } catch (e) {
                return;
            }
            Scheme.publish(root.palette);
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => store.setText("{}"));
        }
    }

    // The picker's list of themes, written out where a command line can read
    // it. Nothing in the shell reads it back — it exists so that setting a
    // theme from a terminal does not mean a second copy of the palettes going
    // quietly out of date. Catalog builds it from the same two places the
    // picker does.
    FileView {
        id: catalogue
        path: Quickshell.statePath("themes.json")
        atomicWrites: true
        onLoaded: Qt.callLater(() => {
            if (catalogue.text() !== Catalog.json)
                catalogue.setText(Catalog.json);
        })
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => catalogue.setText(Catalog.json));
        }
    }
}
