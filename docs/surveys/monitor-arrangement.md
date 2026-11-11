# Monitor arrangement GUIs on Hyprland: prior art survey

**The question:** how do existing tools let you drag monitors on a canvas (as in the
GNOME or KDE display settings) and then apply the result to Hyprland? What is the
smallest QML version that works for this shell on Hyprland 0.57, where the config
is Lua and `hyprctl keyword` is gone?

Researched 2026-11-11. Every snippet below was read from the raw file at the
default branch on that date. Line numbers refer to that revision. Hyprland facts
are taken from the `v0.57.1` tag and from the 0.57.1 stubs installed on this
machine. Two `hyprctl eval` replies were also checked live (read-only probes).

---

## 0. What Hyprland 0.57 actually provides (verified)

### `hl.monitor` spec: from the installed stubs

`/nix/store/…-hyprland-0.57.1/share/hypr/stubs/hl.meta.lua:639-663`

```lua
---@class HL.MonitorSpec
---@field bitdepth? integer|boolean
---@field cm? string
---@field disabled? boolean
---@field icc? string
---@field max_avg_luminance? integer|boolean
---@field max_luminance? integer|boolean
---@field min_luminance? number|boolean
---@field mirror? string
---@field mode? string
---@field output string
---@field position? string
---@field reserved? integer|HL.CssGap
---@field reserved_area? integer|HL.CssGap
---@field scale? string|number
---@field sdr_eotf? string
---@field sdr_max_luminance? integer|boolean
---@field sdr_min_luminance? number|boolean
---@field sdrbrightness? number|boolean
---@field sdrsaturation? number|boolean
---@field supports_hdr? integer|boolean
---@field supports_wide_color? integer|boolean
---@field transform? integer|boolean
---@field vrr? integer|boolean
```

`hl.meta.lua:947`: `---@field monitor fun(spec: HL.MonitorSpec): nil`. Reading goes
through `hl.get_monitors()`, `hl.get_monitor(sel)` and `hl.get_monitor_at(x, y)`
(lines 935-938). The `HL.Monitor` object has `x`, `y`, `width`, `height`,
`scale` and `transform` (lines 781-812). There is also an event,
`"monitor.layout_changed"` (line 17).

The wiki (`hyprwm/hyprland-wiki` `content/configuring/core/monitors/positioning.md:12,36-37`)
says the same thing:

```lua
hl.monitor({ output = "DP-1", mode = "1920x1080@120Hz", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "1920x1080@120Hz", position = "1920x0", scale = 1 })
```

> The position is calculated with the scaled (and transformed) resolution, meaning
> if you want your 4K monitor with scale 2 to the left of your 1080p one, you'd use
> the position `1920x0` for the second screen (3840 / 2).

### What `hl.monitor` does when evaluated at runtime: from the source

`src/config/lua/bindings/LuaBindingsConfigRules.cpp:1077-1135` (tag v0.57.1):

```cpp
    CMonitorRuleParser parser(output);

    const auto         existing = std::ranges::find_if(Config::monitorRuleMgr()->all(), [&output](const auto& rule) { return rule.m_name == output; });
    if (existing != Config::monitorRuleMgr()->all().end())
        parser.rule() = *existing;
    ... // each field applied over it; unknown field -> addError("hl.monitor: unknown field '...'")
    Config::monitorRuleMgr()->add(std::move(parser.rule()));
    Supplementary::refresher()->scheduleRefresh(Supplementary::REFRESH_MONITOR_STATES);
```

The field defaults are `mode = "preferred"`, `position = "auto"` and `scale = "auto"`
(same file, lines 81-87).

`src/config/shared/monitor/MonitorRuleManager.cpp:36-41,95-97,22-28`:

```cpp
void CMonitorRuleManager::add(CMonitorRule&& x) {
    std::erase_if(m_rules, [&x](const auto& e) { return e.m_name == x.m_name; });
    m_rules.emplace_back(std::move(x));
    scheduleReload();
}
...
    for (auto const& r : m_rules | std::views::reverse) {
        if (PMONITOR->matchesStaticSelector(r.m_name))
            return applyWlrOutputConfig(r);
    }
...
    m_listeners.preChecksRender = Event::bus()->m_events.render.preChecks.listen([this](PHLMONITOR m) {
        if (m_reloadScheduled)
            ensureMonitorStatus();
```

What follows from this:

1. **A runtime `hyprctl eval 'hl.monitor{…}'` applies live.** The rule is applied
   on the next frame (`ensureMonitorStatus`). The newest rule that matches an
   output wins, so an eval for `"DP-1"` beats a `"desc:…"` rule from the config.
2. **The merge happens only on an exact `output` string match.** If the config says
   `output = "desc:Dell Inc. DELL U2724DE"` and you eval `output = "DP-1"`, you get a
   *fresh* rule that starts from `mode = "preferred"` and `scale = "auto"`. So
   **always send `mode`, `scale` and `transform` along with `position`**. NibrasShell
   and displaywright do this, and NibrasShell explains why (section 6).
3. **A wlr-output-management client wins over rules.** `applyWlrOutputConfig`
   (lines 44-80) overwrites mode, position, transform, scale and vrr with whatever a
   wlr-output-management client last committed for that output. That state is kept
   per client binding (`src/protocols/OutputManagement.cpp:644-650`, `m_monitorStates`),
   and kanshi stays bound for the whole session. **So on a host that runs kanshi, an
   `hl.monitor` eval for an output that kanshi configured does nothing**:
   `ensureMonitorStatus` sees the same rule (kanshi's override) and skips it. This
   machine (samsung-ablo) runs `kanshi.service`, and its profiles set `position`
   for the Dell and AGENT-1 (`~/.dotfiles/hosts/samsung-ablo/home.nix:93-127`). The
   framework does too. I read this from the source and did not test it live. It
   matches the aphotic-hypr report in section 9, which says the eval "registers the
   rule without actually re-applying it".
4. **`hyprctl reload` drops every eval'd rule.** The config is re-run. Anything you
   want to keep has to be in a file that the config `require`s.

### `hyprctl eval` replies: checked live on this machine

```
$ hyprctl eval 'return 1'            ->  ok                       (exit 0)
$ hyprctl eval 'hl.nosuchfn()'       ->  error: [string "return hl.nosuchfn();"]:1:
                                         attempt to call a nil value (field 'nosuchfn')   (exit 7)
```

So the check is **reply `== "ok"`**. The exit code is also non-zero on a Lua error.
displaywright's comment says "hyprctl exits 0 either way", but that describes the
legacy `keyword` refusal path, not `eval`. The `hyprctl -j monitors all` output
here includes the headless agent output
`{"name":"AGENT-1","description":"","make":"",…,"x":10000}`, so a canvas must
filter it out, or the bounding box becomes 10000 px wide.

### Quickshell 0.3.2 side

`quickshell-hyprland-ipc.qmltypes`: `HyprlandMonitor` exposes `id, name, description, x, y,
width, height, scale` and `lastIpcObject`. `transform`, `refreshRate`,
`availableModes` and `mirrorOf` are only available through `lastIpcObject`. `Hyprland`
has `usingLua`, `refreshMonitors()` and `dispatch()`. There is no `eval` wrapper,
so apply with `Process { command: ["hyprctl", "eval", lua] }`.

---

## 1. Summary table

| # | Implementation | Kind | Reads monitors | Drag | Snap / glue | Logical size | Applies with | Persists |
|---|---|---|---|---|---|---|---|---|
| 1 | AvengeMedia/DankMaterialShell | QML shell | wlr-output-management (own Go daemon) + `Hyprland.monitors` | `MouseArea drag.target` | 4 candidates per axis, 200 px, then overlap fallback | `phys/scale`, rotation swap | writes `~/.config/hypr/dms/outputs.lua` + `hyprctl reload` | that file + `monitors.json` profiles, auto-applied on hotplug |
| 2 | ilyamiro MonitorPopup.qml (30+ copies, e.g. Devvvmn/ActivSpot) | QML popup | `hyprctl monitors -j` | `MouseArea` on an invisible "ghost" | **perimeter glue**: always touches a neighbour | `res/scale`, **no rotation** | `hyprctl --batch 'keyword monitor …'` | awk-rewrites `monitor=` lines in `hyprland.conf` |
| 3 | BlackKingBarOrg/displaywright-shell-plugin | QML (Omarchy plugin) | `hyprctl -j monitors all` | `MouseArea`, anchored press, frozen zoom | 5 candidates per axis + push-out + island check | `phys/scale`, rotation swap | **`hyprctl eval "hl.monitor(…); …"`**, falls back to `--batch keyword` | managed block in `~/.config/hypr/monitors.lua`; 15 s keep/revert |
| 4 | doannc2212/quickshell-config monitor-manager | QML app | `hyprctl -j monitors all` + `rawEvent` | `MouseArea drag.target` with min/max | on release: 3 candidates per axis + overlap resolve | `transform%2` swap, `/scale` | `hyprctl --batch keyword monitor` (fails on Lua) | `monitors.conf` or `monitors.lua`, detects `require("monitors")` |
| 5 | AxOS-project/Sleex | QML + C++ plugin | Hyprland socket from C++ | **`DragHandler`** (`target: null`) | magnetic, 18 px, guide lines | **physical px (bug)** | socket `keyword monitor` | `~/.config/sleex/monitors.lua` |
| 6 | AhmedSaadi0/NibrasShell | QML shell | `hyprctl monitors all -j` | none: left/right/above/below buttons | uses Hyprland `auto-right` etc. | delegated to Hyprland | **`hyprctl eval hl.monitor({…})`** | runtime only |
| 7 | ilyamiro/serpantinum | QML settings | `hyprctl monitors all -j` | none (power/scale only) | none | — | `hyprctl eval 'hl.monitor…' \|\| keyword` | via its Config |
| 8 | nwg-piotr/nwg-displays | GTK3 Python | Hyprland socket `j/monitors all` | GTK motion events | edge lines, 10 px snap grid | `phys/scale`, rotation swap | writes `monitors.conf` **and** `monitors.lua`, `hyprctl reload` | those files + profiles |
| 9 | erans/hyprmon | Go TUI | `hyprctl -j monitors` | mouse in the terminal | edges/centres, guides | `PxW/Scale`, rotation swap | **`hyprctl eval <hl.monitor>`** per monitor on Lua | `monitors.lua` + `require` line |
| 10 | ToRvaLDz/monique | GTK4 Python | Hyprland socket | `GestureDrag` | 12 px / zoom | rotation swap | writes conf/lua, `reload` (plus a live keyword path) | profiles + `moniqued` hotplug daemon + optional **kanshi config export** |

There is no arrangement GUI in **end-4/dots-hyprland** (it only ships `hyprland.lua`),
**caelestia-dots/shell** (`services/Hypr.qml` only reads `Hyprland.monitors`) or
**noctalia** (now C++, no QML). No QML for it turned up in **HyDE** either. The
code-search API hit its rate limit before I could check whether HyDE calls
nwg-displays. **Ax-Shell** has `utils/monitor_manager.py` and `hyprland_monitor.py`,
but the names suggest focus tracking. I did not read them.

---

## 2. AvengeMedia/DankMaterialShell: the most complete

Files (branch `master`):
`quickshell/Modules/Settings/DisplayConfig/MonitorCanvas.qml`, `MonitorRect.qml`,
`DisplayConfigState.qml`, `quickshell/Common/OutputModel.js`,
`quickshell/Services/HyprlandService.qml`, `quickshell/Services/WlrOutputService.qml`,
`quickshell/Modals/DisplayConfirmationModal.qml`, `core/internal/config/embedded/hypr-outputs.lua`.

**1. Reading.** The main source is wlr-output-management through DMS's own Go
daemon (`WlrOutputService.qml`, `DMSService.sendRequest("wlroutput.getState")`,
lines 70-83). Hyprland extras come from `Hyprland.monitors`.
`HyprlandService.qml:447-462` re-reads when any `lastIpcObject` changes:

```qml
    function _syncMonitorLayout() {
        const signature = Hyprland.monitors.values.map(m => `${m.name}:${m.x},${m.y},${m.scale},${m.lastIpcObject?.transform ?? 0}`).join("|");
        if (signature === _monitorLayoutSignature)
            return;
        _monitorLayoutSignature = signature;
        monitorLayoutChanged();
    }
    Instantiator {
        model: CompositorService.isHyprland ? Hyprland.monitors : null
        delegate: QtObject {
            required property HyprlandMonitor modelData
            readonly property var monitorLastIpcObject: modelData.lastIpcObject
            onMonitorLastIpcObjectChanged: root._syncMonitorLayout()
        }
    }
```

**2. Canvas.** `MonitorCanvas.qml:76-84` fits the bounding box:

```qml
        property real scaleFactor: {
            if (bounds.width === 0 || bounds.height === 0)
                return 0.1;
            const padding = Theme.spacingL * 2;
            const scaleX = (width - padding) / bounds.width;
            const scaleY = (height - padding) / bounds.height;
            return Math.min(scaleX, scaleY);
        }
        property point offset: Qt.point((width - bounds.width * scaleFactor) / 2 - bounds.minX * scaleFactor, (height - bounds.height * scaleFactor) / 2 - bounds.minY * scaleFactor)
```

`MonitorRect.qml:24-27,103-158` uses `MouseArea drag.target` and holds `x`/`y` steady
while dragging (`x: isDragging ? x : …`). It computes a snapped position, draws it
as an outline (`snapPreview`, lines 57-69) and commits on release:

```qml
        drag.target: root.isConnected ? root : null
        drag.threshold: 0
        onPositionChanged: mouse => {
            let posX = Math.round((root.x - root.canvasOffset.x) / root.canvasScaleFactor);
            let posY = Math.round((root.y - root.canvasOffset.y) / root.canvasScaleFactor);
            const size = DisplayConfigState.getLogicalSize(root.outputData);
            const snapped = SettingsData.displaySnapToEdge ? DisplayConfigState.snapToEdges(root.outputName, posX, posY, size.w, size.h) : Qt.point(posX, posY);
            root.snappedLogical = snapped;
            root.isValidPosition = SettingsData.displaySnapToEdge ? !DisplayConfigState.checkOverlap(root.outputName, snapped.x, snapped.y, size.w, size.h) : true;
        }
```

Snapping, `OutputModel.js:971-1044`. For each neighbour and axis it tries four
candidates: attach after, attach before, align start and align end. The threshold
is 200 logical px. Then it falls back to the overlap check:

```js
function axisSnaps(edge, extent, pos, testExtent) {
    const far = edge + extent;
    const testFar = pos + testExtent;
    return [
        { "val": far,                 "dist": Math.abs(pos - far) },
        { "val": edge - testExtent,   "dist": Math.abs(testFar - edge) },
        { "val": edge,                "dist": Math.abs(pos - edge) },
        { "val": far - testExtent,    "dist": Math.abs(testFar - far) }
    ];
}
function snapToEdges(layout, testName, posX, posY, testW, testH) {
    const snapThreshold = 200;
    ... // nearestSnap over every neighbour, x and y independently
    if (!checkOverlap(layout, testName, snappedX, snappedY, testW, testH)) return { x: snappedX, y: snappedY };
    if (!checkOverlap(layout, testName, snappedX, posY, testW, testH))     return { x: snappedX, y: posY };
    if (!checkOverlap(layout, testName, posX, snappedY, testW, testH))     return { x: posX, y: snappedY };
    return { x: posX, y: posY };
}
```

**3. Logical size.** `OutputModel.js:861-914`: physical size comes from the current
mode. 90/270 and the flipped variants swap it, then it is divided by scale.
Rounding depends on the compositor (niri uses `ceil`, everything else `round`).
`recalculateAdjacentPositions` (lines 1046-1084) keeps a right-hand neighbour glued
when the scale changes.

**4. Apply.** `HyprlandService.qml:314-425` writes one `hl.monitor` line per output
to `~/.config/hypr/dms/outputs.lua` and runs `hyprctl reload`:

```js
            const parts = [`output = ${luaQuoted(identifier)}`, `mode = ${luaQuoted(resolution)}`, `position = ${luaQuoted(geometry.position)}`, `scale = ${scale}`];
            const transform = OutputModel.transformIndex(output.logical?.transform ?? "Normal");
            if (transform !== 0)
                parts.push(`transform = ${transform}`);
            ...
            lines.push("hl.monitor({ " + parts.join(", ") + " })");
        }
        lines.push('hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })');
...
        Proc.runCommand("hyprctl-reload", ["hyprctl", "reload"], ...
```

Scale is written as an exact n/120 fraction (`hyprlandScaleValue`, OutputModel.js:350-360:
"Hyprland snaps to the nearest n/120 itself").
`DisplayConfirmationModal.qml:11-38` gives a 10 s countdown that reverts unless
you confirm.

**5. Persistence and hotplug.** The file above is required by DMS's generated
`hyprland.lua`. Profiles live in `~/.config/DankMaterialShell/monitors.json`
(DisplayConfigState.qml:84) and are keyed by a fingerprint of the connected output
set. `onOutputsChanged` (lines 787-799) restarts `autoSelectDebounceTimer`, which
applies the matching profile. That makes DMS a kanshi replacement. It does not
coordinate with a running kanshi.

---

## 3. ilyamiro MonitorPopup.qml: the most copied popup (30+ forks)

The catalogue's `ilyamiro/nixos-configuration` no longer has this file. Its tree now
holds `compositors/hyprland/config/monitors.lua`, and the successor project
`ilyamiro/serpantinum` has no canvas (section 8). The copy read here is
`Devvvmn/ActivSpot` `scripts/quickshell/monitors/MonitorPopup.qml` (1184 lines). Code
search finds the same file in 30+ dotfiles repos.

**1. Reading.** `MonitorPopup.qml:202-240`: a `Process` runs `hyprctl monitors -j`.
Positions are normalised to the minimum and multiplied by `uiScale: 0.10` (line 51).

**2. Canvas.** All tiles sit inside one `Item { id: transformNode; scale: targetScale;
transformOrigin: Item.TopLeft }` (lines 544-550), so tile coordinates stay
"virtual" (layout × 0.1) and the container does the zoom. The drag uses a hidden
**ghost**. The `MouseArea` drags an invisible `Item`, and the visible card only
moves to the snapped position, with a `Behavior` animation (lines 620-705):

```qml
    Item {
        id: ghostDrag
        x: model.uiX; y: model.uiY
        width: monitorCard.width; height: monitorCard.height
        MouseArea {
            anchors.fill: parent
            drag.target: ghostDrag
            onPositionChanged: {
                ... // clamp ghost to the others' bounding box +40
                for (let j = 0; j < monitorsModel.count; j++) {
                    if (j === index) continue;
                    let snapped = window.getPerimeterSnap(ghostDrag.x, ghostDrag.y,
                                    sModel.uiX, sModel.uiY, sW, sH, mW, mH, 20);
                    ... // keep nearest
                }
                if (!window.isOverlappingAny(bestX, bestY, mW, mH, index)) {
                    monitorsModel.setProperty(index, "uiX", bestX);
                    monitorsModel.setProperty(index, "uiY", bestY);
                }
            }
            onReleased: { ghostDrag.x = model.uiX; ghostDrag.y = model.uiY; }
        }
    }
```

**Edge gluing.** `MonitorPopup.qml:118-150` clamps the pointer onto the nearest of
the four perimeter lines of a neighbour, so the result always touches. On the free
axis it then snaps to the start, end or centre alignment:

```js
    function getPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT) {
        let edges = [
            { x1: sX - mW, x2: sX + sW, y1: sY - mH, y2: sY - mH }, // Top Edge
            { x1: sX - mW, x2: sX + sW, y1: sY + sH, y2: sY + sH }, // Bottom Edge
            { x1: sX - mW, x2: sX - mW, y1: sY - mH, y2: sY + sH }, // Left Edge
            { x1: sX + sW, x2: sX + sW, y1: sY - mH, y2: sY + sH }  // Right Edge
        ];
        let bestX = pX, bestY = pY, minDist = 999999;
        for (let i = 0; i < 4; i++) {
            let e = edges[i];
            let cx = Math.max(e.x1, Math.min(pX, e.x2));
            let cy = Math.max(e.y1, Math.min(pY, e.y2));
            if (Math.abs(cx - sX) < snapT) cx = sX;
            if (Math.abs(cx - (sX + sW - mW)) < snapT) cx = sX + sW - mW;
            if (Math.abs(cx - (sX + sW/2 - mW/2)) < snapT) cx = sX + sW/2 - mW/2;
            if (Math.abs(cy - sY) < snapT) cy = sY;
            if (Math.abs(cy - (sY + sH - mH)) < snapT) cy = sY + sH - mH;
            if (Math.abs(cy - (sY + sH/2 - mH/2)) < snapT) cy = sY + sH/2 - mH/2;
            let dist = Math.hypot(pX - cx, pY - cy);
            if (dist < minDist) { minDist = dist; bestX = cx; bestY = cy; }
        }
        return { x: bestX, y: bestY };
    }
```

**3. Logical size.** `(resW / sysScale) * uiScale`. It **ignores transform**, so a
rotated monitor is drawn wrong.

**4. Apply.** Lines 1088-1180: a second "tight snap" pass with a 25 px threshold
closes rounding gaps, everything is normalised so the minimum is 0×0, and then:

```js
    batchCmds.push("keyword monitor " + monitorStr);   // name,WxH@rate,XxY,scale
    let fullCommand = "hyprctl --batch '" + batchCmds.join(" ; ") + "'";
    Quickshell.execDetached(["sh", "-c", fullCommand + " ; " + saveCmd + " ; " + postReloadCmd]);
```

**This does not work on 0.57 Lua.** `keyword` is refused.

**5. Persistence.** `saveCmd` uses `awk` to replace the `monitor=` lines in
`~/.config/hypr/hyprland.conf`. There is no hotplug or kanshi handling.

---

## 4. BlackKingBarOrg/displaywright-shell-plugin: the cleanest Lua-era code

An Omarchy shell plugin (MIT, last pushed 2026-09). Files: `Arrange.qml`,
`ArrangeCanvas.qml`, `lib/snapping.mjs`, `lib/geometry.mjs`, `lib/luawriter.mjs`,
`lib/applyflow.mjs`. The pure logic lives in `.mjs` files so it can be unit-tested
outside Quickshell (`tests/`).

**1. Reading.** `Arrange.qml:108-133`: `hyprctl -j monitors all`, mapped through
`geo.stateFromHyprctl`.

**2. Canvas.** `ArrangeCanvas.qml:33-61`. The zoom is **frozen during a gesture**:

```qml
  // Dragging a display changes the bounding box, which changes the zoom, which
  // moves every tile including the one under the cursor -- so the tile does not
  // track the pointer and the drag fights back. The transform is frozen for the
  // length of a gesture and recomputed when it ends.
  readonly property real liveZoom: {
    const usableW = Math.max(width - 2 * padding, 40)
    const usableH = Math.max(height - 2 * padding, 40)
    return Math.min(usableW / Math.max(box.w, 1), usableH / Math.max(box.h, 1), maxZoom)
  }
  readonly property real zoom: interacting ? heldZoom : liveZoom
```

The drag (lines 187-236) is a plain `MouseArea` without `drag.target`. The press
point is stored in **canvas** coordinates and the tile's logical origin at press is
also stored. The comment explains why:

```qml
        // Where the display was when the drag began, and where the pointer was
        // in the canvas's own coordinates. Both have to be anchored: measuring
        // each event against the *current* position compounds the movement,
        // and measuring in the tile's coordinates measures against a frame
        // that is itself moving. Together they turned a 300px gesture into
        // 1555px of travel.
        onPositionChanged: function (mouse) {
          var p = mapToItem(view, mouse.x, mouse.y)
          var wanted = { x: originX + (p.x - pressX) / view.zoom,
                         y: originY + (p.y - pressY) / view.zoom,
                         w: tile.rect.w, h: tile.rect.h }
          var result = view.snap.snapAndResolve(wanted, others)
          tile.state.x = result.x
          tile.state.y = result.y
        }
```

Snapping, `lib/snapping.mjs:13-80`. Five candidates per axis, each axis snapped on
its own with `SNAP_THRESHOLD = 120` logical px. Then any overlap is pushed out
along the cheapest axis:

```js
function candidates(size, others, axis) {
  const out = []
  for (const o of others) {
    const lo = axis === "x" ? o.x : o.y
    const hi = axis === "x" ? rectRight(o) : rectBottom(o)
    const oSize = axis === "x" ? o.w : o.h
    const center = lo + oSize / 2
    out.push([hi, hi])                            // attach after
    out.push([lo - size, lo])                     // attach before
    out.push([lo, lo])                            // align leading edges
    out.push([hi - size, hi])                     // align trailing edges
    out.push([center - size / 2, center])         // align centres
  }
  return out
}
export function pushOut(moving, others) {
  let { x, y } = moving
  for (let i = 0; i <= others.length; i++) {
    const current = { x: x, y: y, w: moving.w, h: moving.h }
    const hit = others.find(o => rectsOverlap(current, o))
    if (!hit) break
    const options = [
      [rectRight(hit) - current.x, [rectRight(hit), y]],
      [rectRight(current) - hit.x, [hit.x - current.w, y]],
      [rectBottom(hit) - current.y, [x, rectBottom(hit)]],
      [rectBottom(current) - hit.y, [x, hit.y - current.h]],
    ]
    const best = options.reduce((a, b) => (b[0] < a[0] ? b : a))
    x = best[1][0]; y = best[1][1]
  }
  return [Math.round(x), Math.round(y)]
}
```

`validate()` (lines 124-171) reports overlaps, "islands" (displays that do not
touch: "the pointer cannot reach …") and bad mirrors.

**3. Logical size.** `lib/geometry.mjs:173-178`: `pixelSizeRotated(state)` swaps for
the odd transforms, then divides by scale.

**4. Apply.** `Arrange.qml:136-170`. Everything goes in one `hyprctl eval` with
`;`-joined `hl.monitor` calls. If the reply looks like an error, it falls back to
`hyprctl --batch "keyword monitor …"`:

```qml
    applyProc.command = ["bash", "-c",
      'out=$(hyprctl eval "$1" 2>&1); low=${out,,}; '
      + 'case "$low" in '
      + '*error*|*non-legacy*|*"unknown request"*|*"invalid dispatcher"*) '
      + 'hyprctl --batch "$2" >/dev/null 2>&1 ;; '
      + 'esac',
      "displaywright", luaText, legacy]
```

`lib/luawriter.mjs:36-49` builds the rule. It always includes mode, position and
scale, so a fresh rule never falls back to `preferred`/`auto`:

```js
export function renderCall(state) {
  const fields = [`output = ${luaString(state.name)}`]
  if (!state.enabled) {
    fields.push("disabled = true")
  } else {
    fields.push(`mode = ${luaString(state.mode ? modeHypr(state.mode) : "preferred")}`)
    fields.push(`position = ${luaString(`${state.x}x${state.y}`)}`)
    fields.push(`scale = ${trimNumber(state.scale)}`)
    if (state.transform) fields.push(`transform = ${state.transform}`)
    if (state.mirrorOf) fields.push(`mirror = ${luaString(state.mirrorOf)}`)
    if (state.vrr !== null && state.vrr !== undefined) fields.push(`vrr = ${state.vrr}`)
  }
  return `hl.monitor({ ${fields.join(", ")} })`
}
```

`lib/applyflow.mjs` runs a 15 s keep-or-revert countdown. The revert is just
another apply of the snapshot.

**5. Persistence.** Only after **Keep** (`Arrange.qml:210-216`): `save()` (lines
400-408) writes a marker-delimited managed block in `~/.config/hypr/monitors.lua`
with `FileView.setText`. Existing `hl.monitor` calls outside the block are
commented out, and the rules of unplugged displays are carried over
(`luawriter.mjs:95-108`). No kanshi handling.

---

## 5. doannc2212/quickshell-config `monitor-manager/`

Files: `MonitorService.qml`, `MonitorCanvas.qml`, `MonitorTile.qml`, `MonitorUtils.qml`,
`MonitorManager.qml`.

**1. Reading.** `MonitorService.qml:162-205`: `hyprctl -j monitors all`. It resolves
`mirrorOf`, which is returned as an ID string. It refreshes on
`Hyprland.rawEvent` for `monitoradded`, `monitorremoved` and `configreloaded`
(lines 252-263), with a 250 ms debounce "for DisplayPort negotiation".

**2. Canvas.** `MonitorCanvas.qml:59-66,175-178`: same fit-to-box as DMS.
`MonitorTile.qml:114-131` uses `MouseArea { drag.target: root; drag.minimumX/maximumX… }`,
and snapping only runs **on release** (`MonitorCanvas.qml:252-337`):

```js
  function snapAndCommit(index, rawCanvasX, rawCanvasY) {
    let lx = (rawCanvasX - originX) / viewScale;
    let ly = (rawCanvasY - originY) / viewScale;
    const T  = 20;  // snap threshold in logical pixels
    ...
      if (!sx) {
        if      (Math.abs(lx      - (m.x + mW)) < T) { lx = m.x + mW; sx = true; }
        else if (Math.abs(lx + dW - m.x)         < T) { lx = m.x - dW; sx = true; }
        else if (Math.abs(lx      - m.x)         < T) { lx = m.x;      sx = true; }
      }
    ...
    // then: while overlapping, centre-to-centre direction decides left/right/above/below
    lx = Math.max(0, lx);  ly = Math.max(0, ly);
    canvas.monitorMoved(index, Math.round(lx), Math.round(ly));
  }
```

**3. Logical size.** `MonitorUtils.qml:6-13`:

```qml
    function logicalW(m) { return (m.transform % 2 === 0) ? m.width / m.scale : m.height / m.scale; }
    function logicalH(m) { return (m.transform % 2 === 0) ? m.height / m.scale : m.width / m.scale; }
```

**4. Apply.** `MonitorService.qml:85-92`: `hyprctl --batch "keyword monitor …"`. It
writes Lua for persistence (`buildMonitorLuaLine`, lines 58-67) but still applies
with `keyword`, so on Lua configs the live apply fails. `verifyApply`
(lines 105-120) re-reads afterwards and reports mismatches. That is a good idea.

**5. Persistence.** `persistToFile` (lines 94-103) writes `~/.config/hypr/monitors.lua`
or `.conf`. `sourceCheck` (lines 136-159) greps for `require("monitors")`, and the
UI says "Persistence disabled — add 'source = …'" when it is missing.

---

## 6. AxOS-project/Sleex: the only `DragHandler` implementation

Files: `src/share/sleex/modules/settings/displaySettings/DisplaySettings.qml`,
`modules/common/widgets/MonitorTile.qml`, `plugins/src/Sleex/services/monitors.cpp`.

**1. Reading.** C++ `Monitors` service talks to `.socket.sock`/`.socket2.sock`
directly (monitors.cpp:35-117).

**2. Canvas.** `DisplaySettings.qml:147-195` fits with `scaleF = min(sx, sy, 0.11)`.
`MonitorTile.qml:240-280` uses a **`DragHandler { target: null }`** and moves the
tile by hand from `translation`:

```qml
    DragHandler {
        id: dragHandler
        target: null
        onActiveChanged: {
            if (active) { tile.dragStartX = tile.x; tile.dragStartY = tile.y }
            else {
                const newRx = Math.round((tile.x - tile.canvasOffsetX) / tile.canvasScaleF + tile.canvasOrigin.x)
                const newRy = Math.round((tile.y - tile.canvasOffsetY) / tile.canvasScaleF + tile.canvasOrigin.y)
                tile.dragCommitted(tile.monitorInfo.name, newRx, newRy)
            }
        }
        onTranslationChanged: {
            let snapped = tile._performMagneticSnap(tile.dragStartX + translation.x, tile.dragStartY + translation.y)
            tile.x = snapped.x; tile.y = snapped.y
        }
    }
```

`_performMagneticSnap` (lines 283-332) snaps in **canvas px** (`snapThreshold: 18`)
against sibling tiles. On X it tries four targets, and on Y it adds vertical
centring. It emits guide-line positions for the parent to draw.

**3. Logical size. Bug:** `realWidth: monitorInfo.width` (lines 22-23) is
physical px, so a monitor at scale 2 is drawn twice as large as its layout
footprint.

**4. Apply.** monitors.cpp:183-200 sends `keyword monitor NAME,WxH@R,XxY,S` over the
socket. That fails on Lua.

**5. Persistence.** `saveMonitorsConfig` (monitors.cpp:480-525) writes
`~/.config/sleex/monitors.lua` with `hl.monitor({ … })` lines.

---

## 7. AhmedSaadi0/NibrasShell: eval done right, but no canvas

Files: `config/quickshell/windows/settings/monitors/MonitorsSettings.qml`, `MonitorItem.qml`.
There is no drag. "Place left/right/above/below" buttons hand the maths to
Hyprland's own `auto-*` positions (`MonitorsSettings.qml:132-144`).
`applyRule` (lines 83-109) is the clearest statement of the merge gotcha:

```js
    // `hyprctl keyword monitor` is rejected on Hyprland >= 0.56.
    // transform/vrr/mirror are always sent explicitly so partial edits
    // (resolution, scale, position) never reset rotation or VRR state.
    function applyRule(name, res, pos, scale, transform, vrr, mirror) {
        let lua = `hl.monitor({ output = "${name}"`;
        lua += `, mode = "${mode}"`;
        lua += `, position = "${position === "" ? "auto" : position}"`;
        ... scale, transform, vrr ...
        // (Arabic comment) always send it, even empty: hl.monitor merges with the
        // existing rule, and mirror = '' is the only way to clear a mirror.
        lua += `, mirror = "${String(mirror ?? "").trim()}"`;
        lua += " })";
        runCommand(["hyprctl", "eval", lua]);
    }
```

`MonitorItem.qml:512-517` handles enable/disable with
`hl.monitor({ output = "…", disabled = false/true })`. Changes are runtime only.

## 8. ilyamiro/serpantinum: eval with a keyword fallback (no canvas)

`src/quickshell/guide/display/DisplayMainState.qml:242-256` reads
`hyprctl monitors all -j || hyprctl monitors -j`. Lines 384-426 apply:

```js
            let luaCmd = 'hl.monitor({ output = "' + monName + '", mode = "' + modeStr + '", position = "auto", scale = ' + scaleVal.toString() + ' })';
            Quickshell.execDetached(["bash", "-c", "hyprctl eval '" + luaCmd + "' || hyprctl keyword monitor " + monName + "," + modeStr + ",auto," + scaleVal.toString()]);
```

The `||` fallback only works because `hyprctl eval` exits non-zero on a Lua error
or an unknown request, which matches the live probe in section 0.

## 9. Two negative data points (Lua era)

- `T-Crypt/aphotic-hypr` `Configs/quickshell/aphotic/modules/settings/panes/DisplaysPane.qml:27-37`
  went read-only: "`hyprctl eval 'hl.monitor({...})'` registers the rule without
  actually re-applying it live … `hyprctl reload` just re-reads monitors.lua's own
  static rule". The source (section 0, point 3) explains both halves. A
  wlr-output-management override (kanshi, or the like) stops the re-apply, and
  `reload` discards eval'd rules.
- `bjarneo/quickshell` `desktop/DisplayPopup.qml:155-156`: "Hyprland's lua parser
  refuses runtime `keyword monitor` ('Use eval.')". It opens
  `~/.config/hypr/monitors.lua` in an editor instead.

---

## 10. Non-QML tools

### nwg-piotr/nwg-displays (GTK3, Python)

- **Read:** `nwg_displays/tools.py:232-250` speaks to the socket directly
  (`j/monitors all`, lines 400-425).
- **Canvas:** `main.py:262-330` (`on_motion_notify_event`) collects snap lines from
  the left, right, top and bottom edges of the other displays. It snaps the
  dragged widget's leading or trailing edge within `snap_threshold_scaled`, after
  first rounding to a `SENSITIVITY` grid:

  ```python
        for value in snap_x:
            if abs(x - value) < snap_threshold_scaled:
                snap_h = value
                break
        for value in snap_x:
            w = widget.logical_width * config["view-scale"]
            if abs(w + x - value) < snap_threshold_scaled:
                snap_h = value - w
                break
  ```
- **Logical size:** `main.py:538-548`, `physical / scale`, swapped when `is_rotated`.
- **Apply:** `settings_applier/settings_applier.py:583-700`. It writes
  `~/.config/hypr/monitors.conf` **and** `monitors.lua`, with blocks of the form
  `hl.monitor({ output = …, mode = …, position = …, scale = … })`, then runs
  `hyprctl("reload")` and opens a confirm window. The restore (`main.py:1193-1203`)
  writes the backups back and waits for Hyprland to reload.
- **Persist:** the same files plus profiles (`profiles.py`). No kanshi.

### erans/hyprmon (Go TUI)

- `hyprland.go:327-344`: when the config format is Lua, each monitor is applied
  with `execHyprctl("eval", generateLuaMonitorRule(m))`. Lines 561-609 always
  include mode, position, scale and `disabled = false`.
- `models.go:177-187`, logical size: `PxW/Scale`, swapped for transforms 1, 3, 5
  and 7. `models.go:289-327`: snaps edges and centres within `SnapThresh`, with
  guides.
- `hyprland.go:703-760`: writes `monitors.lua` and appends a `require` line to
  `hyprland.lua` if it is missing (`ensureHyprmonLuaRequire`).

### ToRvaLDz/monique (GTK4, Python)

- `canvas.py:15,189-231`: `SNAP_DISTANCE = 12` screen px, converted with
  `threshold = SNAP_DISTANCE / self._zoom`. Edge and alignment targets.
- `hyprland.py:205-247`: writes the conf and/or Lua config, then `self.reload()`.
  `apply_profile_keyword` (lines 249-289) is a live `keyword monitor` path for
  legacy configs.
- **The only tool that is aware of kanshi:** `kanshi_config.py` writes every saved
  profile into one kanshi config, with the active one first (header: "kanshi
  reads a single file … picks the first profile whose outputs exactly match").
  It also ships `moniqued`, its own hotplug daemon listening on socket2
  `monitoradded`/`monitorremoved`.

### hyprland-guiutils / hyprdisplays

`hyprwm/hyprland-guiutils` `utils/` contains only `dialog`, `donate-screen`, `run`,
`update-screen` and `welcome`. There is no display tool in it. I found no
"hyprdisplays" repo, so monique is the closest match for that lead.

---

## 11. Recommendation for this shell

### The decisions

- **Window:** a full-screen `PanelWindow` overlay with a centred card, the same
  shape as `PowerWindow.qml`. This needs no new infrastructure.
- **Read:** one `Process { command: ["hyprctl", "-j", "monitors"] }` when the window
  opens. You could use `Hyprland.monitors` instead, but `transform` and
  `refreshRate` are only in `lastIpcObject`, and that arrives asynchronously after
  `refreshMonitors()`, so you would need an `Instantiator` (as DMS does) just to
  know when the data is ready. Filter out headless outputs
  (`description === ""` catches `AGENT-1` here) and mirrors.
- **Model:** a plain JS array in **logical** px, `{name, x, y, w, h, mode, scale,
  transform}`, with `w = (transform odd ? height : width) / scale`. Every tool that
  gets rotation right does this (DMS, displaywright, doannc, nwg-displays, hyprmon).
- **Canvas:** fit the bounding box to the view, and **freeze the box while a drag is
  held** (displaywright's lesson). The drag is a plain `MouseArea` that anchors the
  press point in the canvas's coordinates (displaywright again). Use
  `Repeater { model: mons.length }`: the model is an int, so assigning a new
  `mons` array mid-drag does not recreate the delegates.
- **Snap:** *glue*, so the moving monitor always touches a neighbour, which is
  ilyamiro's perimeter idea. Then align start, end or centre on the free axis
  within a threshold given in **screen** px (`16 / zoom`, as monique does). Reject
  any spot that overlaps another monitor. Gaps can never happen and no island
  validation is needed.
- **Apply:** a single `hyprctl eval` with `hl.monitor({…}); hl.monitor({…})`.
  **Always** send `mode`, `position`, `scale` and `transform`. Normalise to a 0,0
  minimum. Success means the reply is exactly `ok`. Re-read after ~300 ms so the
  canvas shows what Hyprland really did. If nothing moved, say so: on kanshi hosts
  that is the expected result.
- **Persistence:** none in the popup. `~/.config/hypr/hyprland.lua` is a
  read-only Home Manager store file here, and on the framework and samsung-ablo
  kanshi owns positions anyway. The durable home is the Nix config: the
  `hl.monitor` rules on the PC, and `services.kanshi` profiles on the laptops.
  The popup can show the Lua or kanshi line to paste. If file persistence is
  wanted later, the smallest step is a dotfiles change adding
  `pcall(dofile, os.getenv("HOME") .. "/.local/state/hypr/monitors.lua")` at the
  end of the generated `hyprland.lua`, with the popup writing that file through
  `FileView.setText`. That does nothing on kanshi hosts unless kanshi is dropped
  there.

### The file (227 lines; untested sketch, apply path checked against 0.57.1 source)

```qml
// DisplaysWindow.qml - drag monitors on a canvas, glue edges, apply live with
// `hyprctl eval 'hl.monitor{…}'` (Hyprland 0.57 Lua). Runtime only: a reload or
// a kanshi profile puts the declared layout back.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    property bool open: false
    visible: open
    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "displays"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }

    // Layout in Hyprland logical px: {name, x, y, w, h, mode, scale, transform}.
    // mode/scale/transform ride along so an eval'd rule never falls back to
    // mode = "preferred", scale = "auto" (a new `output` string is a fresh rule).
    property var mons: []
    property var live: []      // as read when the window opened; Revert target
    property var sent: null    // what the last Apply asked for, to detect a no-op
    property string status: ""

    function show() {
        status = ""; live = []; sent = null;
        reader.running = true;
        open = true;
        Qt.callLater(() => card.forceActiveFocus());
    }
    function hide() { open = false; }

    function bounds(list) {
        if (!list.length) return { x: 0, y: 0, w: 1920, h: 1080 };
        const x = Math.min(...list.map(m => m.x)), y = Math.min(...list.map(m => m.y));
        return { x, y,
                 w: Math.max(...list.map(m => m.x + m.w)) - x,
                 h: Math.max(...list.map(m => m.y + m.h)) - y };
    }

    function overlaps(a, b) {
        return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
    }

    // Glue r onto the nearest perimeter of any other monitor, then align the free
    // axis (start / end / centre) within t. Never returns an overlapping spot.
    // Adapted from ilyamiro MonitorPopup.qml getPerimeterSnap + an overlap reject.
    function glue(r, others, t) {
        let best = null;
        for (const o of others) {
            const sides = [                                   // [xMin, xMax, yMin, yMax] for r's top-left
                [o.x - r.w, o.x + o.w, o.y - r.h, o.y - r.h], // above
                [o.x - r.w, o.x + o.w, o.y + o.h, o.y + o.h], // below
                [o.x - r.w, o.x - r.w, o.y - r.h, o.y + o.h], // left
                [o.x + o.w, o.x + o.w, o.y - r.h, o.y + o.h]  // right
            ];
            for (const s of sides) {
                let x = Math.max(s[0], Math.min(r.x, s[1]));
                let y = Math.max(s[2], Math.min(r.y, s[3]));
                if (s[0] !== s[1])
                    for (const a of [o.x, o.x + o.w - r.w, o.x + (o.w - r.w) / 2])
                        if (Math.abs(x - a) < t) x = a;
                if (s[2] !== s[3])
                    for (const a of [o.y, o.y + o.h - r.h, o.y + (o.h - r.h) / 2])
                        if (Math.abs(y - a) < t) y = a;
                const c = { x: Math.round(x), y: Math.round(y), w: r.w, h: r.h };
                const d = Math.hypot(c.x - r.x, c.y - r.y);
                if ((!best || d < best.d) && !others.some(q => overlaps(c, q)))
                    best = { x: c.x, y: c.y, d };
            }
        }
        return best;
    }

    function move(i, x, y, t) {
        const others = mons.filter((_, j) => j !== i);
        const p = glue({ x, y, w: mons[i].w, h: mons[i].h }, others, t);
        if (!p) return;
        const next = mons.slice();
        next[i] = Object.assign({}, mons[i], { x: p.x, y: p.y });
        mons = next;
    }

    function apply(list) {
        const b = bounds(list);
        sent = list.map(m => ({ name: m.name, x: m.x - b.x, y: m.y - b.y }));
        applier.command = ["hyprctl", "eval", list.map(m =>
            `hl.monitor({ output = "${m.name}", mode = "${m.mode}", position = "${m.x - b.x}x${m.y - b.y}", ` +
            `scale = ${m.scale}, transform = ${m.transform} })`).join("; ")];
        applier.running = true;
    }

    Process {
        id: reader
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = JSON.parse(text)
                    .filter(o => !o.disabled && o.description !== "" && o.mirrorOf === "none")
                    .map(o => {
                        const rot = o.transform % 2 === 1;
                        return { name: o.name, x: o.x, y: o.y,
                                 w: Math.round((rot ? o.height : o.width) / o.scale),
                                 h: Math.round((rot ? o.width : o.height) / o.scale),
                                 mode: `${o.width}x${o.height}@${o.refreshRate.toFixed(3)}`,
                                 scale: o.scale, transform: o.transform };
                    });
                if (root.sent && root.sent.some(s => {
                        const m = list.find(l => l.name === s.name);
                        return m && (m.x !== s.x || m.y !== s.y); }))
                    root.status = "Hyprland kept its own positions (kanshi or another output manager owns them)";
                root.sent = null;
                root.mons = list;
                if (!root.live.length) root.live = list;
            }
        }
    }

    Process {
        id: applier
        stdout: StdioCollector {
            onStreamFinished: {
                root.status = text.trim() === "ok" ? "" : text.trim();
                reread.restart();
            }
        }
    }
    Timer { id: reread; interval: 300; onTriggered: reader.running = true }   // rules apply on the next frame

    Rectangle { anchors.fill: parent; color: Qt.alpha(Theme.bg, 0.78) }
    MouseArea { anchors.fill: parent; onClicked: root.hide() }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(820, parent.width - 40)
        height: Math.min(540, parent.height - 40)
        color: Theme.bg
        radius: Theme.radius
        border.width: 1
        border.color: Theme.line
        Keys.onEscapePressed: root.hide()
        MouseArea { anchors.fill: parent }                       // keep clicks off the scrim

        Item {
            id: view
            anchors { fill: parent; margins: 28; bottomMargin: 76 }
            // Fit the layout's box; frozen while a tile is held, or zoom/origin
            // move under the pointer (displaywright ArrangeCanvas.qml:33-36).
            property var heldBox: null
            readonly property var box: heldBox ?? root.bounds(root.mons)
            readonly property real zoom: Math.min(width / box.w, height / box.h)
            readonly property real ox: (width - box.w * zoom) / 2 - box.x * zoom
            readonly property real oy: (height - box.h * zoom) / 2 - box.y * zoom

            Repeater {
                model: root.mons.length                          // an int: new arrays keep the delegates (and the drag) alive
                Rectangle {
                    id: tile
                    required property int index
                    readonly property var m: root.mons[index]
                    x: view.ox + m.x * view.zoom
                    y: view.oy + m.y * view.zoom
                    width: m.w * view.zoom
                    height: m.h * view.zoom
                    radius: Theme.radiusS
                    color: grip.pressed ? Theme.bgHi : Theme.bgAlt
                    border.width: grip.pressed ? 2 : 1
                    border.color: grip.pressed ? Theme.accent : Theme.line
                    Text {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.fg
                        text: `${tile.m.name}\n${tile.m.w}×${tile.m.h}  ×${+tile.m.scale.toFixed(2)}`
                    }
                    MouseArea {
                        id: grip
                        anchors.fill: parent
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        property point start
                        property point press
                        onPressed: mouse => {
                            view.heldBox = view.box;
                            start = Qt.point(tile.m.x, tile.m.y);
                            press = mapToItem(view, mouse.x, mouse.y);
                        }
                        onPositionChanged: mouse => {
                            const p = mapToItem(view, mouse.x, mouse.y);
                            root.move(tile.index, start.x + (p.x - press.x) / view.zoom,
                                      start.y + (p.y - press.y) / view.zoom, 16 / view.zoom);
                        }
                        onReleased: view.heldBox = null
                        onCanceled: view.heldBox = null
                    }
                }
            }
        }

        Text {
            anchors { left: parent.left; right: buttons.left; bottom: parent.bottom; margins: 24 }
            elide: Text.ElideRight
            color: Theme.bad
            text: root.status
        }

        component TextBtn: Rectangle {
            property string label
            signal clicked
            width: 96; height: 32; radius: Theme.radiusS
            color: area.containsMouse ? Theme.line : Theme.bgAlt
            Text { anchors.centerIn: parent; text: parent.label; color: Theme.fg }
            MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
        }

        Row {
            id: buttons
            anchors { right: parent.right; bottom: parent.bottom; margins: 20 }
            spacing: 8
            TextBtn { label: "Revert"; onClicked: { root.mons = root.live; root.apply(root.live); } }
            TextBtn { label: "Apply"; onClicked: root.apply(root.mons) }
        }
    }
}
```

Wire it up like `PowerWindow { id: powerWin }` in `shell.qml:1652` and toggle it
from an IPC handler or a bind.

### Caveats in the sketch

- It applies a layout with no countdown. Moving positions cannot blank a screen
  (mode, scale and transform are re-sent unchanged), so DMS's or displaywright's
  10-15 s auto-revert is not needed until the popup also edits mode or scale.
- A rule whose `output` is the connector name (`DP-1`) wins over the config's
  `desc:` rule until the next `hyprctl reload`. After a reload, the config's
  layout comes back.
- On kanshi hosts the apply is a no-op for every output kanshi configured.
  Section 0, point 3 explains why, and the status line reports it after the
  re-read. The re-read never sees the eval'd position, so the tiles snap back,
  which is honest.
- Glue allows a corner-only contact (the clamp range includes `o.x - r.w` with
  `y = o.y - r.h`). Hyprland accepts it, but the pointer cannot cross a corner.
  Shrink the clamp ranges by 1 px if that matters.
