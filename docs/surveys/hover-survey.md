# Workspace-pill hover: 16 projects vs. ours

Every file below was opened and read. Local clones are under
`/tmp/claude-1000/-home-erikf--dotfiles--claude-worktrees-notifications-dark-mode-fix-2b275e/a86c222d-110d-4226-a5b0-f35e8c06695c/scratchpad/clones/`
(abbreviated `CLONES/`); the noctalia checkout is
`/home/erikf/.dotfiles/.claude/worktrees/notifications-dark-mode-fix-2b275e/noct4/` (abbreviated `NOCT4/`);
five were fetched fresh from GitHub into `.../scratchpad/fetched/` (abbreviated `FETCHED/`)
because the catalogue's top-starred shells were not on disk.

15 third-party implementations + ours. Of those 15, **11 have a real hover
affordance on the workspace indicator**; 4 (Brainitech, maxchennn, Ambxst,
caelestia) deliberately have none — they are kept in the table because their
absence is itself evidence about the consensus.

---

## 1. Comparison table

| # | Project | File:line of the colour expression | **Idle/base colour** | Animates what, how long | MouseArea vs HoverHandler, and where it sits | Hover read how | Hover visible against its ground? | Model / delegate churn | Active-pill branch |
|---|---------|-----------------------------------|----------------------|--------------------------|---------------------------------------------|----------------|-----------------------------------|------------------------|--------------------|
| **0** | **OURS** | `/home/erikf/projects/personal/quickshell/Workspaces.qml:136` | **`"transparent"` — the literal string, i.e. transparent *black*** | `Behavior on color { ColorAnimation { duration: 120 } }` (line 138), no easing given → default `Easing.Linear` | `MouseArea` (189-194), **child of the coloured Rectangle, `anchors.fill: parent`, exactly the visual bounds, no negative margins** | `hover.containsMouse` read directly in the ternary | **NO.** Hover colour is `Theme.bgHi`; the enclosing `Group` ground is *also* `Theme.bgHi` (`Group.qml:16`, used at `shell.qml:334-337`). Settled hover is literally invisible. | `Repeater` over `ScriptModel` (118-123) over a re-sorted copy of `Hyprland.workspaces.values`; ScriptModel diffs by identity so pills are not rebuilt | `ws.here ? Qt.alpha(Theme.accent, 0.22)` — first branch of the *same* ternary, so active and hover share one animated property; **the active pill has no hover feedback at all** |
| 1 | noctalia v4 (9.1k★) | `NOCT4/Modules/Bar/Extras/WorkspacePill.qml:85-95` | `Qt.alpha(Color.resolveColorKey(emptyColor), 0.3)` — **alpha of the theme's empty colour, never `"transparent"`** | `Behavior on color { enabled: !Color.isTransitioning; ColorAnimation { duration: Style.animationFast; easing.type: Easing.InOutQuad } }` (157-163). Size uses `states`/`transitions` (41-74), colour does not. | `MouseArea` (204-212) `anchors.fill: parent` — but **parent is the outer container Item, which is deliberately bigger than the coloured pill**: `width: isVertical ? barHeight : ...` with the comment `// Container uses full barHeight on cross-axis for larger click area` (37) and `// Full-height click area` (203). The coloured `Rectangle` (76-81) is inset inside it. | `pillMouseArea.containsMouse`, read directly, and it is the **first, highest-priority branch** (86) — hover beats focused/urgent/occupied | Yes — `Color.mHover` is `#9BFECE`, a mint (`NOCT4/Commons/Color.qml:420`), nothing like the capsule ground | `Repeater` over a hand-diffed `ListModel localWorkspaces` (`NOCT4/Modules/Bar/Widgets/Workspace.qml:119, 375-393, 616-619`) — they `set()` in place rather than clear/refill precisely to avoid rebuilding delegates | `workspace.isFocused` is branch 2, **below** hover; text colour has its own parallel ternary + its own `Behavior on color` (127-145) |
| 2 | end-4/dots-hyprland (15.3k★) | `FETCHED/end4_Workspaces.qml:90-104` + `FETCHED/end4_StateOverlay.qml` | Base rect is `color: "transparent"` (`end4_Workspaces.qml:94`, `StateOverlay.qml:12`) — **but it is never colour-animated**; the tint is a separate `StateLayer` child faded in by `FadeLoader { shown: root.hover }` (`StateOverlay.qml:14-26`) | **Opacity, on a separate overlay item.** No `ColorAnimation` anywhere on the hover path. | **One `ButtonMouseArea` for the entire group** (`end4_Workspaces.qml:14`, `hoverEnabled: true` at 50). No per-pill mouse item exists. Which pill is hovered is arithmetic: `hoverIndex = Math.floor(position / workspaceButtonWidth)` (51-54) | `root.containsMouse` + `root.containsPress` passed into the overlay (99-100) | Yes — `contentColor: Appearance.colors.colPrimary` at Material-3 state-layer alpha, over `m3secondaryContainer` | `Repeater { model: wsModel.shownCount }` — fixed count, delegates never created/destroyed on workspace churn | Active pill is its **own separate item** (`TrailingIndicator` at 81-87, z:2); hover is a *different* `TrailingIndicator` at z:3. **Active and hover never touch the same property.** |
| 3 | caelestia-dots/shell (10.8k★) | `FETCHED/Workspace.qml:53`, `FETCHED/Workspaces.qml:95-106` | n/a — **no hover styling at all** | Only `Behavior on Layout.preferredHeight` (`Workspace.qml:114`) | **One `MouseArea` for the whole column** (`Workspaces.qml:95-96`), resolves the pill with `layout.childAt(event.x, event.y)` (98) | not read | n/a | `Repeater { model: Config.bar.workspaces.shown }` — fixed count. (Inner window-icon repeater uses `ScriptModel`, `Workspace.qml:94-101`) | Active only changes the *text* colour and drives a separate `ActiveIndicator` loader (`Workspaces.qml:82-93`) |
| 4 | DankMaterialShell (7.4k★) | `FETCHED/Dank_WorkspaceSwitcher.qml:1356` | `unfocusedColor` — **an opaque theme colour**; hover is `Theme.withAlpha(unfocusedColor, 0.7)`, i.e. *the same hue at lower alpha*, never black | Colour goes through a `DankColorAnimation` object (1362-1366) whose output `pillColor.value` feeds `visualContent.color` (1606). **Gated: `animated: delegateRoot.colorAnimationReady`, and `colorAnimationReady` is only set true in `Component.onCompleted` (1358, 2028)** — a freshly created delegate does not animate its first colour. | `MouseArea` (1387-1390) `anchors.fill: parent`, hoverEnabled gated on `!isPlaceholder` | `property bool isHovered: mouseArea.containsMouse` (1159), a binding, used in the ternary | Yes — pill sits on the bar surface, hover is a 0.7-alpha tint of the pill's own colour | `Repeater` over a compositor-abstracted list; `_placeholder` entries keep the delegate count stable while workspaces come and go | `isActive ? activeColor` is branch 1, hover is branch 4 (after urgent and placeholder) — **so the active pill deliberately ignores hover**, same as ours |
| 5 | StatIndet/quickshell (186★) | `FETCHED/StatIndet_Workspaces.qml:76-79` | `Appearance.colors.colLayer4` — **opaque** | `Behavior on color { ColorAnimation { duration: 200 } }` (81) | `MouseArea` (84-88), sibling of the Rectangle, both fill the delegate `Item`; the Item's own `implicitWidth` grows to 32 when `active || isHovered` (63) | `property bool isHovered: mouseArea.containsMouse` (60) | Yes — dedicated `colLayer2Hover` token | `Repeater { model: Niri.workspaces }` | `active ? colPrimary` first, `hasWindows` second, **hover third** — active and occupied both outrank hover |
| 6 | josecriane/quickshell-config | `CLONES/josecriane_quickshell-config/modules/bar/components/Workspaces.qml:141-145` | `Foundations.palette.base02` — **opaque** | `Behavior on color { ColorAnimation { duration: Foundations.duration.fast; easing.type: Easing.InOutCubic } }` (159-164) | `MouseArea` (178-182) child of the pill, **`anchors.margins: -4`** — hit area 8px wider than the visual on every side | `property bool isHovered: pillMouseArea.containsMouse` (139) | Yes — hover is `Qt.lighter(base02, 1.3)`, i.e. **derived from the idle colour, guaranteed one step brighter** | `Repeater` over a hand-maintained `ListModel` refilled by `updateWorkspaceList()` (43-63) — clear/append, so delegates *are* rebuilt | `model.isFocused ? activeColor` first; also `scale: isFocused ? 1.0 : (isHovered ? 0.95 : 0.9)` (148), so hover is *also* signalled by scale, not colour alone |
| 7 | Gakuseei/Ricelin (230★) | `CLONES/Gakuseei_Ricelin/configs/quickshell/pill/Workspaces.qml:113-115` | Colour is **constant per state** (`isActive ? Theme.vermLit : Theme.cream`); **hover changes `opacity` only** | `Behavior on opacity { NumberAnimation { duration: Motion.fast } }` (115). No ColorAnimation. | `MouseArea` (118-127), **sibling of the dot Rectangle, and much larger**: `leftMargin/rightMargin: -gap/2`, `topMargin/bottomMargin: -8*s` (121-124) — the hit areas *tile*, no dead strips | `area.containsMouse` read directly (114); also latched into `workspaces.hoverIndex` via `onContainsMouseChanged` (128-133) for a different purpose | Yes — 0.3 → 0.7 opacity of an opaque cream on a dark bar | `Repeater { model: workspaces.range }` (a plain int array) | `isActive` wins the whole opacity expression: `slot.isActive ? 1.0 : (area.containsMouse ? 0.7 : 0.3)` — active pill ignores hover |
| 8 | tripathiji1312/quickshell (150★) | `CLONES/tripathiji1312_quickshell/modules/bar/components/Workspace.qml:32-36` | `Qt.rgba(fg.r, fg.g, fg.b, 0.2)` — **alpha of the foreground colour, explicitly not black** | `Behavior on color { ColorAnimation { duration: Material3Anim.short4; easing.bezierCurve: Material3Anim.standard } }` (56-61) — but **the colour has no hover branch**; hover drives `scale` (`onEntered: root.scale = 1.2`, 169-173) and a tooltip | `MouseArea` (152-157) child of the pill, **`anchors.margins: -4  // Larger hit area`** | `mouseArea.containsMouse` read directly by the tooltip (118, 127-128) | Yes — the tooltip is a distinct surface | `Repeater { model: config.bar.workspaces.count }` → `Loader { source: "Workspace.qml" }` (32-48), fixed count | `isActive` is branch 1 of the colour ternary; hover is on a different property entirely, so they cannot collide |
| 9 | corecathx/whisker (139★) | `CLONES/corecathx_whisker/modules/bar/Workspaces.qml:55-59` | `Appearance.colors.m3primary_container` — **opaque** | `Behavior on color { ColorAnimation { duration: Appearance.animation.fast; easing.type: Appearance.animation.easing } }` (63); also width and opacity | `MouseArea` (65-69) child of the pill, `anchors.fill: parent`, **`hoverEnabled` not even set** — no per-pill hover. A group-level `HoverHandler` (115-117) only drives the preview popout. | not read per-pill | n/a | `Repeater { model: Hyprland.fullWorkspaces }` | `focused || hasWindows ? m3primary` plus `opacity: focused ? 1.0 : 0.4` (53) and `width: focused ? 20 : 10` (49) |
| 10 | myamusashi/vast-shell (109★) | `CLONES/myamusashi_vast-shell/Qml/Widgets/Workspaces.qml:130-138` | Colour is per-state and **opaque** (`m3Primary` / `m3PrimaryFixedDim` / `m3OutlineVariant`); hover is handled by `MArea`'s built-in **layer**: `layerColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.8)` (115) | `Behavior on opacity` + `Behavior on implicitWidth`, both `NAnim` with `Appearance.animations.curves.emphasized` (140-151). **No ColorAnimation on the dot.** | `MArea` (a project-local MouseArea subclass) at 112-118, **sibling of `fgIndicator`, filling the whole delegate Item which is larger than the 8px dot**; `visible: !delegateRoot.isActive` so the active pill has no hit area at all | via `MArea`'s own layer, not read into the colour expression | Yes — `Qt.alpha(m3Primary, 0.8)` ripple layer | `Repeater` over a computed integer count | `isActive` drives width 8→24 and `opacity: isActive ? 1.0 : 0.5`; hover is disabled on the active pill by `visible: !isActive` |
| 11 | diinki/linux-antiquity (896★) | `CLONES/diinki_linux-antiquity/configs/quickshell/taskbar/Workspaces.qml:42-58` | Background Rectangle is `color: "transparent"` (57) — **but there is no `Behavior on color` anywhere**, so nothing interpolates through black. Hover changes only the *text* colour (33, 46). | **Nothing animated at all.** | **`HoverHandler`** (60-64), sibling of the `Button`'s `background` Rectangle, covering the whole Button | `mouse.hovered`, read inside `getColor()` (46) — note this is an imperative function, so it only re-evaluates when its captured bindings change | Yes — accent text on the bar background | `Repeater` over a filtered `Hyprland.workspaces.values` array | `modelData.id == focusedWindowId || mouse.hovered` — **active and hover collapse into the same visual**, deliberately |
| 12 | diinki/linux-retroism (757★) | `CLONES/diinki_linux-retroism/configs/quickshell/taskbar/Workspaces.qml:59-91` | `Config.colors.base` — **opaque**; hover → `Config.colors.shadow` | **Nothing animated.** Instant swap. | **`HoverHandler`** (87-91), sibling of the `background` Rectangle | `mouse.hovered` inside `getColor()` (69-73) | Yes — a 90s-style flat two-tone with a 1px outline (80-81) | `Repeater` over a filtered array | Same collapse as #11: focused-or-hovered → `shadow` |
| 13 | bjarneo/quickshell (125★) | `CLONES/bjarneo_quickshell/desktop/Workspace.qml:53-60` | **No background rectangle at all** — the pill is bare text | `Behavior on color`/`opacity`/`font.pixelSize`, all 120ms (58-60), driven by active/present, **not by hover** | `MouseArea` (63-73), `anchors.fill: parent`, **`anchors.margins: -2`** with the comment: `// Reach 2px into the 4px grid gap on every side so there are no dead strips between adjacent numbers — each kanji owns the space up to the midpoint between it and its neighbour, making clicks forgiving.` | `onEntered` fires a `Bloom` ripple (71) — the one project that latches on the *event* rather than reading state | Yes — a ripple, not a fill | `Repeater { model: 10 }` (`desktop/Bar.qml:414-424`), fixed count | `active` drives colour, opacity and font size together; hover is a ripple, orthogonal |
| 14 | Brainitech/Brain_Shell (228★) | `CLONES/Brainitech_Brain_Shell/src/modules/Left/Workspaces.qml:130-138` | Opaque `Theme.wsEmpty` | `Behavior on color { ColorAnimation { duration: 200 } }` (138) | `MouseArea` (166-171) child of the dot, `hoverEnabled` **not set** | not read | n/a — no hover state | `Repeater { model: 10 }`, fixed | `isActive ? Theme.wsActive` + width 200ms OutBack |
| 15 | maxchennn/vroomies (94★) | `CLONES/maxchennn_vroomies/settings/quickshell/components/Bar/Sway.qml:96-110` | `"transparent"` for the active diamond outline, `zyuTheme.bar_fg` for the dot — but **no colour animation on the workspace dots**, only `Behavior on width`/`opacity` (101-109) | width + opacity only | `MouseArea` (112-115), `hoverEnabled` not set on the workspace dots | not read | n/a for workspaces. **Their *other* bar buttons do have hover** (163-231) and use `Qt.rgba(1,1,1,0.07)` — an explicit rgba, never `"transparent"` — and **animate `width` 0→32 rather than colour** | `Repeater { model: Hyprland.workspaces }` | `isActive` swaps which of two sibling rectangles has non-zero width |
| 16 | Axenide/Ambxst (1.7k★) | `FETCHED/Ambxst_Workspaces.qml:415-470, 620-690` | n/a — pills are `Button`s whose `background` draws only number/dot/icon; **no hover fill** | `Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }` (457-464) | `Button` from QtQuick.Controls; a group-level `MouseArea` (177-185) only handles BackButton, plus a `WheelHandler` | not read | n/a | `Repeater { model: effectiveWorkspaceCount }`, fixed count | Active is a separate stretchy `StyledRect` overlay (`activeHighlightH`, 290-310) at z:2, over the buttons |

### HoverHandler vs MouseArea tally

- **`MouseArea` (or a project subclass of it — `MArea`, `ButtonMouseArea`, `Gen.MouseArea`): 14** — ours, noctalia, end-4, caelestia, DankMaterialShell, StatIndet, josecriane, Gakuseei, tripathiji, corecathx, myamusashi, bjarneo, Brainitech, maxchennn.
- **`HoverHandler`: 2** — both diinki repos (`linux-antiquity/…/Workspaces.qml:60`, `linux-retroism/…/Workspaces.qml:87`), same author, and in both cases it is attached to a `QtQuick.Controls.Button` where a `MouseArea` would fight the Button's own input handling. Neither carries a comment explaining the choice.
- **1 uses both** — corecathx: `MouseArea` on the pill for the click, `HoverHandler` on the container for the popout (`Workspaces.qml:65, 115-117`).
- **No project I read comments on why** it picked one over the other for workspace pills. The only comment on this axis in the whole survey is in *our own* `Btn.qml:30-32` — "Read from the MouseArea rather than latched by entered/exited, so it cannot stick on when the button is hidden or reparented mid-hover."

---

## 2. The consensus pattern

Stated as code, this is what the majority converge on:

```qml
// (a) Every colour in the ternary is a real colour. The idle value is either an
//     opaque theme token or an explicit alpha of a NAMED colour — never the
//     string "transparent", which is transparent BLACK.
Rectangle {
    id: visual
    color: pill.isActive  ? Theme.activeColour
         : ma.containsMouse ? Theme.hoverColour        // distinct token, not the ground
         : Qt.alpha(Theme.idleColour, 0.3)             // or an opaque token

    Behavior on color {
        ColorAnimation { duration: ~120-200; easing.type: Easing.InOutQuad }
    }
}

// (b) The hit area is BIGGER than the coloured rectangle, so adjacent pills tile
//     with no dead strip between them.
MouseArea {
    id: ma
    anchors.fill: parent
    anchors.margins: -4
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: activate()
}
```

with three named variants that the highest-star projects prefer:

- **Group-level hover (end-4 #2, caelestia #3).** One `MouseArea` over the entire
  rail; the hovered index is computed from `mouseX`/`mouseY`. There are then no
  per-pill enter/exit events at all, so crossing between pills cannot produce a
  transition.
- **Hover as a separate overlay whose *opacity* animates (end-4 #2, myamusashi #10,
  Gakuseei #7).** The pill's own `color` is never touched by hover, so the hover
  animation cannot interact with the active-workspace colour branch.
- **Hover derived from the idle colour (josecriane #6 `Qt.lighter(base02, 1.3)`,
  DankMaterialShell #4 `Theme.withAlpha(unfocusedColor, 0.7)`).** Guarantees the
  hover state is one perceptual step from idle in the *same* hue — it can never
  land on the ground colour by accident.

Counts on the highest-value column — **what the idle value is**:

| Idle value | Count | Who |
|---|---|---|
| Opaque theme token | 6 | DankMaterialShell, StatIndet, josecriane, diinki-retroism, corecathx, Brainitech |
| `Qt.alpha(namedColour, x)` / `Qt.rgba(fg.r,…, 0.2)` | 3 | noctalia (`Qt.alpha(emptyColour, 0.3)`), tripathiji, myamusashi's ripple layer |
| Opacity animated instead of colour | 3 | Gakuseei, myamusashi, end-4 |
| `"transparent"` **while colour-animating** | **1 — only ours** | — |
| `"transparent"` but never colour-animated | 3 | end-4's base rect, diinki-antiquity, maxchennn |

**No project in this survey animates `color` away from the literal `"transparent"`.
Ours is the only one.**

---

## 3. Every way our code differs, ranked by flicker likelihood

### #1 — Idle colour is `"transparent"` (transparent black) on a property that is colour-animated

`Workspaces.qml:136-138`:
```qml
color: ws.here ? Qt.alpha(Theme.accent, 0.22) : hover.containsMouse ? Theme.bgHi : "transparent"
Behavior on color { ColorAnimation { duration: 120 } }
```
`ColorAnimation` interpolates premultiplied-off RGBA channel-wise. `"transparent"`
is `#00000000`. Half way from it to `Theme.bgHi` (`#252932`) you are at roughly
`rgba(0x12, 0x14, 0x19, 0.5)` — a half-opaque near-black composited **on top of**
the `Group`'s `#252932` ground, i.e. materially darker than either endpoint. That
is the dark flash, and it happens on enter *and* on exit.

Contrast, in a real project: noctalia never uses the string — its idle value is
`Qt.alpha(Color.resolveColorKey(emptyColor), 0.3)`,
`NOCT4/Modules/Bar/Extras/WorkspacePill.qml:94`. Our own `Btn.qml:46` already does
the right thing (`Qt.alpha(root.hoverColor, 0)`) and `Btn.qml:11-16` documents
exactly this failure — `Workspaces.qml` is the file the fix was never applied to.

`grep -rn '"transparent"' /home/erikf/projects/personal/quickshell/*.qml` confirms
`Workspaces.qml:136` and `TrayMenu.qml:198` are the only two places in the shell
that still combine `"transparent"` with a `Behavior on color`.

### #2 — The settled hover colour is byte-identical to the ground it is drawn on

`Workspaces.qml:136` hovers to `Theme.bgHi`. `Group.qml:16` is `color: Theme.bgHi`,
and `shell.qml:334-337` puts `Workspaces` inside exactly that `Group`. Both resolve
to `base02`, `Theme.qml:28`.

So the animation's *destination* is invisible. Everything a user perceives on hover
is the dark dip of #1 and nothing else — which reads precisely as "flicker" rather
than "highlight". This is the same bug `Btn.qml:17-20` already fixed by moving
buttons to `Theme.line`; the fix was likewise not applied here.

Real-project contrast: josecriane derives hover from idle so it can never coincide —
`CLONES/josecriane_quickshell-config/modules/bar/components/Workspaces.qml:143`:
`if (isHovered) return Qt.lighter(Foundations.palette.base02, 1.3);`

### #3 — The hit area is exactly the visual, so 3px dead strips sit between pills

`Workspaces.qml:189-191`: `MouseArea { anchors.fill: parent }` on a 44×24 pill,
inside a `ColumnLayout { spacing: 3 }` (`Workspaces.qml:11`). Dragging the pointer
down the rail therefore produces enter → *exit* → enter for every pill boundary,
and each of those runs a full 120ms colour animation through transparent black.
With #1 in place, a single slow pass down the rail is a train of dark pulses. This
is a *second, independent* generator of the flicker Erik sees, and it is the one
that makes it look like flicker rather than a single flash.

Every project that keeps per-pill hover oversizes the hit area, several with an
explicit comment:

- `CLONES/bjarneo_quickshell/desktop/Workspace.qml:63-68` —
  `anchors.margins: -2` / *"Reach 2px into the 4px grid gap on every side so there
  are no dead strips between adjacent numbers"*.
- `CLONES/josecriane_quickshell-config/modules/bar/components/Workspaces.qml:181` —
  `anchors.margins: -4`.
- `CLONES/tripathiji1312_quickshell/modules/bar/components/Workspace.qml:155` —
  `anchors.margins: -4  // Larger hit area`.
- `CLONES/Gakuseei_Ricelin/configs/quickshell/pill/Workspaces.qml:121-124` —
  negative margins on all four sides, sized to half the inter-dot gap so the
  areas tile exactly.
- `NOCT4/Modules/Bar/Extras/WorkspacePill.qml:37, 203-206` — the `MouseArea` fills
  a container that is `barHeight` on the cross axis while the coloured pill is
  `capsuleHeight * baseDimensionRatio`; comments *"Container uses full barHeight on
  cross-axis for larger click area"* and *"Full-height click area"*.
- end-4 and caelestia remove the problem entirely with one group-level MouseArea
  (`FETCHED/end4_Workspaces.qml:14, 51-54`; `FETCHED/Workspaces.qml:95-98`).

### #4 — Hover and the active-workspace branch share one animated property

`Workspaces.qml:136` puts `ws.here` and `hover.containsMouse` in one ternary on one
`color`, under one `Behavior`. Two consequences:

- Clicking a pill flips `ws.here` **and** keeps `containsMouse` true, so the colour
  runs `transparent → bgHi → Qt.alpha(accent, 0.22)` back-to-back, two 120ms legs
  that visually stutter.
- `Qt.alpha(Theme.accent, 0.22)` is itself semi-transparent, so the *active* pill's
  entry animation also drags through transparent black.

end-4 keeps them on separate z-stacked items that never share a property —
`FETCHED/end4_Workspaces.qml:81-87` (active `TrailingIndicator`, z:2) vs `90-104`
(hover `TrailingIndicator` + `StateOverlay`, z:3). Ambxst does the same with a
separate `activeHighlightH` overlay (`FETCHED/Ambxst_Workspaces.qml:290-310`).

### #5 — The `Behavior on color` is ungated, so it also fires on theme changes and on delegate churn

`Workspaces.qml:138` has no `enabled:`. Two projects gate theirs explicitly:

- noctalia: `Behavior on color { enabled: !Color.isTransitioning; ColorAnimation {…} }`
  — `NOCT4/Modules/Bar/Extras/WorkspacePill.qml:157-163` and again at `139-145` for
  the label. Their palette itself animates (`NOCT4/Commons/Color.qml:183-196`), so
  they suppress per-widget animation while it does.
- DankMaterialShell gates the *first* assignment per delegate:
  `property bool colorAnimationReady: false` (`FETCHED/Dank_WorkspaceSwitcher.qml:1358`),
  `animated: delegateRoot.colorAnimationReady` (1365), set true only in
  `Component.onCompleted` (2028). A delegate that appears under the pointer therefore
  snaps to its colour instead of animating into it.

Ours uses `ScriptModel` (`Workspaces.qml:118-123`), which does diff by identity — so
this is lower risk than it would be with a clear/refill `ListModel` — but our shell
also swaps whole palettes at runtime (`Theme.qml:15-16`, `Scheme.qml`), which is
exactly the case noctalia guards against.

### #6 — Linear easing

`Workspaces.qml:138` gives no `easing.type`, so `ColorAnimation` defaults to
`Easing.Linear`. Every animated peer specifies a curve: noctalia `Easing.InOutQuad`
(`WorkspacePill.qml:143, 161`), josecriane `Easing.InOutCubic` (`Workspaces.qml:162`),
tripathiji a Material bezier (`Workspace.qml:59`), corecathx `Appearance.animation.easing`
(`Workspaces.qml:63`). Linear makes the mid-point — the darkest point of the #1
excursion — sit at exactly 60ms and hold visual weight there; an ease-out spends
less time near the start colour. Cosmetic on its own, aggravating in combination.

### #7 — No `cursorShape`

`Workspaces.qml:189-194` sets no `cursorShape`. Ten of the eleven peers with a
per-pill mouse item set `cursorShape: Qt.PointingHandCursor` (noctalia
`WorkspacePill.qml:207`, StatIndet `:88`, josecriane `:183`, tripathiji `:157`,
Gakuseei `:126`, corecathx `:67`, bjarneo `:70`, Brainitech `:168`, maxchennn `:113`,
both diinki via `HoverHandler.cursorShape`). Not a flicker cause; listed for
completeness because it is the one place where *every* project agrees and we differ.

---

## 4. Things nobody has considered

**(a) The dead-strip pulse train is a separate bug from the transparent-black flash,
and fixing only the colour will leave half the symptom.** See #3. Even with a
correct `Qt.alpha(hoverColour, 0)` idle and a visible hover colour, a 3px gap
between 24px-tall pills means the highlight still *drops out and comes back* on
every boundary crossing — it will just be a bright pulse instead of a dark one.
Both #1 and #3 need fixing for the rail to feel like end-4's or noctalia's.
The specific reason our shell is worse than everyone else's here: our pill is 44
wide inside a `Group` that is 46 (`Group.qml:13`), so horizontal slop is 1px each
side, while `ColumnLayout { spacing: 3 }` leaves a full 3px vertical strip. A
vertical rail is the orientation where inter-pill gaps are traversed most.

**(b) `Qt.alpha(Theme.accent, 0.22)` means the ACTIVE pill also animates out of
transparent black.** Everyone treats the active colour as opaque or as a state-layer
alpha over a known ground. Ours is a 22%-alpha accent that composites onto `bgHi`;
when the focused workspace changes, the pill that *loses* focus animates
`Qt.alpha(accent, 0.22) → "transparent"` and the pill that gains it animates the
other way, both through darker-than-either territory. So workspace switching flashes
too, not just hovering — which may be why it reads as "these pills flicker" rather
than "hover flickers".

**(c) The active pill gives no hover feedback at all.** `ws.here` is the first
branch (`Workspaces.qml:136`), so hovering the focused pill changes nothing.
noctalia deliberately inverts this — hover is the **first** branch and outranks
focused (`NOCT4/Modules/Bar/Extras/WorkspacePill.qml:86-89`), so every pill responds.
myamusashi instead makes the intent explicit by disabling the hit area on the active
pill (`CLONES/myamusashi_vast-shell/Qml/Widgets/Workspaces.qml:113`,
`visible: !delegateRoot.isActive`). We do neither — we silently swallow the hover,
which is the worst of the three because the pointer is over a live click target that
gives no acknowledgement.

**(d) `TrayMenu.qml:198` has the identical defect** (`color: area.containsMouse &&
row.usable ? Theme.bgHi : "transparent"` with `Behavior on color { ColorAnimation
{ duration: 110 } }` at line 200). It is less visible only because the tray menu's
ground is not `bgHi`. Worth fixing in the same pass. `LauncherWindow.qml:145` uses
`"transparent"` too but has **no** `Behavior`, so it is safe as-is.

---

## Files read

Ours: `/home/erikf/projects/personal/quickshell/Workspaces.qml`, `Btn.qml`,
`Group.qml`, `Theme.qml`, `shell.qml` (300-360), `TrayMenu.qml`, `LauncherWindow.qml`.

noctalia: `NOCT4/Modules/Bar/Extras/WorkspacePill.qml` (full),
`NOCT4/Modules/Bar/Widgets/Workspace.qml` (structure + 610-730),
`NOCT4/Commons/Color.qml` (hover tokens).

Local clones: corecathx_whisker, myamusashi_vast-shell, Gakuseei_Ricelin,
tripathiji1312, josecriane, Brainitech_Brain_Shell, diinki_linux-antiquity,
diinki_linux-retroism, bjarneo_quickshell (`desktop/Workspace.qml` + `desktop/Bar.qml`
414-424), maxchennn_vroomies, Rexcrazy804_Zaphkiel (checked — `kurumibar/Widgets/Workspace.qml`
and `kurukurubar/Widgets/WorkspacePill.qml` are a *single* "current workspace" button,
not a per-workspace pill rail, so excluded from the table).

Fetched from GitHub (not on disk): caelestia-dots/shell
`modules/bar/components/workspaces/{Workspaces,Workspace}.qml`; end-4/dots-hyprland
`dots/.config/quickshell/ii/modules/ii/bar/Workspaces.qml` +
`modules/common/widgets/StateOverlay.qml`; AvengeMedia/DankMaterialShell
`quickshell/Modules/DankBar/Widgets/WorkspaceSwitcher.qml`; Axenide/Ambxst
`modules/bar/workspaces/Workspaces.qml`; StatIndet/quickshell
`Modules/Bar/Workspaces/Workspaces.qml`.

Searched and found nothing usable: `liixini_skwd` (`skwd-bar/qml/bar/TopBar.qml` has
`focusWorkspace()` but renders no workspace pills), `doannc2212_quickshell-config`,
`shub39_dotfiles` (workspace mentions are in services only, no pill widget).
