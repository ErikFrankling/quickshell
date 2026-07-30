# Which glyph says "VPN" on a 58px rail?

Erik, looking at the rail: *"as for the wifi or internet icon — i guess the
shield is supposed to be a VPN? that's a bit weird, maybe find a proper VPN
logo."*

The rail draws its icons from JetBrainsMono Nerd Font 3.4 at
`Theme.icon` — **15px**. That size is the whole question. Every candidate below
exists in the font; only some of them survive being drawn that small.

## What other shells use

| Project | File:line | Icon | Set |
|---|---|---|---|
| noctalia | `Modules/Bar/Widgets/VPN.qml:107` | `shield-lock`, falling back to `shield`, and `shield-off` in the menu at `:55` | Tabler |
| DankMaterialShell | `Modules/ControlCenter/BuiltinPlugins/VpnWidget.qml:17`, `Modules/Settings/NetworkVpnTab.qml:46`, `Modules/ControlCenter/Details/VpnDetailContent.qml:29` | `vpn_key` | Material Symbols |
| DankMaterialShell (bar widget setting) | `Modules/Settings/WidgetsTabSection.qml:2262` | `vpn_lock` | Material Symbols |
| caelestia | `modules/utilities/cards/Toggles.qml:144` | `vpn_key` | Material Symbols |
| Moonveil (CrescentShell) | `modules/theme/Icons.qml:244` | `U+EC34` — Tabler `shield-lock`, **absent from this font**, renders as tofu here | Tabler |

So there are exactly two conventions in the wild: a **shield** and a **key**.
Nobody uses the glyph that is actually named "vpn".

## The candidates, drawn at the size they will be drawn at

Rendered with the shipped font at 15px and dumped as ASCII, so the comparison is
reproducible without an image viewer:

```sh
ffmpeg -f lavfi -i color=c=black:s=26x26 \
  -vf "drawtext=fontfile=$FONT:text='<glyph>':fontsize=15:fontcolor=white:x=4:y=(h-text_h)/2-2" \
  -frames:v 1 -f rawvideo -pix_fmt gray out.raw
od -An -v -tu1 -w1 out.raw | awk '{c=($1>190?"#":($1>110?"+":($1>40?".":" ")));printf "%s",c; if(NR%26==0)print ""}'
```

**U+F099D `nf-md-shield-lock` — what the rail shipped**

```
        +#+.
     .+#####+.
    +#########
    ##########
    ####...###
    ####.#++##
    ###+ . .##
    ###     ##
    +##     ##
    .##.    ##
     +########
      #######.
       +####.
        .+.
```

Legible. A shield with a keyhole. Rejected on meaning, not on legibility: it
says "security" in general, which is how Erik read it.

**U+F0582 `nf-md-vpn` — the glyph literally named vpn**

```
     ###..##..
    #+.+#....#
    #.  ++ .#.
    +#.+  .#.
     +#+ .#.
        .#. +
        ++  #.
        +# .#.
         ###+
          .
```

Three thin letterforms at 64px; mush at 15. **Rejected.** This is the finding
worth keeping: the obvious answer, the icon whose name is the word, is the one
that cannot be used.

**U+F183D `nf-md-tunnel`**

```
         .+++.
        +######
       ##. #. +
      +##+###+#
      #.+######
     .# #######
     +#########
     +#.#######
     +#########
     ++ #######
     .#########
```

A hatched arch. At 15px it is a filled blob with a rounded top and reads as no
particular object. **Rejected.**

**U+F0318 `nf-md-lan-connect`**

```
      +#####
      #+...#.
      #.   #.
      +#####
     +#######
      .......
       +     ++
      .#    +#+
      .#    ++
      .#... ++
      .#### +##
            +##
```

Legible, and says "LAN". Wrong word. **Rejected.**

**U+F0306 `nf-md-key` — chosen**

```
     .###+
    .######
    ###.+##+++
    ##+  #####
    ###.+#####
    +######  +
     +####.  +
       ..    .
```

Legible at 15px: a bow, a shaft, two teeth. It is Material's own `vpn_key`, the
glyph DankMaterialShell and caelestia both use for exactly this, and it is not
the shield.

`U+F0307 nf-md-key-variant` is the same shape outlined and loses the teeth at
this size; `U+F033E nf-md-lock` is the most legible glyph of the lot but a
padlock beside a wifi icon reads as "this network has a password".

## Verified on the live rail

`ip link show tun0 up` was temporarily pointed at `lo` so the button would
appear. The glyph renders in `Theme.good` — bow at the top, shaft and teeth
below — and is not the `.notdef` box:

```
        y=966         GGGGGG
        y=969        GGG .GGGGGGGGG
        y=972          GGG    GGG
```

## The dot

The same button carried `badge: win.vpn ? 1 : 0`, which is `Btn`'s 8px accent
circle in the top-right corner — the same mark the control-centre arrow used for
unread notification count. So one shape meant two unrelated things, and on this
button it sat on top of a glyph that already said the same thing. Erik read it
as a notification, which is what it looked like. Deleted; the button that only
exists while the tunnel does says it once.
