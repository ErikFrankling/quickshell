# Control centres, and the shape of a vertical bar

Two questions, asked of the same set of shells while the rail was being
restructured:

1. When a shell puts several unrelated things — notifications, volume, the
   tray, a system monitor — behind one button, how does it let you move between
   them, and how does the panel size itself?
2. Does a vertical bar round its corners, and does it stand its widgets on
   rounded grounds or on the bare bar?

Read: `noct4/` (Noctalia v4.7.7, the last QML release before the C++ rewrite),
and fifteen clones under a scratch directory — whisker, vast-shell, Ricelin,
tripathiji1312, Brainitech Brain Shell, Zaphkiel, bjarneo, diinki × 2,
shub39, maxchennn vroomies, liixini skwd, josecriane, doannc2212, Rexcrazy804.

---

## 1. Control centres

### The headline: most of them do not page at all

| Project | File | Lines | Pages | How you switch | Sizing |
|---|---|---:|---|---|---|
| Noctalia v4 | `Modules/Panels/ControlCenter/ControlCenterPanel.qml` | 191 | none | a card stack; anything deeper is a *sibling panel* opened by `PanelService.getPanel(...)` | width fixed 440; height a **hand-summed table of per-card constants** |
| whisker | `windows/quickpanel/QuickPanel.qml` | 500 | none | related surfaces are separate bar popouts | hard-fixed `460 × 670` |
| tripathiji1312 | `modules/controlcenter/ControlCenterWindow.qml` | 216 | none | one scrolling column | `440 × min(860, screen-40)` |
| vast-shell | `Qml/Modules/Drawers/QuickSettings/QuickSettings.qml` | 229 | 3 | **pill tab bar along the top edge**, `Repeater` over a 3-entry literal model | fixed, `0.3 × screen` wide |
| Brainitech | `src/popups/Dashboard.qml` | 218 | 5 | `TabSwitcher` strip + `Item { visible: page === … }` | **per-page width from a lookup table** |
| Zaphkiel | `Containers/CentralSwipable.qml` | 164 | 5 | **vertical icon rail** + `SwipeView`; active tab scales its glyph 1.6× | fixed by notch state |
| bjarneo | `desktop/omni/QuickContainer.qml` | 340 | drill-down | a 4-column toggle grid **compresses to a 64px icon rail** when you open a tile | height animates to the open detail |
| Ricelin | `pill/Pill.qml` | 2448 | 26 | string-keyed surfaces + an explicit `surfaceBack()` tree walk | **per-surface descriptor table of size thunks** |
| diinki antiquity | `popups/SettingsWindow.qml` | 974 | 7 | 220px sidebar list + a back button | not sized (a `FloatingWindow`) |

Citations for the load-bearing ones:

- Noctalia's card stack is `ControlCenterPanel.qml:99-140` — a `Repeater` over
  `Settings.data.controlCenter.cards` driving a `Loader` whose
  `sourceComponent` is a switch on `modelData.id`. Its height at `:35-70` sums
  hardcoded constants (`profileHeight` 64, `audioHeight` 60,
  `mediaSysMonHeight` 260 …) declared at `:72-79` **and duplicated** in the
  loader's own `Layout.preferredHeight` switch at `:105-122`. Weather is the
  one card that reports its measured height back (`:165-169`). A quick-toggle
  opens its sibling panel — `Widgets/Network.qml:13-14`:
  `PanelService.getPanel("networkPanel", screen)?.toggle(this)`.
- vast-shell's tab bar is `QuickSettings.qml:59-149`; its page component is 40
  readable lines at `:187-228` — every page `anchors.fill: parent`, cross-fades
  on `opacity`, slides 5% of the width in the direction of travel, and sits in
  a `Loader { active: currentIndex === pageIndex }` at `:212-218`, so an
  off-tab page is destroyed. `saveIndex` at `:25` persists the tab across
  opens.
- Brainitech's per-page width is a literal table at `Dashboard.qml:31-37`
  applied from `onPageChanged` at `:39-44`; the sibling `ArchMenu.qml:17-26,
  72-76` does both axes and pins the *window* to the largest page so the
  layer surface never resizes — only a masked sizer inside it does.
- Ricelin resolves an open surface's size through a thunk table at
  `Pill.qml:213-239`, most entries reading the loaded item's real
  `implicitHeight` plus a constant; `morphCloseness` at `:568-571` is a 0→1
  measure of how settled the morph is, and page content keys its opacity off
  that rather than off a timer, so a page never fades in over a half-grown
  shell.

### Where the settings GUI went

Every one of them has a settings GUI and every one of them keeps it **out** of
the control centre:

- Noctalia: `Modules/Panels/Settings/**` is **23,953 lines**, a sidebar
  `NListView` over a tab model plus a search index (`SettingsContent.qml`
  is 1331 lines on its own).
- whisker: the gear execs `whisker ipc settings open ""`
  (`QuickPanel.qml:242-246`) and closes the panel; settings is a separate
  427-line window with a collapsing sidebar.
- vast-shell: `Qml/Modules/Settings/Pages/*`, ~1000 lines.
- liixini skwd: `skwd-settings/qml/sections/BarSettings.qml` alone is 1249
  lines.

This is the whole argument for this shell's "no settings page, ever". The
control centre is not where a settings GUI starts — it is where one *ends up*
once pages exist and there is an obvious place to add a ninth.

### What was taken

A tab strip along the top and one `Loader` under it: vast-shell's shape, with
its per-page `Loader` but none of its slide animation. `panels/Control.qml` is
~100 lines including the reasoning, and it holds three pages.

Two things were **not** taken:

- **A toggle-pill grid** (whisker `QuickPanel.qml:357-426`, tripathiji
  `ControlCenterWindow.qml:179-194`). This rail already shows wifi and
  bluetooth state permanently and toggles them on right-click, so a grid of
  pills would restate what is two pixels to the left.
- **A size table** (Noctalia, Brainitech, Ricelin). The card in `shell.qml`
  already binds its height to `body.item.implicitHeight` and eases it, so
  putting `Layout.preferredHeight: item.implicitHeight` on the page loader
  gets per-page resizing for one line and no table to keep in sync. Noctalia's
  duplicated-constant switch at `ControlCenterPanel.qml:72-79` versus
  `:105-122` is what the table costs.

### How a bar button says its panel is open

Asked because filling the rail's metrics block with solid `Theme.accent`
turned the numbers inside the rings illegible.

- **Noctalia does not indicate it at all.** `BarPillVertical.qml:62-65`
  derives `bgColor`/`fgColor` from `hovered` and a custom colour only; there is
  no open-panel state in the pill.
- **whisker fills**, but only a quick-toggle tile: `StyledLargeButton` takes
  the primary colour when active (`QuickPanel.qml:21-78`) and it is a 2-column
  grid cell with its own label, not a strip of numbers.
- **Zaphkiel does not use a ground at all** — the active tab glyph scales to
  1.6× and everything else stays put (`CentralSwipable.qml:52-67`).
- **diinki** signals selection with text colour alone
  (`SettingsWindow.qml:66,80`).

None of them fills a tall block behind small text, because none of them has
one. So the rings keep a 12% accent wash and a hairline in the accent, and
`Btn` keeps its solid fill — it inverts its glyph to `Theme.bg` along with it
and it is one 28px slot.

Measured contrast of the ring numbers (`Theme.fg`) against the block behind
them:

| Theme | idle | solid accent (before) | wash + edge (after) |
|---|---:|---:|---:|
| Gruvbox dark | 11.9:1 | **1.8:1** | 9.8:1 |
| Gruvbox Light | 7.8:1 | **1.3:1** | 6.5:1 |
| Everforest Dark Medium | 3.8:1 | **1.5:1** | 3.1:1 |

Everforest is low in all three columns because its own `base05` is a muted
grey-green — that is the theme's choice, and the fix does not make it worse in
kind. The old behaviour did.

---

## 2. Vertical bar shape

Only four projects in the set have a real vertical bar, and the three that
thought about it all came to the same answer: **a vertical bar is a slab**.

- **bjarneo** makes it explicit. `desktop/Bar.qml:24`:
  ```qml
  readonly property bool cloudMode: bar.root.round && bar.root.isHorizontal
  ```
  over the comment at `:21-23`, *"Cloud mode: horizontal+round only. Vertical
  bars keep the original slab geometry."* Two backgrounds exist: `cloudBg`
  with `radius: cornerRadius` at `:55`, visible only when horizontal (`:47`),
  and `slabBg` at `:80-108` with **no radius property at all**, which is what a
  left or right bar gets.
- **shub39** has no radius anywhere in `quickshell/bar/Bar.qml`. The window
  itself carries the colour (`:17`); every widget is `radius: 0`
  (`bar/Time.qml:8`, `bar/CpuUsage.qml:9`, `bar/Dnd.qml:8`); the column is
  segmented by 4px gaps and split top/bottom by a `fillHeight` spacer at
  `:51-53`.
- **whisker** makes it a preference in one line —
  `modules/bar/vertical/VBarContainer.qml:28`, `radius: floating ? 20 : 0` —
  and draws one continuous strip (`:26-32`) with three anchored groups inside
  rather than separate pill clusters.
- **diinki antiquity** has no radius either; its rail silhouette is a quadratic
  bezier on a `Canvas` (`taskbar/Sidebar.qml:84-145`) that pinches to nothing
  at top and bottom, so it is flush-square against both screen edges by
  construction.

Pill clusters are a **horizontal**-bar idiom in this set: josecriane
(`modules/bar/components/*.qml`, one capsule per module), tripathiji
(`modules/bar/Bar.qml:73,122,188,269,334,420`, uniform `radius: 20`), maxchennn
(one continuous rounded card, `Sway.qml:48`).

### Rounding exactly one corner at a section boundary

The pattern this rail wanted — square everywhere, one curve where two sections
meet — exists in three places:

- `liixini_skwd/skwd-bar/qml/bar/dropdowns/DropdownTail.qml:34-37` squares the
  two corners that touch the bar and rounds the two that do not, choosing by
  which side the dropdown is on.
- `Rexcrazy804_Zaphkiel/.../Widgets/CalendarView.qml:22-27` and `:42-47` stack
  two rectangles into one visually continuous block: the upper rounds its top
  pair and squares its bottom pair, the lower does the reverse. Same at
  `Widgets/PowerTab.qml:118-120`.
- `Gakuseei_Ricelin/.../pill/Updates.qml:576-587` generalises it into a `Seg`
  component with `corner: -1 | 0 | 1`, so first and last segments round their
  outer pair and middles stay flat.

### What was taken

The rail runs square into all four screen edges, as bjarneo's, shub39's and
whisker's do. It keeps exactly one curve — the bottom right corner of the
workspaces block, which is full rail width and runs square into the top and
left screen edges. Nothing else on the rail has a ground; the metrics block
grows one only under the pointer or with its panel open. That removed four
rounded grounds and 132px of rail height.
