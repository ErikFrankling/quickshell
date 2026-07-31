# Sparklines: what they are drawn with, and whether anyone labels the axis

Asked of every shell on disk that draws a *history* graph — a CPU, memory or
network curve over time, not an instantaneous ring or arc:

1. **What primitive** draws it — `Canvas`, a `ShaderEffect`, a C++ painted
   item, `QtGraphs`, or a `Repeater` of `Rectangle`s? Is `Canvas` deliberately
   avoided anywhere?
2. **Is there a Y axis** — a gridline, a tick, a printed maximum, any unit at
   all?
3. **How is the maximum chosen** — fixed per metric, autoscaled to the window's
   peak, or a sticky high-water mark?
4. **Can the time window be changed**, and by whom?
5. **What happens while the buffer is still filling** — does the curve stretch
   across the full width, or does it keep a fixed step and grow in from one
   edge?

Local clones are under
`/tmp/claude-1000/.../scratchpad/clones/` (abbreviated `CLONES/`); the noctalia
checkout is
`/home/erikf/.dotfiles/.claude/worktrees/notifications-dark-mode-fix-2b275e/noct4/`
(`NOCT4/`). Twenty-odd trees were opened; six draw a history graph at all. The
rest — `maxchennn`, `Gakuseei`, `Brainitech`, `Rexcrazy804`, `josecriane`,
`diinki`×2, `liixini`×2, `shub39`, `bjarneo`, `nucleus`, `marble`, and every
AGS/GTK tree including `waybar` and `eww` — draw rings, arcs and numbers only.
No GTK shell in these trees draws a sparkline.

---

## 1. The primitive

| # | Project | Primitive | Where |
|---|---------|-----------|-------|
| **0** | **OURS** | **`Canvas`, `onPaint`, defaults** | `Graph.qml` |
| 1 | noctalia | **`ShaderEffect`** over a data texture built from a `Repeater` of `Rectangle`s | `NOCT4/Widgets/NGraph.qml:174-231`, `Shaders/frag/graph.frag` |
| 2 | caelestia | **C++ `QQuickPaintedItem`** | `CLONES/../caelestia/plugin/src/Caelestia/Internal/sparklineitem.hpp:12`, `.cpp:15` |
| 3 | end-4 / dots-hyprland | `Canvas` | `end4/dots/.config/quickshell/ii/modules/common/widgets/Graph.qml:8` |
| 4 | corecathx/whisker | `Canvas` ×3 (fps, mem, cpu) | `CLONES/corecathx_whisker/components/FPSOverlay.qml:219,296,384` |
| 5 | tripathiji1312 | `Canvas` | `CLONES/tripathiji1312_quickshell/components/NetworkGraph.qml:6` |
| 6 | myamusashi | **`QtGraphs` `GraphsView`** + `AreaSeries` | `CLONES/myamusashi_vast-shell/Qml/Modules/Drawers/QuickSettings/Performances.qml:611,647` |

Three of six stayed on `Canvas`; two moved off it deliberately; one uses Qt's
own charting module. noctalia says why in the file: *"Data texture built from
Rectangles instead of Canvas"* (`NGraph.qml:166`), and its other canvases carry
matching caveats — *"Static canvas - drawn ONCE, then cached"*,
`renderStrategy: Canvas.Cooperative // Better performance than Threaded for
simple shapes`, `renderTarget: Canvas.FramebufferObject // GPU texture`
(`NBusyIndicator.qml:23-28`), and *"Completely disabled during scaling to avoid
expensive canvas redraws"* (`DesktopMediaPlayer.qml:76`).

**Nobody has written down that a `Canvas` graph flickers.** Of the four graphs
still drawn with one, exactly one sets a render hint at all —
`renderStrategy: Canvas.Threaded` (`NetworkGraph.qml:30`) — and that component
is dead code, registered in `qmldir` and never instantiated. No graph anywhere
sets `renderTarget`.

So `Canvas` is not the wrong primitive here, and the measurements agree: with
the panel repainting nine canvases per sample, 543 consecutive frames were
sampled with no dropped frame, and a rebuild forced at 60 Hz was captured six
times without ever catching a half-drawn graph. What was wrong was *how often
we threw the canvas away* — see the commit that added this file.

## 2. The Y axis

| # | Project | Gridlines | Printed maximum | Units |
|---|---------|-----------|-----------------|-------|
| **0** | **OURS, before** | **none** | **none** | **none** |
| **0** | **OURS, after** | **one, at the ceiling** | **yes, under it** | **`%` / `B/s` / `°C` / `rpm`** |
| 1 | noctalia | none | none | none — 12 % headroom instead (`NGraph.qml:38`) |
| 2 | caelestia | none | none | none (`"Collecting data..."` while empty, `NetworkCard.qml:94-100`) |
| 3 | end-4 | none | text above the graph: `"of %1"` → *"of 31.2 GB"* (`Resources.qml:97`) | that string |
| 4 | whisker | none | none | a `"fps"` caption (`FPSOverlay.qml:199`) |
| 5 | tripathiji | 3 dashed, **unlabelled** (`NetworkGraph.qml:22-24,51-64`) | none | none |
| 6 | myamusashi | axes exist and are switched **off** (`Performances.qml:636-645`) | none | none |

**Not one of the six labels its axis.** One prints a maximum as prose, one
draws unlabelled gridlines, one turns Qt's own axes off on purpose. Erik asked
for the thing none of them has.

## 3. How the maximum is chosen

- **Fixed per metric** — end-4 normalises to 0..1 before storing
  (`Graph.qml:38`); whisker uses 80 for fps and 100 for cpu
  (`FPSOverlay.qml:235,399`); myamusashi `max: 100`; noctalia 100 for cpu/mem.
- **Autoscaled to the window peak** — caelestia
  (`NetworkCard.qml:70`, floor `1024`), tripathiji (`localMax` with `*1.1`
  headroom, `NetworkGraph.qml:69-72`), whisker's memory chart
  (`Math.max(...root.memGraph)`, `:311`), noctalia's network with a **1 MB/s
  floor** (`SystemStatService.qml:172-181`).
- **Sticky high-water mark** — only noctalia, only for temperature, and it
  never decays (`SystemStatService.qml:110-114`).

Two of them soften the resulting jump rather than removing it: caelestia
animates the maximum (`Behavior on smoothMax`, `NetworkCard.qml:88-90`) and
noctalia lerps the scale on a 16 ms timer (`NGraph.qml:126-153`).

**Ours snaps instead.** A floor per metric, as noctalia and caelestia have, and
then the ceiling rounded *up* to a power of two for byte rates and to 1/2/5×10ⁿ
for counted ones. Animating a scale that changes on every sample is a way of
making a lie smooth; snapping means the axis usually does not change at all,
and when it does it lands on a number worth printing next to it. A ceiling of
"256K/s" is both the number the curve is drawn against and the number on the
label, because the label is derived from it.

## 4. Choosing the window

| # | Project | Window | Who can change it |
|---|---------|--------|-------------------|
| **0** | **OURS, after** | **whole / half / quarter of the buffer** | **Erik, on the panel** |
| 1 | noctalia | 1 min, hardcoded (`SystemStatService.qml:72`) | nobody |
| 2 | caelestia | 30 samples (`NetworkUsage.qml:25`) | nobody — though the *interval* has a slider (`ServicesPage.qml:114-118`) |
| 3 | end-4 | 60 samples (`Config.qml:459-462`) | config file |
| 4 | whisker | 60, hardcoded (`FPSOverlay.qml:545-551`) | nobody |
| 5 | tripathiji | 30 (`NetworkGraph.qml:10`) | nobody |
| 6 | myamusashi | 30 (`Performances.qml:574`) | nobody |

Nobody puts the window on the panel. end-4 puts the length in its config file
and caelestia puts the sample interval behind a slider in a settings page —
which this shell does not have and is not getting. Three presets beside the
label that prints the window is the smallest thing that answers the request:
the label *is* the control.

## 5. While the buffer is still filling

- **Fixed step, grow in from the right** — caelestia
  (`sparklineitem.cpp:37-38`: `stepX = w / (m_historyLength - 1)`, `startX = w -
  (len - 1) * stepX ...`), end-4 (`Graph.qml:26-27,33`, `alignment:
  Graph.Alignment.Right`), tripathiji (`NetworkGraph.qml:74-76,84`).
- **Fixed step, grow in from the left** — whisker (`step = width / 60`,
  `FPSOverlay.qml:236`), which then closes the fill to the right edge anyway
  and leaves a flat tail.
- **Never happens** — noctalia pre-fills the buffer with zeros
  (`SystemStatService.qml:70-71,81-87`).
- **Stretches** — myamusashi, via a sliding X axis that starts at
  `Math.max(0, counter - maxPoints)` (`Performances.qml:589-590`).

**Ours used to stretch** — `step = width / (v.length - 1)` — which re-scaled the
whole curve sideways on every sample until the buffer filled. That is the state
the panel is in for the two minutes after every config reload, which during
development is most of the time. It now does what caelestia, end-4 and
tripathiji all do: a step fixed at the window length, and a short history drawn
against the right edge.
