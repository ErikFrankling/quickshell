# One slot for the link *and* the tunnel

Erik, on the rail: *"why is network represented by two icons? should only be
one. should be able to represent the VPN some other way, idk — give me like 10
designs for how those networking logos can look."*

The rail had two: `networkBtn`, which says ethernet / wifi-at-a-strength /
offline, and `vpnBtn`, a key that exists only while a tunnel does. An hour
earlier the opposite had been tried — one glyph that swapped to a shield when
the tunnel came up — and it was rejected because it threw away the
ethernet-vs-wifi half at exactly the moment he wanted it. So the question is
whether *both* facts fit in one 28px slot.

Sixteen designs, drawn at true rail scale in `network-glyph.qml` and measured
from a screenshot of it. `vpn-glyph.md` is the companion: it asks which glyph
says "VPN" at 15px. This one asks what shape says it *without taking a slot*.

## What the corpus does — nothing

Sixteen trees read (noctalia plus the fourteen clones plus this shell). **Zero
prior art for expressing link type and tunnel state in one glyph or one
composed icon.** The corpus splits three ways:

| Approach | Who |
|---|---|
| Two independent bar widgets | noctalia (`Services/UI/BarWidgetRegistry.qml:30` and `:42`), josecriane (`modules/bar/components/StatusIcons.qml:108` and `:129`), corecathx `whisker` |
| Two glyphs in a `Row` inside one widget, the VPN one appearing and disappearing — so the slot's width changes | Brainitech `Brain_Shell`, `src/modules/Right/Network.qml:86`, glyph at `:92`, shield at `:111-119` |
| No VPN indication at all | the other twelve |

Not one icon expression anywhere reads VPN state and link state in the same
ternary. The building blocks all exist and have simply never been combined:

* a corner badge with a surface-coloured ring so it does not dissolve into the
  glyph under it — noctalia `Modules/Bar/Widgets/NotificationHistory.qml:121-138`
* a corner dot that means a *link state* rather than a count — josecriane
  `StatusIcons.qml:175-185`, `visible: parent.anyConnecting`, the only one in
  the corpus that is not an unread count
* a 3px underline under a bar icon — noctalia `Modules/Bar/Widgets/Taskbar.qml:870-887`,
  `bottomMargin: -2`, `height: 4`, and again at `Workspace.qml:806` and
  `Tray.qml:443`. Always focus or hover, never connectivity.

Three of the four corner dots in the corpus mean an unread count, which is the
measured version of Erik's complaint the first time this was tried here.

## How the numbers were taken

`network-glyph.qml` draws all sixteen at `Theme.slot` on `Theme.bgHi`, with the
glyph at `Theme.icon` — 28px, 15px, the rail's real ground — in eight columns:
ethernet, wifi 90%, wifi 20% and offline, each without and with a tunnel. Two
2px red registration marks bracket the grid so the measuring script finds it by
arithmetic rather than by recognising anything. It was rendered by Quickshell
itself and screenshotted with `grim`, so these are Qt's own rasterisations at
the size they will really be drawn, not an approximation.

```sh
quickshell -p docs/surveys/network-glyph.qml &
grim -o <output> /tmp/sheet.png
ffmpeg -i /tmp/sheet.png -vf "crop=800:850:20:20" -f rawvideo -pix_fmt rgb24 sheet.raw
```

Three measurements per design, all from the raw buffer:

* **Δpx** — how many of the slot's 784 pixels change by more than 24/255 in any
  channel when the tunnel comes up. This is the whole question of "can you tell
  at a glance", as a number.
* **thinnest** — the shortest run of changed pixels along any row or column of
  the slot. A mark whose thinnest run is 1px is a hairline, and a hairline on a
  58px rail at arm's length is not a mark.
* **apart** — the smallest pixel difference between any two of ethernet, wifi
  90% and wifi 20% *while the tunnel is up*. With no tunnel at all that number
  is **54**, so 54 means the design costs the link glyph nothing and 0 means the
  three link states have become the same picture.

## The sixteen

| # | design | Δpx /784 | thinnest | apart | verdict |
|---|---|---|---|---|---|
| 1 | two slots — the baseline it replaces | 0 | — | 54 | perfect, and costs 33px of rail (28 slot + 5 gap) |
| 2 | swap the glyph to a shield 󰦝 | 114–143 | 1px | **0** | the three link types become one picture. Measured proof of the rejection an hour ago |
| 3 | swap the glyph to a key 󰌆 | 123–162 | 1px | **0** | same |
| 4 | corner dot — Btn's own 8px accent badge | 58 | 5px | 54 | legible, but it is the unread-count mark, and see below |
| 5 | corner dot with a bgHi ring | 29 | 1px | 54 | the ring eats the disc: 29 changed pixels, thinnest run 1px |
| 6 | 9px key glyph in the corner | 33 | 1px | 54 | a blob; see the dump below |
| 7 | 9px padlock glyph in the corner | 42 | 1px | 54 | same, plus a padlock beside wifi reads as "this network has a password" |
| 8 | tint the link glyph green | 74–136 | — | 51 | works, but colour on this button already means online / not online |
| 9 | **underline, 14×3** | **42** | **3px** | **54** | **chosen** |
| 10 | 1px ring round the whole slot | 140 | 1px | 54 | a hairline, and it fights Btn's `active` fill |
| 11 | fill the slot ground, `alpha(good, 0.22)` | 134 | 1px | 51 | the ground itself changes by **23/255** — below the threshold. Invisible |
| 12 | stacked composite, 11px link over 9px key | 128–155 | 1px | **28** | the link glyph loses half its separation to make room |
| 13 | Nerd Font's own wifi+lock glyphs | **0** on ethernet, **0** offline, 58–68 on wifi | 1px | 52 | there is no ethernet-with-lock and no offline-with-lock in the set |
| 14 | key at 15px, link type as an 8px footnote | 156–197 | 1px | **16** | link type is a smudge |
| 15 | link glyph shrunk inside a shield | 134–141 | 1px | **16** | same |
| 16 | 9px corner notch | 69 | 5px | 54 | visible, but an arbitrary shape, and it fights the slot's own 10px radius |

### The ones the numbers alone do not explain

**4, the corner dot.** It measures well — 58 changed pixels, a 5px thinnest run
— and it still fails twice. It is `Btn.badge`, the same 8px accent disc the
control-centre arrow uses for the unread notification count, and Erik read it as
exactly that the first time. And at 3px margin it *touches the glyph*: rendered
at the top right of the wifi-90% fan, the disc and the fan run into each other.

```
                  .++++.        <- the badge
                 .+####+.
                 +######+
                 +######+
         .+#####++######+       <- and the fan, joined to it
       +###############+.
      ###############++.
```

**6, a key glyph in the corner.** At 9px the key is 33 ink pixels in a 9×6 box
with a thinnest run of one, and it is clipped by the slot edge:

```
                     ..
                    OOO+
                   .O+OOOOOO
                   .O+OOOOOO
                    OOO+ O#
```

Compare the same glyph at the 15px it gets in its own slot, which has a bow, a
shaft and two teeth and is what `vpn-glyph.md` chose:

```
             .OOO+
            .OOOOO+
            OOOOOOO++++++.
            OO+ .OOOOOOOO#
            OO+ .OOOOOOOO#
            OOOOOOO..OOO..
             OOOOO+  OOO
              OO+.   OOO
```

**13, the fused Nerd Font glyphs.** `nf-md-wifi_strength_4_lock` U+F092A and
`nf-md-wifi_strength_1_lock` U+F0921 do exist in JetBrainsMono Nerd Font 3.4 —
checked against the font's own charset, not assumed. But there is no
`ethernet-lock` and no `wifi-strength-off-lock`, so on a machine on a cable the
design changes **nothing at all**: 0 pixels out of 784. Half the states cannot
be drawn. And where it does apply, the padlock is bitten out of the fan and
damages its silhouette at 15px:

```
         +#######.
       +###########+
      ##############+
      .#############
       +#########++.
        +######+.+.
         ######.#+#+
         .####+.# ++
          .###.+####.
           +##.#####.
```

The one use of a fused wifi+lock glyph anywhere in the corpus is
corecathx `whisker`, `modules/bar/NetworkTray.qml:305` — and it means **captive
portal**, not VPN.

**11, tinting the ground.** Worth recording because it looks free. A 22% wash of
`Theme.good` over `Theme.bgHi` is a **23/255** change in the strongest channel.
That is under the 24 threshold used throughout this sheet, which is itself
generous. The design is not subtle; it is invisible.

## What was chosen, and what it costs

**Design 9, a 14×3 bar under the glyph, in `Theme.good`.**

```
         .+#####+.
       +###########.
      ##############+
      +#############.
       +###########.
        ##########+
         ########+
         .#######
          +#####.
           +###.
            ##+
             +


       OOOOOOOOOOOOOO
       OOOOOOOOOOOOOO
       OOOOOOOOOOOOOO
```

It is the only design that scores well on all three measurements at once:

* **42 changed pixels**, and — uniquely — *the same 42* under all four link
  glyphs. Every other mark that touches the glyph changes by a different amount
  depending on how much ink is under it.
* **3px at its thinnest**, against 1px for every corner-glyph, ring and
  composite design. Only the dot (5px) and the notch (5px) are thicker, and both
  of those are already spoken for.
* **54 apart** — the full no-tunnel separation. The link glyph is not touched,
  moved, shrunk or recoloured, so ethernet, wifi and offline are exactly as
  distinguishable with the tunnel up as without it. That is the thing the
  shield swap destroyed.

It also never collides: the bar lives in the two rows of slot the glyphs do not
reach, which is why it is the same 42 pixels every time.

**What it costs against the two slots it replaces.** The two-slot version drew
a *key* — an object, at 15px, with a bow and teeth, that a person can look at
and name. The bar is a bar. It has to be learnt once; nothing about its shape
says "tunnel". It also cannot say *which* tunnel or *how many*, and there are
now two of them on the laptop. That is the trade: the rail gives up naming the
tunnel and gets 33 pixels back, the unread-count badge stays unique, and the
panel — which had to grow a row per tunnel anyway — becomes the only place the
tunnels are named. On a rail this narrow that is the right side of the trade,
but it is a real loss and not a free win.

The shape is noctalia's, `Modules/Bar/Widgets/Taskbar.qml:870-887`. It means
focus there and a tunnel here, and nothing on this rail uses it for anything, so
the vocabulary stays one-to-one.

## Does the matcher see both of his tunnels?

Erik: *"you missed with the VPN — i actually have several, an OpenVPN and the
Cloudflare private access WARP thing."*

`Net.qml` matches a tunnel by `linkinfo.info_kind` out of `ip -j -d addr`,
chosen so that one expression catches WireGuard, OpenVPN and WARP alike. Both
halves of that claim were tested rather than assumed.

**Cloudflare WARP, live on this machine.** `info_kind: "tun"`, `operstate:
"UNKNOWN"`, `100.96.0.113`. It is absent from `Networking.devices` entirely, so
there is no way to see it through the Quickshell API — the device list here is
`eno1:Wired`, `wlp11s0:Wifi`, `vmnet1:Wired`, `vmnet8:Wired`, logged from the
running shell.

**OpenVPN.** `modules/nixos/openvpn.nix` is included by `hosts/framework` and
commented out on `hosts/pc`, and this session ran on `pc` — so `tun0` was not
available to look at. Instead the real binary his module builds, OpenVPN
2.6.21, was run inside an unprivileged network namespace (`unshare -r -n`),
which touches nothing outside itself:

```
3: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 state UNKNOWN
    tun type tun pi off vnet_hdr off persist off
```

```json
{"ifname":"tun0","operstate":"UNKNOWN",
 "linkinfo":{"info_kind":"tun","info_data":{"type":"tun",...}},
 "addr_info":[{"family":"inet","local":"10.8.0.6","scope":"global"}]}
```

`info_kind` is `tun`, so the matcher catches it. Two further facts fell out:

* **`tap` mode reports `info_kind: "tun"` as well**, with `info_data.type`
  carrying `tap`. So an OpenVPN in bridged mode is caught by the same
  expression, without a second branch.
* **The `operstate !== "DOWN"` guard is doing real work.** The kernel's tun
  driver holds carrier off until a process attaches, so a persistent tun device
  nobody is using reads `DOWN` — measured, by creating one with `ip tuntap add`
  and never attaching — and a live one reads `UNKNOWN`. That is what stops a
  leftover interface from claiming the rail.

**Both at once.** Two OpenVPN processes in one namespace, one on `tun0` and one
named `CloudflareWARP`, produced a two-tunnel `ip -j -d addr`. Pointing `Net`'s
probe at that capture for one reload gave, from the running shell's log:

```
tunnels=[{"name":"tun0","ip":"10.8.0.6"},
         {"name":"CloudflareWARP","ip":"100.96.0.113"}] vpn=true
```

and the panel drew a row each — `tun0`, then `CloudflareWARP`, then `Wi-Fi` —
read back out of the screenshot. `find` had been returning the first match
only, and the dotfiles order `cloudflare-warp.service` *before*
`openvpn-homeVPN.service`, so WARP always won the race and the OpenVPN he set up
by hand was the one that never appeared. That is the bug he hit.

So the display did not have to be dropped. The rail says *some* tunnel is up —
count-independent, because a bar cannot carry a number — and the panel lists
every one of them by interface and address.

## Two link facts that changed with it

**When the tunnel *is* the default route.** `Net.device` now falls back from
"the device named by the default route" to "whichever device is connected",
because a full tunnel replaces the default route with `tun0`, which
`Networking.devices` has never heard of. Without the fallback the one moment the
rail cannot tell wifi from ethernet is the moment a VPN is up. His OpenVPN
probably does not hit this — `redirect-gateway def1` splits the default into
`0.0.0.0/1` and `128.0.0.0/1` and leaves `default` on the physical gateway — but
some WireGuard configurations do. The old code answered this with a shield
glyph, which is now gone: the glyph is about the link and only the link.

**Wifi hardware versus a wifi switch.** These need different UI and are
different questions:

| | test | UI |
|---|---|---|
| no radio in the machine | no `DeviceType.Wifi` in `Networking.devices` → `Net.hasWifi === false` | nothing wifi renders: no row, no toggle, no list |
| a radio, switched off | `Net.hasWifi && !Networking.wifiEnabled` | the Wi-Fi row, reading `off`, and a row that turns it on |

`Networking.wifiHardwareEnabled` is **not** the first test, despite the name. It
is NetworkManager's `WirelessHardwareEnabled`, which means "no hardware rfkill
switch is blocking the radio" — measured `true` on this machine at the same time
as `rfkill` reports `phy0` unblocked. Device presence is the unambiguous
question and is what the panel gates on. Verified by turning the radio off with
`nmcli radio wifi off` and reading the row back out of a screenshot — label
`Wi-Fi`, value `off`, with the card still present — then restoring it.

**And when the list opens by itself.** The wifi list now starts expanded when
wifi is *the link carrying the default route* — `Net.wifi` — and not when the
radio merely exists or is merely switched on. Measured on this desktop:
`nmcli radio` reports WIFI **enabled** while `wlp11s0` is disconnected with no
saved connection at all and `eno1` carries everything. Gating on
`Networking.wifiEnabled` would have opened a screen-height list of neighbours on
exactly the machine the collapse was written for.

That change moves the battery risk, so the scanner gate gained a term:
`root.visible && root.wifiOpen && Networking.wifiEnabled`. `wifiOpen` is now
true by default on the laptop, so without `root.visible` the radio would sweep
for as long as the shell ran. `restoreMode: Binding.RestoreNone` stays — the
default puts the old value back when the Binding dies, and the old value is
whatever the scanner was when the page opened.
