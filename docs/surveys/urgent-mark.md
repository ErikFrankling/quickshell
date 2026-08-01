# The workspace that is trying to get your attention

> "something very nice that waybar had was that the workspace buttons would
> turn like red and shit when there was something happening in that workspace.
> it's a concept in wayland i think. want to be alerted when in a browser for
> example a link was opened. investigate how that works in waybar and how
> others have implemented that in quickshell."

Source: `urgent-mark.qml`. Run it with

    quickshell -p docs/surveys/urgent-mark.qml

It prints and does not draw, for the reason `pill-bounds.qml` prints: a survey
harness has its own `ShellId` and therefore its own empty `theme.json`, so it
can only ever be *seen* in one scheme, and every question here is a question
about all nine. It instantiates `Themes.qml` unseen and reads its own `curated`
list, so no palette is copied twice.

---

## 0. What the thing is called

It is not an xdg_activation feature exactly, though that is where it comes
from. The protocol is `xdg-activation-v1`: a client that wants to be raised
asks for a token and hands it to the window it wants focused. What the
compositor does with that request is policy, and Hyprland's policy is the
option `misc:focus_on_activate`, which on this machine reads

    $ hyprctl getoption misc:focus_on_activate
    int: 0
    set: false

— off, and off by default; his Hyprland config never mentions it. So an
activation request does **not** steal focus. Instead Hyprland marks the window
urgent and says so, once, on the event socket. That is the whole mechanism: a
one-shot notice, not a state you can go and read.

**Nothing in `hyprctl` reports it.** The full key list of a `hyprctl clients -j`
entry on 0.56.0 is `acceptsInput address allowedOverFullscreen at class
contentType floating focusHistoryID fullscreen fullscreenClient
fullscreenHandler grouped hidden inhibitingIdle initialClass initialTitle
mapped monitor pid pinFullscreened pinned size stableId swallowing tags
tearingHint title visible workspace xdgDescription xdgTag xwayland` — no
urgency field, and `hyprctl workspaces` has none either. Anything that polls
`hyprctl` cannot see this. That is worth writing down because polling is the
obvious first idea and it is a dead end.

The event is `urgent`, on socket 2, carrying the window address with no `0x`:

    urgent>>5e1138b14a20

Confirmed by reading the socket directly while the trigger was pulled — §5.
Hyprland's own Lua stubs name the same concept three more times, which is a
useful cross-check that the string was not guessed:
`share/hypr/stubs/hl.meta.lua:31` declares the event `"window.urgent"`, `:795`
gives a workspace `has_urgent`, and `:841` gives `get_urgent_window`. The
`focusurgentorlast` dispatcher — "Focus the urgent window or the last window" —
is the consumer side of the same flag.

## 1. What his waybar actually does

Both halves of it are in the dotfiles and neither is a default.

`modules/home-manager/waybar/config.jsonc:164-176` — the module opts in by
naming an icon for the state, which is what makes waybar emit the CSS class at
all:

```jsonc
"hyprland/workspaces": {
    "format": "{icon} {name}",
    "format-icons": {
        "1": "",  "2": "",  "3": "󰈹",
        "urgent": "",
        "active": "",
        "default": ""
    },
},
```

`modules/home-manager/waybar/style.css:212-231` — and this is the part worth
reading closely, because the mark is not the one you would guess from the word
"border":

```css
#workspaces button {
  border-top: 2px solid transparent;
  /* To compensate for the top border and still have vertical centering */
  padding-bottom: 2px;
  ...
  color: #888888;
}

#workspaces button.active {
  border-color: #4c7899;
  color: white;
  background-color: #285577;
}

#workspaces button.urgent {
  border-color: #c9545d;
  color: #c9545d;
}
```

So every button carries a **2px rule along one edge**, invisible until a state
colours it. `active` colours the rule *and* fills the ground. `urgent` colours
the rule and the label, and touches no ground at all.

That is the shape this shell already has. The focused pill is a filled ground
plus a 2px marker (`Workspaces.qml`, the `Rectangle` anchored left at 55%
height in `Theme.accent`) — waybar's `active`, transposed from a horizontal bar
to a vertical rail. Which means the urgent state has a shape waiting for it
too: the edge, and the label, in the alarm colour, and the ground left alone.

`#c9545d` is a desaturated red. `Theme.bad` is `base08`, which is what every
base16 scheme calls its red, so this is the token — never the literal, or the
light schemes get a mid-dark red that was picked against a dark ground.

## 2. Does Quickshell expose it?

Yes, on both the workspace and the window, and this was nearly missed. The
public `Quickshell/Hyprland/quickshell-hyprland.qmltypes` does **not** contain
the string `urgent` — the Hyprland types are not declared there. They are
declared in the private submodule the public `qmldir` re-exports:

    module Quickshell.Hyprland
    ...
    import Quickshell.Hyprland._Ipc

and it is `Quickshell/Hyprland/_Ipc/quickshell-hyprland-ipc.qmltypes` that has
them. Grepping the public file alone says the feature does not exist. Grep the
whole tree.

| Type | Property | Where |
|---|---|---|
| `HyprlandWorkspace` | `urgent : bool`, readonly, `notify: urgentChanged` | `_Ipc/quickshell-hyprland-ipc.qmltypes:464-473`, plus a `updateUrgent` method at `:523` |
| `HyprlandToplevel` | `urgent : bool`, readonly, `notify: urgentChanged` | `_Ipc/quickshell-hyprland-ipc.qmltypes:362-371`, with `onActivatedChanged` at `:413` |
| `Windowset` (`Quickshell.WindowManager`) | `urgent : bool`, readonly | `WindowManager/quickshell-windowmanager.qmltypes:126-135` |

Three things follow.

**The rollup is already done.** Quickshell tracks the flag on the toplevel,
maps address to workspace itself, and publishes `urgent` on the workspace. So
the address-to-workspace bookkeeping the raw event would need is not work
anybody has to do. `Hyprland.rawEvent` does exist —
`_Ipc/quickshell-hyprland-ipc.qmltypes:152-155`, signalling a `HyprlandEvent`
with `name` and `data` — and it is the escape hatch, but it is not needed here.

**Clearing is already done too.** `HyprlandToplevel` has an `onActivatedChanged`
slot and `HyprlandWorkspace` an `updateUrgent`, so activating the window drops
the flag and the workspace recomputes. Nothing in this shell has to hold a
per-workspace bit or decide when to release it. Verified live in §5.

**There is a compositor-agnostic route as well.** `Quickshell.WindowManager`'s
`Windowset.urgent` is the same flag off `ext-workspace-v1`, which is the one
noctalia uses when it is not on Hyprland. Not needed here, but it means this is
not a Hyprland-only idea — it is the Wayland-level concept he thought it was.

## 3. Who else does it

Sixteen projects read: noctalia v4 and the fifteen clones. **Six implement
workspace urgency.** So it is a minority, but a well-populated one, and every
one of them reaches for a red.

| Project | file:line | The mark | Source of truth |
|---|---|---|---|
| noctalia v4 | `NOCT4/Modules/Bar/Extras/WorkspacePill.qml:85-96` | ground `Color.mError` | `Services/Compositor/HyprlandService.qml:266` — `"isUrgent": ws.urgent === true` |
| noctalia v4 | `NOCT4/Modules/Bar/Extras/WorkspacePill.qml:129-140` | *and* the label `Color.mOnError` | same |
| noctalia v4, grouped mode | `NOCT4/Modules/Bar/Widgets/Workspace.qml:881-889` and `:950-958` | the same pair again — ground `mError`, label `mOnError` | `Modules/Bar/Widgets/Workspace.qml:358` |
| noctalia v4, other compositors | `NOCT4/Services/Compositor/ExtWorkspaceService.qml:74` and `:133` | — | `ws.urgentChanged.connect(...)` on `Quickshell.WindowManager` — the generic `ext-workspace-v1` route |
| noctalia v4, Sway / Niri / Mango | `SwayService.qml:309`, `NiriService.qml:117`, `MangoService.qml:109` | — | one `isUrgent` field fed from four different compositors |
| Brainitech/Brain-Shell | `src/modules/Left/Workspaces.qml:123`, `:132`, `:140-165` | dot goes `Theme.wsUrgent` (`#fa6b94`, `src/theme/Colors.qml:27`) **and pulses scale 1.0 to 1.35 on a 400ms loop** | `ws.urgent` |
| doannc2212 | `bar/Bar.qml:158`, `:167`, `:174-183` | ground **blinks** `accentRed` on a 500ms `SequentialAnimation` driving a `urgentBlink` bool | `modelData.urgent` |
| diinki/linux-retroism | `configs/quickshell/taskbar/Workspaces.qml:66-68` | ground `Config.colors.urgent` (`#ff723e` to `#e83939` per theme, `Config.qml:19-63`) | `modelData.urgent` |
| diinki/linux-antiquity | `configs/quickshell/taskbar/Workspaces.qml:44-46` | same, one urgent colour across five themes (`Config.qml:19-153`) | `modelData.urgent` |
| josecriane | `modules/bar/components/Workspaces.qml:58` | plumbed into the model as `isUrgent` | `ws.is_urgent` — snake_case, so this is **Niri's** IPC field, not Hyprland's |

Nine of the fifteen clones do not implement it at all: bjarneo, corecathx,
Gakuseei, liixini x2, maxchennn, myamusashi, Rexcrazy804, shub39. tripathiji
matches on `urgent` but it is *notification* urgency in the control centre
(`modules/controlcenter/sections/NotificationsSection.qml:18`), a different
thing entirely.

Two findings from the table:

- **Everybody puts it in the ground, and nobody borders.** That is the opposite
  of what waybar does, and it is the choice this shell cannot copy — see §4.
- **Two of six animate it, and both animate it forever.** Brainitech pulses the
  scale on an infinite loop; doannc2212 blinks the fill on an infinite loop.
  `warning-states.md` already argued the case against a permanent pulse for the
  metric washes and it applies here unchanged: a mark that never settles is a
  mark you learn to stop seeing, and this one already has a natural end — you
  go to the workspace and it is gone.
- Both of the two that animate also guard on `!focused`
  (`Brain-Shell/.../Workspaces.qml:142`, `Bar.qml:175`). Both had the same
  problem this shell has, and both solved it the same way.

## 4. Why the ground is the one channel this shell cannot use

`pill-bounds.md` settled four rungs of one ink, and its whole argument was that
each rung has to clear the one below it on all nine palettes. Reprinted from
`urgent-mark.qml`, unchanged by anything here:

| | Tokyo Night | Gruvbox | Catppuccin | Gruvbox Light | Rosé Pine Dawn | Nord | Rosé Pine | Everforest | Kanagawa |
|---|---|---|---|---|---|---|---|---|---|
| idle `a(dim,.12)` | 5.2 | 4.6 | 4.4 | 4.5 | 4.8 | 3.6 | 5.9 | 3.7 | 3.1 |
| hover `a(dim,.22)` | 9.4 | 8.4 | 8.0 | 8.4 | 8.9 | 6.6 | 10.7 | 6.8 | 5.6 |
| focus `a(acc,.30)` | 16.4 | 15.0 | 16.6 | 12.7 | 11.1 | 14.8 | 19.0 | 14.2 | 13.1 |
| focus+hover `a(acc,.40)` | 21.5 | 19.9 | 21.8 | 16.9 | 14.8 | 19.6 | 25.0 | 18.7 | 17.3 |

Urgency is only ever drawn on a pill that is **not** focused — going there is
what clears it — so the rung it would have to clear is the hover, at 5.6 to
10.7 dL. Five alphas of `Theme.bad` as a ground, minus the hover rung
(`OVRHOV`, so a negative number means the urgent pill would be *dimmer* than a
merely hovered one):

| ground | Tokyo Night | Gruvbox | Catppuccin | Gruvbox Light | Rosé Pine Dawn | Nord | Rosé Pine | Everforest | Kanagawa | worst |
|---|---|---|---|---|---|---|---|---|---|---|
| `a(bad,.20)` | +0.7 | −1.9 | +2.1 | +3.2 | −0.8 | −2.1 | −0.8 | −0.1 | −2.5 | **−2.5** |
| `a(bad,.30)` | +5.7 | +1.8 | +7.1 | +8.9 | +3.3 | +0.3 | +4.2 | +3.3 | −0.3 | **−0.3** |
| `a(bad,.38)` | +9.7 | +4.8 | +11.1 | +13.4 | +6.6 | +2.3 | +8.1 | +6.1 | +1.7 | +1.7 |
| `a(bad,.48)` | +14.7 | +8.7 | +16.0 | +18.8 | +10.7 | +4.7 | +12.9 | +9.6 | +4.5 | +4.5 |

Lightness is the wrong instrument for a hue change, though, and the honest
question is not "is it lighter" but "could it be mistaken for the pill next to
it". That is a Lab distance, and `urgent-mark.qml` prints dE76 — the crude
euclidean one, deliberately, because dE2000's corrections shrink large
differences in saturated colour and shrinking flatters this design. About 2.3
is the just-noticeable difference; 10 is "obviously not the same colour".

dE from the **focused** fill `a(acc,.30)`, which is the pill an urgent one sits
beside:

| ground | Tokyo Night | Gruvbox | Catppuccin | Gruvbox Light | Rosé Pine Dawn | Nord | Rosé Pine | Everforest | Kanagawa | min |
|---|---|---|---|---|---|---|---|---|---|---|
| `a(bad,.20)` | 20.1 | 21.0 | 16.2 | 25.8 | 7.5 | 17.0 | 13.0 | 18.3 | 25.4 | **7.5** |
| `a(bad,.30)` | 23.6 | 22.7 | 18.6 | 32.4 | 7.9 | 19.5 | 14.2 | 20.6 | 33.9 | **7.9** |
| `a(bad,.38)` | 27.6 | 26.3 | 21.8 | 38.6 | 10.5 | 22.2 | 17.2 | 23.4 | 41.2 | 10.5 |
| `a(bad,.48)` | 33.3 | 32.5 | 26.6 | 46.8 | 14.9 | 26.1 | 22.3 | 27.7 | 50.5 | 14.9 |
| **1px/2px border, solid `bad`** | **66.1** | **71.7** | **55.2** | **82.3** | **42.2** | **49.7** | **53.2** | **54.3** | **96.6** | **42.2** |

Rosé Pine Dawn is the scheme that decides this. Its accent is `#907aa9`, a
muted purple, and its `base08` is `#b4637a`, a muted rose — two washed pinks,
and at 30% over the same ground they land 7.9 apart, which is *noticeable but
not obvious*. Kanagawa decides the lightness column for the opposite reason:
`base08` is `#e82424`, pure red, which ties `a(dim,.22)` in L\* while being
completely unmistakable — which is exactly why both numbers are printed and
neither is trusted alone.

To clear both gates the ground has to go to `a(bad,.48)` or past it, and that
costs the label:

| the number's WCAG ratio | Tokyo Night | Gruvbox | Catppuccin | Gruvbox Light | Rosé Pine Dawn | Nord | Rosé Pine | Everforest | Kanagawa | worst |
|---|---|---|---|---|---|---|---|---|---|---|
| `bad` on `a(bad,.48)` | 2.4 | 2.1 | 2.3 | 2.1 | 2.0 | 1.6 | 2.3 | 1.9 | 1.9 | **1.6** |
| `bad` on `a(bad,.38)` | 2.9 | 2.4 | 2.7 | 2.5 | 2.3 | 1.8 | 2.8 | 2.1 | 2.1 | 1.8 |
| `dim` on `a(bad,.38)` | 2.1 | 2.3 | 1.7 | 1.9 | 2.4 | 2.0 | 2.5 | 1.8 | 1.9 | 1.7 |
| — the shipped precedent — | | | | | | | | | | |
| `accent` on focused `a(acc,.30)` | 3.3 | 3.1 | 3.3 | 2.6 | 2.3 | 2.9 | 3.8 | 2.8 | 2.7 | 2.3 |
| — the shipped design — | | | | | | | | | | |
| **`bad` on idle `a(dim,.12)`** | **4.7** | **3.3** | **4.7** | **4.4** | **3.1** | **2.2** | **4.4** | **3.0** | **2.4** | **2.2** |
| **`bad` on hover `a(dim,.22)`** | **4.1** | **2.9** | **4.1** | **3.9** | **2.7** | **1.9** | **3.7** | **2.7** | **2.2** | **1.9** |

A red number on a red ground is a red number you cannot read. Every ground
strong enough to be unambiguous drives its own label below the 2.3 the focused
pill has read at since it shipped; leave the ground alone and the same number
reads 1.9 to 4.7, at or above that precedent on eight of nine.

**So the ground is out — not on looks, on arithmetic.** Which is convenient,
because the ground is also the channel the ladder lives in, and the safest way
for a fifth state not to break a four-rung ladder is not to touch it.

## 5. The mark

**A 2px border in `Theme.bad`, and the number in `Theme.bad`. The ground does
not move.** `Workspaces.qml`:

```qml
readonly property bool alarm: modelData.urgent && !ws.here
...
border.width: ws.alarm ? 2 : 0
border.color: Theme.bad
...
color: ws.here ? Theme.accent : ws.alarm ? Theme.bad : Theme.dim
```

Four lines, and it is waybar's own mark — an edge and a label in the alarm
colour, no fill — transposed to a rail. The 2px comes from waybar's own
`border-top: 2px`, and from the focused marker beside it, which is already 2.

It is the loudest thing on the rail. dL against the ground 24.6-49.0; dE 42.2
to 96.6 from the focused fill and 45.9 to 91.4 from a hovered idle pill, against
a JND of 2.3. And in ink — dL times pixels covered, `pill-bounds.md`'s third
number, on the 44x24 pill:

| | Tokyo Night | Gruvbox | Catppuccin | Gruvbox Light | Rosé Pine Dawn | Nord | Rosé Pine | Everforest | Kanagawa | min-max |
|---|---|---|---|---|---|---|---|---|---|---|
| **2px border `bad` (256px)** | 12532 | 9612 | 12369 | 12163 | 10468 | 6308 | 12170 | 8854 | 6894 | **6308-12532** |
| 1px border `bad` (132px) | 6462 | 4956 | 6378 | 6272 | 5398 | 3253 | 6275 | 4565 | 3555 | 3253-6462 |
| left marker `bad` (26px) | 1273 | 976 | 1256 | 1235 | 1063 | 641 | 1236 | 899 | 700 | 641-1273 |
| the shipped ground `a(dim,.12)` (1056px) | 5480 | 4896 | 4661 | 4794 | 5105 | 3833 | 6246 | 3951 | 3231 | 3231-6246 |

The 2px border carries **1.9 to 2.0 times the ink of the entire shipped
ground**, in a quarter of the area. 1px was rejected on that row: it merely
ties the ground it is drawn around.

The left marker was the other candidate — it is the literal transposition of
waybar's edge rule, and it is the one waybar itself uses for `urgent`. It loses
twice. It is 641-1273 ink, a tenth of the border and a fifth of the ground, so
it is not a mark you see across a desk. And that slot is already the *focused*
pill's, so an urgent pill drawn there would read as a mis-coloured focused one —
which is the one confusion the dE column exists to prevent.

Three things it deliberately does not do:

- **It does not animate.** Two of the six prior implementations pulse forever;
  see §3. This one has an end condition already.
- **`border.width` carries the toggle, not `border.color`.** An `int` has no
  `ColorAnimation` to walk, so nothing here can fade a colour to or from
  `"transparent"` — which is transparent *black*, and the reason the hover fill
  above it is one hue at two alphas.
- **It costs no height.** A `Rectangle`'s border draws inside its bounds
  (`pill-bounds.md` §3 measured the same thing for its border designs), so the
  pill is the 24 it was, and the shell logged no new `MEASURE` line across the
  reload — `fixed` stays 595, `railWidth` 58.

`!ws.here` is not belt and braces. Hyprland clears urgency when the window is
activated and Quickshell recomputes the workspace flag, but the two arrive on
separate signals, and a frame in which both are true would put an alarm around
the pill you are standing on. It is also what both animating implementations
guard on. Proved by accident in §6.

## 6. Proof it fires, and proof it clears

No synthetic property pokes. Firefox was already running on workspace 3 and the
focus was on workspace 1 — his own example, a link handed to a browser that is
somewhere else.

    $ hyprctl activeworkspace -j | jq -r .id
    1
    $ firefox --new-tab about:blank &

socket 2, read directly with `nc -U .../.socket2.sock`:

    urgent>>5e1138b14a20
    urgent>>5e1138b14a20
    windowtitle>>5e1138b14a20
    windowtitlev2>>5e1138b14a20,Mozilla Firefox
    urgent>>5e1138b14a20
    urgent>>5e1138b14a20

`0x5e1138b14a20` is Firefox, on workspace 3. Focus never moved — the active
workspace was still 1 afterwards, which is `focus_on_activate: false` doing its
job. Firefox asks four times; the flag is idempotent.

The live shell, with a temporary `onAlarmChanged` probe in the pill (removed
before commit):

    ALARM ws=3 urgent=true here=false alarm=true

and the rail, with workspace 1 focused in Gruvbox's gold and workspace 3
carrying a 2px `base08` border and a red 3:

`urgent-on.png`.

Then the clear. `hyprctl dispatch workspace name:3`, and without any code in
this shell asking for it:

    ALARM ws=3 urgent=false here=false alarm=false

`urgent-cleared.png` — workspace 3 now gold and focused, no red anywhere on the
rail. Focus was put back on workspace 1.

**And the `!ws.here` guard proved itself unprompted.** A second trigger launched
Obsidian, which instead of raising its existing window on workspace 9 opened a
*new* window on workspace 1 — the focused one — and Hyprland duly marked it:

    urgent>>5e11393361d0
    $ hyprctl clients -j | jq '.[]|select(.address=="0x5e11393361d0")|.workspace.id'
    1

`urgent` went true on the workspace being looked at, and no `ALARM` line was
emitted and no border was drawn, because `alarm` never changed. That window was
closed again; it was not his.

## 7. What was nearly concluded, and was wrong

The first pass at this searched `Quickshell/Hyprland/quickshell-hyprland.qmltypes`
and `Quickshell/Wayland/*.qmltypes` for `urgent`, found nothing, and concluded
the property did not exist — that this would have to be built out of
`Hyprland.rawEvent`, a per-workspace flag held in QML, an address-to-workspace
map off `Hyprland.toplevels`, and a rule for when to release it.

All of that already exists in C++ and is three properties away. The public
`qmltypes` for a Quickshell module is not where its types are declared; the
`qmldir` re-exports a private `_Ipc` submodule and that is where they live.
Grep the whole `Quickshell/` tree, and grep it for the *concept* rather than
one module.
