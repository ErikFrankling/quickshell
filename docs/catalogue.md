# Quickshell Repository Catalogue (>50 GitHub stars)

**What this is for.** A reference index of every public GitHub repository above 50 stars that
contains Quickshell (QML desktop shell) code, so that a future coding session can jump straight
to a good source example instead of re-running discovery. Every row was verified to actually
contain QML that imports `Quickshell` (or to sit in a `quickshell/` config tree); repos that
merely mention Quickshell in a README are recorded in the NOT-A-SHELL section so nobody
investigates them twice.

**Data provenance / freshness.** Enumerated 2026-07-29 by merging: `topic:quickshell` (fully
exhausted -- the topic bottoms out at 5 stars), keyword repo search (`quickshell` in
name/description/readme, paginated, `stars:>50`), ~30 GitHub code searches for Quickshell-only
identifiers (`ShellRoot`, `PanelWindow`, `IpcHandler`, `WlrLayershell`, `ExclusiveZone`,
`QsMenuOpener`, `Quickshell.Services.*`, `import Quickshell`, `filename:shell.qml`, ...), the
`eq-desktop/awesome-quickshell` list, `language:QML stars:>50`, `topic:hyprland-dotfiles`,
`topic:niri`, and the fork lists of the five biggest shells. 1087 candidates resolved via GraphQL;
633 git trees fetched; 127 repos confirmed as containing Quickshell QML.

**Column notes.**
- **Size** is the count of `.qml` files and the summed *byte* size of those blobs from
  `git/trees/HEAD?recursive=1`. **Bytes, not lines.** Rough rule of thumb: ~33 bytes/line, so
  1 MB of QML is roughly 30k lines.
- **Last commit** is `pushed_at` (real last push), not `updated_at`.
- **Licence** says `NONE` explicitly when the repo has no licence file -- several very popular
  configs are unlicensed, so copying from them is legally murky.

---

## Read this first: two traps

1. **`noctalia-dev/noctalia` (9,078 stars, MIT, pushed 2026-07-29) is no longer Quickshell.**
   Noctalia v5 was rewritten as a native Wayland/OpenGL-ES shell in C++ "with no Qt or GTK
   dependency". The repo today contains **726 `.h` / 655 `.cpp` files and zero `.qml`**. The
   QML-era (v4) code survives only in `noctalia-dev/legacy-v4-plugins` (632 qml, 5.1 MB) and in
   old tags of the main repo. Many third-party "noctalia plugin" repos below are still QML and
   still useful. Do not send a session to `noctalia-dev/noctalia` looking for QML.
2. **`bgibson72/yahr-quickshell` reports 890 qml / 10.4 MB -- almost all of it is
   `VSCodium/User/History/**` editor autosave junk**, not a 10 MB shell. The same trap applies to
   any dotfiles repo that backs up an editor state directory.

---

## Shells and dotfiles-containing-a-shell (>50 stars, sorted by stars)

| # | Repo | Stars | Size | Licence | Last commit | Type | Read this for |
|---|------|-------|------|---------|-------------|------|---------------|
| 1 | [basecamp/omarchy](https://github.com/basecamp/omarchy) | 24169 | 100 qml, 1.1 MB | MIT | 2026-07-29 | SHELL (in distro) | The **plugin-host architecture**. `shell/shell.qml` documents why relative-path imports do not share singleton state, and injects service instances into plugins via properties instead. `shell/plugins/{bar,panels,services}/` is the cleanest first-party plugin API in the ecosystem. |
| 2 | [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) | 15345 | 586 qml, 1.9 MB | GPL-3.0 | 2026-07-27 | DOTFILES (shell "ii") | The **biggest widget library** (`modules/common/widgets`, 120 files) and the reference Material-You implementation. Only project shipping two complete alternative shells (`modules/ii/` and `modules/waffle/`) off one service layer. Entry: `dots/.config/quickshell/ii/shell.qml` |
| 3 | [caelestia-dots/shell](https://github.com/caelestia-dots/shell) | 10836 | 275 qml, 1.2 MB | GPL-3.0 | 2026-07-29 | SHELL | **Best-organised codebase overall**, and the reference for a C++ QML plugin alongside your shell (`plugin/src/Caelestia/`: `imageanalyser`, `qalculator`, `appdb`, `requests`, `toaster`, GLSL blob shaders). 18 flat service singletons. Entry `shell.qml` is 40 lines of declarative composition. |
| 4 | [AvengeMedia/DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) | 7427 | 567 qml, 7.5 MB | MIT | 2026-07-28 | SHELL | **Most compositor-portable** (niri/Hyprland/sway/MangoWC/labwc/MiracleWM behind `CompositorService`), 64 service singletons, documented IPC (`docs/IPC.md`), a plugin API, JSON theme files. The one to copy for multi-compositor abstraction. |
| 5 | [ilyamiro/nixos-configuration](https://github.com/ilyamiro/nixos-configuration) | 5937 | 30 qml, 1.6 MB | NONE | 2026-06-02 | DOTFILES | Small self-contained shell (`Bar`, `Lock`, `Floating`, `Caching`, `Config`) under `config/sessions/hyprland/scripts/quickshell/` -- good "whole shell in 30 files" scale reference. Unlicensed. |
| 6 | [mylinuxforwork/dotfiles](https://github.com/mylinuxforwork/dotfiles) | 4931 | 38 qml, 319 KB | GPL-3.0 | 2026-07-27 | DOTFILES (partial) | ML4W is waybar-based; Quickshell is used only for standalone apps (`overview/`, `CalendarApp/`, settings). Read for **packaging discrete Quickshell mini-apps** launched independently of a main shell. |
| -- | [noctalia-dev/noctalia](https://github.com/noctalia-dev/noctalia) | 9078 | **0 qml** (C++ rewrite) | MIT | 2026-07-29 | SHELL -- NOT QML ANY MORE | See trap 1 above. Historical interest only. |
| 7 | [Axenide/Ambxst](https://github.com/Axenide/Ambxst) | 1698 | 216 qml, 3.0 MB | AGPL-3.0 | 2026-07-23 | SHELL | **Most complete service layer** (42 singletons incl. `FocusGrabManager`, `GlobalShortcuts`, `KeyStore`, `ClipboardService` with a real SQL schema, `CompositorTomlWriter`, AI strategies). Ships `AGENTS.md` files and `config/ConfigValidator.js` -- a validated, schema-checked config. |
| 8 | [snowarch/iNiR](https://github.com/snowarch/iNiR) | 1326 | 812 qml, 8.5 MB | MIT | 2026-07-22 | SHELL (ii-derived) | Illogical-impulse ported to niri. Read for a **niri workspace/window model** replacing Hyprland IPC in an otherwise-identical codebase -- a good side-by-side diff target against end-4. |
| 9 | [fufexan/dotfiles](https://github.com/fufexan/dotfiles) | 1126 | 37 qml, 77 KB | MIT | 2026-07-02 | DOTFILES | Clean **Nix/home-manager packaging of a Quickshell config** (`home/services/quickshell/`). Read for the `.nix` wiring, not the widgets. |
| 10 | [ahmad9059/HyprFlux](https://github.com/ahmad9059/HyprFlux) | 906 | 33 qml, 148 KB | MIT | 2026-07-06 | DOTFILES | Minimal, readable bar+widgets config at a size you can hold in your head. |
| 11 | [diinki/linux-antiquity](https://github.com/diinki/linux-antiquity) | 896 | 50 qml, 3.1 MB | MIT | 2026-07-20 | SHELL (themed) | **Strongest non-Material visual identity** -- art-nouveau. Read for heavy custom `Canvas`/image-asset styling instead of Material tokens. |
| 12 | [diinki/linux-retroism](https://github.com/diinki/linux-retroism) | 757 | 15 qml, 71 KB | MIT | 2026-03-21 | SHELL (themed) | 90s-retro look in only 15 files -- the tightest "complete look-and-feel" example in the list. |
| 13 | [AhmedSaadi0/NibrasShell](https://github.com/AhmedSaadi0/NibrasShell) | 749 | 224 qml, 1.6 MB | MIT | 2026-07-20 | SHELL | **Data-driven theming**: `themes/variants/` (14 files) + `themes/modules/` swap the whole palette at runtime. Also an animated-mascot subsystem (`components/eye_shapes/`) and per-window animation dirs. |
| 14 | [nucleus-hq/nucleus-shell](https://github.com/nucleus-hq/nucleus-shell) | 743 | 130 qml, 696 KB | GPL-3.0 | 2026-07-11 | SHELL | Clear `services/` (24) to `modules/interface/{bar,sidebarLeft,sidebarRight,settings,lockscreen,overlays}` split plus a `plugins/` dir. Good mid-size template. |
| 15 | [pctrade/end4-pC](https://github.com/pctrade/end4-pC) | 709 | 508 qml, 2.2 MB | GPL-3.0 | 2026-07-28 | SHELL (end-4 fork) | Actively-maintained divergent end-4 fork; diff against upstream to see which end-4 patterns people actually change. |
| 16 | [snes19xx/surface-dots](https://github.com/snes19xx/surface-dots) | 656 | 81 qml, 837 KB | NONE | 2026-07-24 | DOTFILES | Multi-entry layout: separate `shell.qml` per surface (`task-bar/`, etc.) rather than one root. Unlicensed. |
| 17 | [Yujonpradhananga/Persona-Quickshell](https://github.com/Yujonpradhananga/Persona-Quickshell) | 616 | 29 qml, 192 KB | NONE | 2026-07-24 | SHELL (themed) | Persona-3 UI recreation -- read for **aggressive skewed/animated transitions** done purely in QML. Unlicensed. |
| 18 | [samyns/Unit-3](https://github.com/samyns/Unit-3) | 462 | 15 qml, 303 KB | MIT | 2026-06-03 | DOTFILES | NieR:Automata rice; Quickshell used alongside waybar -- example of incremental adoption. |
| 19 | [Cybersnake223/Hypr](https://github.com/Cybersnake223/Hypr) | 458 | 39 qml, 475 KB | MIT | 2026-07-29 | DOTFILES | Per-feature standalone Quickshell entry points (`launcher/shell.qml` etc.). |
| 20 | [ladybug-me/caelestia-dots-kde](https://github.com/ladybug-me/caelestia-dots-kde) | 436 | 391 qml, 2.2 MB | GPL-3.0 | 2026-07-29 | SHELL (port) | Caelestia running **on KDE Plasma 6** -- read for what has to change when the compositor is not wlroots/Hyprland. |
| 21 | [isabelroses/dotfiles](https://github.com/isabelroses/dotfiles) | 435 | 36 qml, 85 KB | EUPL-1.2 | 2026-07-22 | DOTFILES | Small hand-written bar (`home/isabel/quickshell/components/`) with tidy per-widget files; Nix-managed. |
| 22 | [shub39/dotfiles](https://github.com/shub39/dotfiles) | 401 | 19 qml, 43 KB | NONE | 2026-07-17 | DOTFILES | Compact niri bar. Unlicensed. |
| 23 | [liixini/skwd](https://github.com/liixini/skwd) | 347 | 123 qml, 828 KB | MIT | 2026-05-15 | SHELL | Skewed/parallelogram geometry throughout -- the reference for **non-rectangular panel shapes and input masks**. |
| 24 | [ChrisTitusTech/dwm-titus](https://github.com/ChrisTitusTech/dwm-titus) | 341 | 53 qml, 237 KB | MIT | 2026-07-29 | DOTFILES | Rare **Quickshell on X11/dwm** (control centre + bar under `config/quickshell/`) rather than Wayland layer-shell. |
| 25 | [Devvvmn/ActivSpot](https://github.com/Devvvmn/ActivSpot) | 322 | 35 qml, 1.0 MB | GPL-3.0 | 2026-07-03 | SHELL (island-centric) | `DynamicIsland.qml` + `AppLauncher`, `ClipboardViewer`, `Lock` as flat siblings -- minimal example of a notch/island with morphing states. |
| 26 | [TSM-061/ctOS](https://github.com/TSM-061/ctOS) | 292 | 55 qml, 125 KB | GPL-3.0 | 2026-07-26 | SHELL (FUI) | Watch-Dogs fictional-UI. Read for **procedural/geometric decoration components** (`bar/components/CornerFrame.qml`, `Meter.qml`, `Divider.qml`). Entry is `bar.qml`, not `shell.qml`. |
| 27 | [mailong2401/cartoon-shell](https://github.com/mailong2401/cartoon-shell) | 281 | 220 qml, 850 KB | GPL-3.0 | 2026-07-29 | SHELL | **Swappable bar layouts** (`modules/bar/layout/style1/...`) driven from settings -- the cleanest example of user-selectable bar arrangements. 24 services. |
| 28 | [Rexcrazy804/Zaphkiel](https://github.com/Rexcrazy804/Zaphkiel) | 278 | 93 qml, 216 KB | MIT | 2026-06-21 | DOTFILES (kurukurubar) | NixOS-native shell packaging; small enough to read end-to-end. Listed in awesome-quickshell. |
| 29 | [2SSK/dot-files](https://github.com/2SSK/dot-files) | 249 | 26 qml, 395 KB | MIT | 2026-07-18 | DOTFILES | Third-party **Noctalia v4 plugins** (`.config/noctalia.shell/plugins/catwalk/`) -- `BarWidget.qml` + `DesktopWidget.qml` + `Panel.qml` + `Main.qml` is the whole plugin contract. |
| 30 | [Nytril-ark/rumda](https://github.com/Nytril-ark/rumda) | 246 | 192 qml, 870 KB | NONE | 2026-06-13 | DOTFILES | Large hand-rolled shell under `common/quickshell/`. Unlicensed. |
| 31 | [EisregenHaha/fedora-hyprland](https://github.com/EisregenHaha/fedora-hyprland) | 246 | 344 qml, 1.4 MB | GPL-3.0 | 2026-02-11 | SHELL (fork of end-4) | Most-starred fork of end-4; read for **distro-portability patches** (Fedora paths/deps). Stale since Feb 2026. |
| 32 | [eq-desktop/eqsh](https://github.com/eq-desktop/eqsh) | 245 | 181 qml, 796 KB | Apache-2.0 | 2026-04-19 | SHELL | The best **Apple-style** shell. Splits `ui/controls/{primitives,auxiliary,providers,advanced,windows}` -- a real design-system layer -- plus `ui/components/notch/instances/` for multi-state notches. |
| 33 | [Gakuseei/Ricelin](https://github.com/Gakuseei/Ricelin) | 230 | 90 qml, 1.1 MB | MIT | 2026-07-29 | DOTFILES | Entirely hand-written Quickshell; per-surface entry points. |
| 34 | [Brainitech/Brain_Shell](https://github.com/Brainitech/Brain_Shell) | 228 | 93 qml, 761 KB | MIT | 2026-06-28 | SHELL | Has an explicit **`src/state/` layer** separate from `src/services/` -- one of very few shells that separates UI state from system services. |
| 35 | [xfcasio/amadeus](https://github.com/xfcasio/amadeus) | 210 | 19 qml, 57 KB | NONE | 2026-05-07 | SHELL | 19-file shell with horizontal/vertical bar variants as separate module dirs. Unlicensed. |
| 36 | [cxOrz/dotfiles-hyprland](https://github.com/cxOrz/dotfiles-hyprland) | 207 | 23 qml, 200 KB | MIT | 2026-07-05 | DOTFILES | ChromeOS-style shelf/launcher in a small file count. |
| 37 | [jutraim/niri-caelestia-shell](https://github.com/jutraim/niri-caelestia-shell) | 204 | 213 qml, 836 KB | GPL-3.0 | 2026-07-28 | SHELL (caelestia fork) | The maintained **caelestia-to-niri port**. Diff against upstream `caelestia-dots/shell` to see exactly which files are compositor-coupled. |
| 38 | [neur0map/ryoku-arch](https://github.com/neur0map/ryoku-arch) | 196 | 546 qml, 4.0 MB | GPL-3.0 | 2026-07-29 | DOTFILES | Full workstation image; Quickshell app under `ryoku/apps/ryovm/quickshell/`. Read for shipping a Quickshell GUI as one app in a larger product. |
| 39 | [Harman1307/dotfiles-Hyprland](https://github.com/Harman1307/dotfiles-Hyprland) | 188 | 8 qml, 204 KB | NONE | 2026-04-24 | DOTFILES | 8-file shell -- the smallest thing here that still looks finished. Unlicensed. |
| 40 | [StatIndet/quickshell](https://github.com/StatIndet/quickshell) | 186 | 301 qml, 2.2 MB | GPL-3.0 | 2026-07-29 | SHELL | 35 services, 40 shared widgets, a rich **left/right sidebar system** (`Modules/Sidebars/Left/{system,notifications,infoTools}`) and a card-based lock screen (`Modules/Lock/Cards`). |
| 41 | [dhrruvsharma/shell](https://github.com/dhrruvsharma/shell) | 182 | 128 qml, 1.1 MB | NONE | 2026-07-13 | SHELL | Mid-size hand-written shell. Unlicensed. |
| 42 | [AyushKr2003/niri-caelestia-shell](https://github.com/AyushKr2003/niri-caelestia-shell) | 170 | 338 qml, 1.7 MB | GPL-3.0 | 2026-06-01 | SHELL (caelestia fork) | Second caelestia-to-niri port; compare with #37 for two approaches to the same port. |
| 43 | [ilyamiro/imperative-dots](https://github.com/ilyamiro/imperative-dots) | 159 | 31 qml, 1.7 MB | NONE | 2026-05-13 | DOTFILES | Non-Nix twin of #5 -- the same shell packaged imperatively. Unlicensed. |
| 44 | [vaguesyntax/ii-vynx](https://github.com/vaguesyntax/ii-vynx) | 152 | 680 qml, 2.6 MB | GPL-3.0 | 2026-07-29 | SHELL (ii-derived) | Actively-developed end-4 derivative that markets itself on modularity. |
| 45 | [tripathiji1312/quickshell](https://github.com/tripathiji1312/quickshell) | 150 | 73 qml, 482 KB | MIT | 2026-06-27 | SHELL | Performance-focused modular config; MIT and readable at 73 files. |
| 46 | [zepyxunderscore/hyprzepyx](https://github.com/zepyxunderscore/hyprzepyx) | 149 | 165 qml, 579 KB | NONE | 2026-01-07 | SHELL | "HyprZepyx" from awesome-quickshell. Current tree buries the shell under `config/old-stuff/spectral-horizon/`; stale since Jan 2026. Unlicensed. |
| 47 | [AxOS-project/Sleex](https://github.com/AxOS-project/Sleex) | 149 | 239 qml, 1.1 MB | GPL-3.0 | 2026-07-25 | SHELL (distro DE) | **84-file common widget library** under `modules/common/widgets` plus `modules/common/functions` -- the most library-like separation of reusable controls in a distro shell. |
| 48 | [wochap/nix-config](https://github.com/wochap/nix-config) | 145 | 96 qml, 132 KB | MIT | 2026-07-28 | DOTFILES | 96 QML files in only 132 KB -- an unusually **fine-grained, tiny-file** decomposition. Good Nix module wiring. |
| 49 | [notcandy001/Moonveil](https://github.com/notcandy001/Moonveil) | 140 | 593 qml, 3.9 MB | AGPL-3.0 | 2026-07-11 | SHELL (CrescentShell) | Large customisation-first shell; note AGPL. |
| 50 | [corecathx/whisker](https://github.com/corecathx/whisker) | 139 | 151 qml, 696 KB | GPL-3.0 | 2026-07-25 | SHELL | Featured in awesome-quickshell. Best **first-run onboarding flow** (`windows/firsttime/`, 9 files) and a clean `windows/` vs `modules/` split, including a vertical bar variant. |
| 51 | [luyu-wu/Config](https://github.com/luyu-wu/Config) | 138 | 62 qml, 219 KB | MIT | 2026-06-30 | DOTFILES | Quickshell used for scripts/utilities under `hypr/Scripts/`. |
| 52 | [HANCORE-linux/quickshell-dots](https://github.com/HANCORE-linux/quickshell-dots) | 135 | 143 qml, 2.0 MB | MIT | 2026-07-28 | SHELL (bar) | Omarchy-targeted bar; keeps whole **versioned copies** (`versions/V1/...`) -- handy for seeing an evolution diff. |
| 53 | [ulises-jeremias/dotfiles](https://github.com/ulises-jeremias/dotfiles) | 130 | 297 qml, 1.4 MB | MIT | 2026-07-28 | DOTFILES | chezmoi-managed (`home/dot_config/quickshell/`) -- read for **templating a Quickshell config through chezmoi**. |
| 54 | [bjarneo/quickshell](https://github.com/bjarneo/quickshell) | 125 | 70 qml, 766 KB | NONE | 2026-06-15 | SHELL (Omarchy) | Navbar + omni-menu for Omarchy, multi-entry (`backgrounds/shell.qml` etc.). Unlicensed. |
| 55 | [iamhrigved/Hyprdots](https://github.com/iamhrigved/Hyprdots) | 123 | 23 qml, 37 KB | NONE | 2025-08-27 | DOTFILES | Tiny and old (Aug 2025) -- early-Quickshell idioms; historical baseline only. Unlicensed. |
| 56 | [caioax/lyne-dots](https://github.com/caioax/lyne-dots) | 122 | 75 qml, 489 KB | GPL-3.0 | 2026-05-11 | DOTFILES | Full desktop with custom components, moderate size. |
| 57 | [Nurysso/Hecate](https://github.com/Nurysso/Hecate) | 115 | 22 qml, 108 KB | GPL-3.0 | 2026-06-13 | DOTFILES | 22-file shell. |
| 58 | [melatonia/meloworld-dotfiles](https://github.com/melatonia/meloworld-dotfiles) | 115 | 75 qml, 537 KB | MIT | 2026-07-03 | DOTFILES | Separate Quickshell processes per feature (`quickshell/idle-overlay/` etc.) -- read for **one-process-per-surface** as an alternative to one big shell. |
| 59 | [j5onrf/dots](https://github.com/j5onrf/dots) | 114 | 2 qml, 42 KB | NONE | 2026-06-21 | DOTFILES | Two large single-file surfaces (`c-shell.qml`) -- an anti-pattern example worth seeing once. Unlicensed. |
| 60 | [EC2854/dotfiles](https://github.com/EC2854/dotfiles) | 114 | 18 qml, 44 KB | NONE | 2025-12-15 | DOTFILES | Small, stale (Dec 2025). Unlicensed. |
| 61 | [myamusashi/vast-shell](https://github.com/myamusashi/vast-shell) | 109 | 226 qml, 1.2 MB | GPL-3.0 | 2026-07-28 | SHELL | Strong four-layer layout: `Qml/Core/{Configs,Utils}` -> `Qml/Services` (25) -> `Qml/Components/Base` -> `Qml/Modules`. Includes a performance/perf-pages drawer and a lock module. |
| 62 | [Goxore/nixconf](https://github.com/Goxore/nixconf) | 104 | 9 qml, 15 KB | MIT | 2026-06-29 | DOTFILES | Two tiny Quickshell "wrapped programs" -- a bar and a **lyrics overlay** (`lyricsProgram/services/MusicLyricsService.qml`). Excellent minimal single-purpose examples. |
| 63 | [elkowar/dots-of-war](https://github.com/elkowar/dots-of-war) | 102 | 27 qml, 469 KB | NONE | 2026-05-19 | DOTFILES | Author of eww, now writing **Noctalia v4 plugins** (`eggs/noctalia/plugins/clipper/`). Unlicensed. |
| 64 | [SherLock707/hyprland_dot_yadm](https://github.com/SherLock707/hyprland_dot_yadm) | 99 | 58 qml, 302 KB | NONE | 2026-05-30 | DOTFILES | yadm-managed dotfiles containing a full shell. Unlicensed. |
| 65 | [mkhmtolzhas/mkhmtdots](https://github.com/mkhmtolzhas/mkhmtdots) | 98 | 28 qml, 81 KB | NONE | 2026-06-03 | DOTFILES | Small shell. Unlicensed. |
| 66 | [atif-1402/anomshell](https://github.com/atif-1402/anomshell) | 97 | 46 qml, 713 KB | MIT | 2026-05-09 | SHELL (Omarchy) | Mid-small Omarchy-targeted shell. |
| 67 | [na-ive/nandoroid-shell](https://github.com/na-ive/nandoroid-shell) | 96 | 328 qml, 2.6 MB | AGPL-3.0 | 2026-07-27 | SHELL | **Android-ROM-inspired**, clearest `panels/` vs `widgets/` vs `services/` (47) separation. `panels/Settings/pages/*` is a good model for a large settings UI. Note AGPL. |
| 68 | [maxchennn/vroomies](https://github.com/maxchennn/vroomies) | 94 | 12 qml, 220 KB | MIT | 2026-07-08 | DOTFILES | 12-file "no waybar, no bloat" bar -- good minimal waybar-replacement reference. |
| 69 | [octagonemusic/octashell](https://github.com/octagonemusic/octashell) | 92 | 35 qml, 230 KB | MIT | 2026-07-25 | SHELL | Readable 35-file MIT shell. |
| 70 | [0Crazy-0/dotfiles](https://github.com/0Crazy-0/dotfiles) | 89 | 586 qml, 1.9 MB | GPL-3.0 | 2026-07-25 | DOTFILES (ii copy) | Vendored copy of end-4's `ii` shell inside personal dotfiles. |
| 71 | [ladybug-me/end-4dots-kde](https://github.com/ladybug-me/end-4dots-kde) | 87 | 1154 qml, 3.8 MB | GPL-3.0 | 2026-06-24 | SHELL (port) | Largest QML file count in the catalogue. end-4 on **Plasma 6**. |
| 72 | [dim-ghub/caelestia-shell](https://github.com/dim-ghub/caelestia-shell) | 87 | 353 qml, 1.9 MB | GPL-3.0 | 2026-07-27 | SHELL (caelestia fork) | Actively maintained caelestia fork. |
| 73 | [MannuVilasara/xenon-shell](https://github.com/MannuVilasara/xenon-shell) | 81 | 100 qml, 527 KB | GPL-3.0 | 2026-06-11 | SHELL | 100-file shell, moderate complexity. |
| 74 | [Harman1307/Alphonso](https://github.com/Harman1307/Alphonso) | 81 | 12 qml, 278 KB | NONE | 2026-06-03 | DOTFILES | 12-file shell. Unlicensed. |
| 75 | [R7rainz/dotfiles](https://github.com/R7rainz/dotfiles) | 78 | 14 qml, 68 KB | MIT | 2026-07-03 | DOTFILES | A Noctalia **`mini-docker` plugin** with a delegate-per-resource design (`Components/{Container,Image,Network}Delegate.qml`). |
| 76 | [hooss-only/dotfiles-minecraft-style](https://github.com/hooss-only/dotfiles-minecraft-style) | 76 | 33 qml, 87 KB | MIT | 2026-01-16 | DOTFILES | Pixel-art theming: nearest-neighbour image handling and bitmap fonts in QML. Stale since Jan 2026. |
| 77 | [bgibson72/yahr-quickshell](https://github.com/bgibson72/yahr-quickshell) | 76 | 890 qml, 10.4 MB (inflated) | NONE | 2026-07-08 | DOTFILES | **See trap 2** -- most of the QML is editor history. Unlicensed. |
| 78 | [elythh/flake](https://github.com/elythh/flake) | 73 | 0 qml | NONE | 2026-07-26 | DOTFILES (nix only) | Quickshell packaged via Nix but the QML lives elsewhere. Read only `modules/home/programs/quickshell/default.nix`. |
| 79 | [yurihikari/ml4w-lightcrimson-dotfiles](https://github.com/yurihikari/ml4w-lightcrimson-dotfiles) | 69 | 86 qml, 956 KB | GPL-3.0 | 2026-07-28 | DOTFILES | ML4W derivative with more Quickshell than upstream. |
| 80 | [ChrisTitusTech/quickshell](https://github.com/ChrisTitusTech/quickshell) | 68 | 22 qml, 32 KB | NONE | 2025-07-02 | SHELL (bar) | Very small, very old (Jul 2025). Useful only as an early-API snapshot. Unlicensed. |
| 81 | [r0naldoom/dotfiles](https://github.com/r0naldoom/dotfiles) | 65 | 364 qml, 3.1 MB | GPL-3.0 | 2026-02-01 | DOTFILES | Vendored **Noctalia v4 QML shell** (`dotfiles/config/noctalia-shell/`) -- one of the easier places to read pre-rewrite Noctalia source. Stale Feb 2026. |
| 82 | [bobvanderlinden/nixos-config](https://github.com/bobvanderlinden/nixos-config) | 63 | 30 qml, 134 KB | NONE | 2026-07-29 | DOTFILES | Actively-pushed 30-file Nix-managed shell. Unlicensed. |
| 83 | [bdsqqq/dots](https://github.com/bdsqqq/dots) | 59 | 31 qml, 166 KB | NONE | 2026-07-29 | DOTFILES | Small, current. Unlicensed. |
| 84 | [pynappo/dotfiles](https://github.com/pynappo/dotfiles) | 58 | 9 qml, 14 KB | NONE | 2026-05-05 | DOTFILES | Per-screen entry points (`.config/quickshell/pynappo/Screens/Logout/shell.qml`, `OSD/`, `Bar.qml`). Nice tiny **multi-surface** layout. Unlicensed. |
| 85 | [doannc2212/quickshell-config](https://github.com/doannc2212/quickshell-config) | 56 | 28 qml, 179 KB | NONE | 2026-06-19 | SHELL | Designed so each piece (bar / launcher / notification daemon / theme switcher, 206 themes) works standalone. Best **"take one module out"** structure at small size. Unlicensed. |
| 86 | [tonybanters/quickshell-btw](https://github.com/tonybanters/quickshell-btw) | 55 | 2 qml, 29 KB | NONE | 2025-12-04 | SHELL (bar) | Two-file sway/Hyprland bar -- the smallest complete bar here. Unlicensed, stale. |
| 87 | [TLSingh1/dotfiles](https://github.com/TLSingh1/dotfiles) | 55 | 104 qml, 251 KB | NONE | 2025-12-11 | DOTFILES | 104 small files under a Nix module. Stale Dec 2025. Unlicensed. |
| 88 | [entailz/thorn](https://github.com/entailz/thorn) | 54 | 91 qml, 525 KB | GPL-3.0 | 2026-02-07 | SHELL | Productivity-focused personal shell. Stale Feb 2026. |
| 89 | [stormy-soul/sshell](https://github.com/stormy-soul/sshell) | 53 | 106 qml, 478 KB | NONE | 2026-05-06 | SHELL | 106-file shell. Unlicensed. |
| 90 | [imiric/quickshell-niri](https://github.com/imiric/quickshell-niri) | 52 | 36 qml, 120 KB | MIT | 2026-05-30 | SHELL (teaching examples) | **The best small teaching repo.** Two graded configs: `simple-bar/` (5 files) and `fancy-bar/` with `services/{Battery,Network,CPU,RAM,Niri}.qml`, `modules/common/{Config,Types,BarState}.qml`, `modules/common/utils/{FileUtils,ColorUtils}.qml`, `modules/common/widgets/{AutoSizingMenu,HoverPopup,ProgressBarText}.qml`. |
| 91 | [flickowoa/zephyr](https://github.com/flickowoa/zephyr) | 51 | 22 qml, 56 KB | NONE | 2024-12-25 | DOTFILES | Oldest entry (Dec 2024) -- pre-1.0 Quickshell API. Do not copy from it. Unlicensed. |

**91 shell/dotfiles entries.** (Plus `noctalia-dev/noctalia`, listed but disqualified.)

---

## Components and single-widget projects worth stealing from

| Repo | Stars | Size | Licence | Last commit | Steal this |
|------|-------|------|---------|-------------|-----------|
| [Darkkal44/qylock](https://github.com/Darkkal44/qylock) | 2368 | 92 qml, 906 KB | GPL-3.0 | 2026-07-28 | **Lock screens.** A collection of Quickshell lockscreen setups (`quickshell-lockscreen/`) plus SDDM themes. Bundles a vendored `QtGraphicalEffects` shim -- useful to know that trick exists. |
| [peteonrails/voxtype](https://github.com/peteonrails/voxtype) | 1026 | 10 qml, 123 KB | MIT | 2026-07-16 | **OSD surfaces driven by an external process.** `quickshell/OsdSurface.qml`, `EnginePicker.qml`, `MeetingControls.qml` -- a Rust app driving a Quickshell UI. Best example of Quickshell as the GUI layer of a non-QML program. |
| [liixini/skwd-wall](https://github.com/liixini/skwd-wall) | 558 | 84 qml, 792 KB | MIT | 2026-07-28 | **Wallpaper picker** with image/video/Wallpaper-Engine-scene support, matugen theme generation, and embedded Wallhaven/Steam browsing. Richest single-purpose Quickshell app in the list. |
| [Shanu-Kumawat/quickshell-overview](https://github.com/Shanu-Kumawat/quickshell-overview) | 451 | 14 qml, 130 KB | NONE | 2026-06-09 | **Hyprland workspace overview / expose** as a drop-in standalone module. Unlicensed. |
| [enhaoswen/Tide-island](https://github.com/enhaoswen/Tide-island) | 353 | 57 qml, 682 KB | GPL-3.0 | 2026-07-29 | **Dynamic island** with smooth morph states, standalone rather than baked into a shell. |
| [noctalia-dev/legacy-v4-plugins](https://github.com/noctalia-dev/legacy-v4-plugins) | 219 | 632 qml, 5.1 MB | NONE | 2026-07-22 | **Largest single collection of QML shell plugins anywhere** (632 files). Frozen by the v5 C++ rewrite, so it is a stable corpus of idiomatic Quickshell widget code. Unlicensed -- read, don't copy verbatim. |
| [Ronin-CK/HyprQuickFrame](https://github.com/Ronin-CK/HyprQuickFrame) | 204 | 7 qml, 48 KB | MIT | 2026-06-01 | **Region-select screenshot UI** in 7 files. Canonical small `PanelWindow` + input-mask example. |
| [Ronin-CK/QuickSnip](https://github.com/Ronin-CK/QuickSnip) | 164 | 7 qml, 66 KB | MIT | 2026-05-20 | **OCR / Google Lens overlay** -- region capture then external-process piping. |
| [JamDon2/hyprquickshot](https://github.com/JamDon2/hyprquickshot) | 133 | 4 qml, 12 KB | MIT | 2026-05-12 | The **smallest useful Quickshell program** in the catalogue (4 files, 12 KB). Read first for the minimum shape of a screenshot tool. |
| [Gakuseei/rishot](https://github.com/Gakuseei/rishot) | 110 | 12 qml, 140 KB | MIT | 2026-07-17 | Screenshot **plus annotation** overlay -- drawing/markup on a layer surface. |
| [imiric/qml-niri](https://github.com/imiric/qml-niri) | 95 | 4 qml, 22 KB | MIT | 2026-07-10 | **A QML plugin exposing niri IPC** as QML types. The template for writing your own compositor-IPC plugin instead of shelling out. |
| [AvengeMedia/dms-plugins](https://github.com/AvengeMedia/dms-plugins) | 79 | 45 qml, 659 KB | MIT | 2026-07-26 | First-party **DankMaterialShell plugin** examples -- the reference implementation of the DMS plugin contract. |
| [dom0/qs-hyprview](https://github.com/dom0/qs-hyprview) | 77 | 17 qml, 63 KB | GPL-3.0 | 2026-04-29 | **Window switcher / expose** using live window previews (`ScreencopyView`-class functionality). |
| [samjoshuadud/waylandar](https://github.com/samjoshuadud/waylandar) | 75 | 11 qml, 68 KB | MIT | 2026-07-27 | **Calendar widget with real sync backends** (Google/Nextcloud/iCloud/ICS). `frontend/components/{AgendaListPane,CalendarCard,CalendarGridPane}.qml`. |
| [AvengeMedia/dankcalendar](https://github.com/AvengeMedia/dankcalendar) | 68 | 43 qml, 598 KB | MIT | 2026-07-26 | Standalone calendar app built on the DMS common library -- how to reuse a shell's widget layer in a separate binary. |
| [folke/dot](https://github.com/folke/dot) | 1286 | 2 qml, 4 KB | Apache-2.0 | 2026-04-17 | **Minimal DMS plugin** (`config/DankMaterialShell/plugins/OptimusPlugin/`): one `PluginSettings` file + one widget file. Two files is the whole plugin. |
| [Balthazzahr/omatunes](https://github.com/Balthazzahr/omatunes) | 102 | 2 qml, 19 KB | NONE | 2026-07-28 | Rust music player exposing a 2-file Quickshell widget + popup pair (`scripts/quickshell/Omatunes{Widget,Popup}.qml`). Unlicensed. |
| [bjarneo/cliamp](https://github.com/bjarneo/cliamp) | 2741 | 6 qml, 21 KB | MIT | 2026-07-27 | `contrib/quickshell/` -- a **now-playing bar widget** (`BandStream.qml`, `NowPlaying.qml`, `TransportButton.qml`, `MediaIcon.qml`) driven by an external TUI player. Tiny and clean. |
| [crawraps/widgets-collection](https://github.com/crawraps/widgets-collection) | 59 | 7 qml, 9 KB | MIT | 2025-06-12 | A 7-file **dock** with `utils/{Appearance,Config,Paths}.qml` -- the smallest correct example of the "config + appearance + paths singleton trio". Stale Jun 2025. |
| [Eaquo/quickshell-games-launchers](https://github.com/Eaquo/quickshell-games-launchers) | 53 | 8 qml, 263 KB | NONE | 2026-07-09 | Game-launcher surfaces. Unlicensed. |
| [motor-dev/wallpaperCarousel](https://github.com/motor-dev/wallpaperCarousel) | 51 | 5 qml, 54 KB | NONE | 2026-06-30 | 5-file wallpaper **carousel with settings persistence** (`Carousel.qml`, `Settings.qml`). Unlicensed. |
| [BlackSparkz/hobbyist-dotfiles](https://github.com/BlackSparkz/hobbyist-dotfiles) | 65 | 1 qml, 4 KB | GPL-3.0 | 2026-06-25 | A **single-file power menu** (`Configs/quickshell/power_menu/shell.qml`). The 4 KB "hello world" of a real Quickshell surface. |
| [quickshell-mirror/quickshell-examples](https://github.com/quickshell-mirror/quickshell-examples) | 55 | 14 qml, 16 KB | NONE | 2025-07-28 | **Official examples**: `lockscreen/` (with `LockContext.qml`), `mixer/`, `wlogout/`, `volume-osd/`, `activate_linux/`, `focus_following_panel/`, `reload-popup/`. Authoritative but small and last touched Jul 2025 -- check API drift against current docs. |

**23 component entries.**

---

## NOT-A-SHELL -- recorded so nobody re-investigates

These matched a Quickshell search but are tooling, themes, templates, packaging, or unrelated.

| Repo | Stars | What it actually is |
|------|-------|---------------------|
| [quickshell-mirror/quickshell](https://github.com/quickshell-mirror/quickshell) | 2696 | **The toolkit itself** (C++/LGPL-3.0, GitHub mirror of the upstream git). Its 26 `.qml` files are internal/test fixtures, not examples. Go here for API truth, not for style. |
| [dusklinux/dusky](https://github.com/dusklinux/dusky) | 2290 | Arch setup scripts. Its only `.qml` is `.config/matugen/templates/quickshell.qml` -- a colour-scheme template, 555 bytes. |
| [amarsbar/rice-cooker](https://github.com/amarsbar/rice-cooker) | 668 | TypeScript ricing toy. Zero QML; matched on a `quickshell-sticker.svg`. |
| [bjarneo/aether](https://github.com/bjarneo/aether) | 604 | Go theming tool for Omarchy. Has a 4-file `contrib/quickshell/blueprints/` demo only. |
| [InioX/matugen-themes](https://github.com/InioX/matugen-themes) | 447 | matugen templates. `templates/quickshell.qml` is a 136-byte colour stub. |
| [MannuVilasara/qswitch](https://github.com/MannuVilasara/qswitch) | 211 | Tool for switching between multiple Quickshell configs. Not a shell. |
| [acdcbyl/Dotfiles-arch](https://github.com/acdcbyl/Dotfiles-arch) | 159 | Dotfiles whose only QML is a matugen colour template. |
| [cushycush/qml-language-server](https://github.com/cushycush/qml-language-server) | 94 | Go LSP for QML with Quickshell awareness (`handler/quickshell.go`). **Useful tooling**, no shell code. |
| [StatIndet/dotfiles](https://github.com/StatIndet/dotfiles) | 90 | Companion dotfiles to `StatIndet/quickshell`; only a matugen `Colorscheme.qml` and a demo file. The shell is in the other repo. |
| [linuxmobile/shin](https://github.com/linuxmobile/shin) | 876 | NixOS config; only `home/services/wayland/quickshell.nix` (packaging), no QML. |
| [AvengeMedia/DankLinux](https://github.com/AvengeMedia/DankLinux) | 51 | Installer/distro tooling for DMS. Zero QML. |
| [tuna-os/tunaOS](https://github.com/tuna-os/tunaOS) | 53 | Enterprise Linux image that ships DMS; a single 2 KB `conductor/dms-native/shell.qml` stub. |
| [AvengeMedia/dms-plugin-registry](https://github.com/AvengeMedia/dms-plugin-registry) | >50 | JSON plugin index for DMS. No QML. |
| [eq-desktop/awesome-quickshell](https://github.com/eq-desktop/awesome-quickshell) | <50 | The awesome list (still alive, 14 shells). Below the star threshold but used as a source here. |

**Also checked and confirmed to contain NO Quickshell code** (they surfaced in searches for
"quickshell" / "hyprland-dotfiles" / QML but are unrelated): `Vantesh/dotfiles`,
`aadritobasu/HyprKenso`, `NeKoRoSYS/NeKoRoSHELL`, `Harman1307/iris`, `hyprnux/hyprglass`,
`mailong2401/dotfiles-hyprland`, `Thunder-Blaze/BlazinLock`, `ezerinz/epik-shell` (AGS/TS),
`saltnpepper97/stasis`, `System64fumo/sysshell`, `parazeeknova/zen-wabi`, `EdenEast/nyx`,
`mwdavisii/nyx`, `yunfachi/nix-config`, `soymou/illogical-flake`, `Joanium/Joanium`,
`LinuxBeginnings/Ubuntu-Hyprland`, `sekiryl/hyprdots`, `SirEthanator/Hyprland-Dots`,
`Axenide/Ax-Shell` (Python/Fabric), `ignis-sh/ignis` (Python), `debuggyo/Exo` (Ignis/Python),
`S4NKALP/Modus` (Fabric/Python), `wayle-rs/wayle` (Rust), `MalpenZibo/ashell` (Rust),
`JakeStanger/ironbar` (Rust/GTK), `hcsubser/hybridbar`, `lirios/shell`, `papyros/papyros-shell`,
`ubports/unity8`, `KDE/plasma-*`, `aeroshell-desktop/aerothemeplasma`, and the large family of
SDDM/Plasma QML themes (`uiriansan/SilentSDDM`, `Keyitdev/sddm-astronaut-theme`, `rccyx/thyx`,
`xCaptaiN09/pixie-sddm`, `vinceliuice/*-kde`, `luisbocanegra/*`, ...) -- QML, but Plasma/SDDM,
not Quickshell.

---

## Start here: the repos to read first, and which files

Read in this order. The first three cover about 90% of idiomatic Quickshell.

### 1. `imiric/quickshell-niri` (MIT, 36 qml, 120 KB) -- learn the shape
The best-graded teaching material. Start with `simple-bar/` (5 files), then `fancy-bar/`:
- `fancy-bar/shell.qml` -- the root `ShellRoot` and per-screen fan-out
- `fancy-bar/modules/common/Config.qml` -- config singleton pattern
- `fancy-bar/modules/common/BarState.qml` -- UI state singleton, kept separate from config
- `fancy-bar/services/Niri.qml`, `services/Battery.qml` -- the service-singleton shape
  (one file, one system concern)
- `fancy-bar/modules/common/widgets/HoverPopup.qml`, `AutoSizingMenu.qml` -- popup sizing/anchoring
- `fancy-bar/modules/common/utils/FileUtils.qml`, `ColorUtils.qml` -- pure-JS helper singletons

### 2. `quickshell-mirror/quickshell-examples` (14 qml, 16 KB) -- the authoritative primitives
- `lockscreen/shell.qml` + `lockscreen/LockContext.qml` + `lockscreen/LockSurface.qml` -- the only
  official session-lock example; `LockContext` is the canonical "shared context object passed to
  per-screen surfaces" idiom
- `volume-osd/shell.qml` -- timed OSD popup, minimal
- `focus_following_panel/shell.qml` -- reacting to focus changes
- `reload-popup/shell.qml` + `ReloadPopup.qml` -- hot-reload UX
- `wlogout/shell.qml` + `WLogout.qml` + `LogoutButton.qml` -- a full-screen exclusive surface

Caveat: last pushed 2025-07-28; verify against current Quickshell docs.

### 3. `caelestia-dots/shell` (GPL-3.0, 275 qml, 1.2 MB) -- the reference architecture
- `shell.qml` -- 40 lines; note the `//@ pragma Env` block at the top (`QSG_RENDER_LOOP`,
  `QS_CRASHREPORT_URL`, `QS_DROP_EXPENSIVE_FONTS`) and `settings.watchFiles: true`
- `modules/ServiceLoader.qml` and `modules/GSFLoader.qml` -- deferred/lazy service instantiation
- `services/` (18 flat singletons) -- read `Notifs.qml` and `NotifData.qml` together for the
  **best notification service split in the ecosystem** (protocol/daemon separate from view model);
  then `Colours.qml` (Material-You palette generation), `Players.qml` (MPRIS), `Hypr.qml`
- `components/StyledRect.qml`, `StyledText.qml`, `StyledClippingRect.qml`, `StateLayer.qml`,
  `MaterialIcon.qml` -- the base-widget layer everything else builds on
- `components/Anim.qml`, `CAnim.qml`, `AnchorAnim.qml`, `AnimLoader.qml` -- animation primitives
- `modules/notifications/Wrapper.qml`, `Notification.qml`, `Content.qml` -- popup composition
- `plugin/src/Caelestia/` -- **the reference for extending Quickshell with C++**:
  `imageanalyser.cpp` (dominant-colour extraction), `qalculator.cpp`, `appdb.cpp`, `requests.cpp`,
  plus `Blobs/shaders/blob.vert` and `blob.frag` for GLSL
- `utils/Paths.qml`, `Icons.qml`, `Images.qml`, `Searcher.qml`, `Strings.qml`, `SysInfo.qml` and
  `utils/scripts/fuzzysort.js`, `fzf.js` -- fuzzy search in plain JS, imported into QML

### 4. `AvengeMedia/DankMaterialShell` (MIT, 567 qml, 7.5 MB) -- the production-grade one
Read selectively; it is large.
- `quickshell/shell.qml` -- `//@ pragma UseQApplication`, `//@ pragma AppId`, and the
  `DC.Style / I18n / Paths / Log / Host` back-end injection block in `Component.onCompleted`
- `quickshell/Services/CompositorService.qml` plus `NiriService.qml`, `HyprlandService.qml`,
  `MangoService.qml`, `LabwcService.qml` -- **the multi-compositor abstraction**, the single most
  reusable idea in this repo
- `quickshell/Common/Paths.qml`, `ModalManager.qml`, `PopoutManager.qml`, `OSDManager.qml`,
  `KeyboardFocus.qml` -- global singletons for focus/modality/overlays
- `quickshell/Common/Anims.qml`, `DankAnim.qml`, `DankColorAnim.qml`, `ListViewTransitions.qml`
- `quickshell/Common/Format.js`, `markdown2html.js`, `htmlElide.js` -- JS utility modules
- `quickshell/Modules/Notifications/Popup/`, `Center/`, and `NotificationContextMenu.qml`
- `quickshell/Modules/Settings/` (59 files) -- a large settings UI without chaos
- `quickshell/Modules/Plugins/` plus `docs/IPC.md` and `docs/CUSTOM_THEMES.md` -- plugin and IPC
  contracts

MIT licensed, so this is the safest big repo to copy from.

### 5. `basecamp/omarchy` (MIT, `shell/`, 100 qml) -- the cleanest plugin host
- `shell/shell.qml` -- read the comments: they explain the **singleton-identity gotcha** (a
  relative `import "path"` does not share singleton state with `import qs.Foo`) and the
  property-injection workaround
- `shell/plugins/bar/widgets/`, `shell/plugins/bar/indicators/`, `shell/plugins/panels/*`,
  `shell/plugins/services/media/` -- plugin taxonomy
- `shell/Commons/Style.qml`, `Color.qml`, `Border.qml`, `Util.qml` -- a 4-file design system
- `shell/Ui/` (30 files) -- the shared control library

### 6. `Axenide/Ambxst` (AGPL-3.0, 216 qml, 3.0 MB) -- the widest service surface
- `modules/services/` (42 files). Specifically the ones nobody else has:
  `FocusGrabManager.qml` and `FocusGrab.qml` (click-outside-to-dismiss done properly),
  `GlobalShortcuts.qml`, `KeyStore.qml`, `ClipboardService.qml` (plus `clipboard_init.sql`),
  `CompositorKeybinds.qml` / `CompositorConfig.qml` / `CompositorTomlWriter.qml`
  (reading and writing compositor config from the shell), `UsageTracker.qml`, `Visibilities.qml`
- `config/Config.qml` + `config/ConfigValidator.js` + `config/defaults/` -- **validated config with
  defaults**, the best config story in the catalogue
- `modules/notifications/` -- `NotificationGroup.qml`, `NotificationListView.qml`,
  `NotificationDelegate.qml`, `NotificationGroupExpandButton.qml`, `notification_utils.js`:
  the best **grouped/stacked notification** implementation
- `AGENTS.md` exists at repo root and inside `modules/services/` -- written for AI sessions

AGPL: read freely, be careful about copying.

### 7. `end-4/dots-hyprland` (GPL-3.0, `dots/.config/quickshell/ii/`) -- the widget encyclopedia
- `modules/common/widgets/` (120 files) -- if a control exists, it exists here
- `modules/common/models/` and `modules/common/models/quickToggles/` -- **data-driven UI**: quick
  toggles defined as model entries rather than hand-placed items
- `modules/common/functions/` (10 files) -- helper library
- `services/` (46 files)
- `modules/ii/` vs `modules/waffle/` -- two complete, visually unrelated shells sharing one service
  layer. Diffing these two directories is the fastest way to learn what is "shell policy" versus
  "shell mechanism".

### 8. `imiric/qml-niri` (MIT, 4 qml) or `AvengeMedia/dms-plugins` (MIT, 45 qml) -- extending
Pick `qml-niri` if you need to expose an external IPC as QML types; pick `dms-plugins` if you need
to write a plugin against an existing shell rather than build your own. `folke/dot` is the 2-file
minimum version of the latter.

### Honourable mentions for specific problems
- **Grouped notifications:** `Axenide/Ambxst modules/notifications/NotificationGroup.qml`
- **Notification service/data split:** `caelestia-dots/shell services/Notifs.qml` + `NotifData.qml`
- **Lock screen:** `quickshell-mirror/quickshell-examples/lockscreen/` then
  `StatIndet/quickshell Modules/Lock/Cards/`
- **Shaders/GLSL:** `caelestia-dots/shell plugin/src/Caelestia/Blobs/shaders/blob.vert|frag`
- **Swappable bar layouts:** `mailong2401/cartoon-shell modules/bar/layout/style1/`
- **Non-rectangular panels:** `liixini/skwd`
- **Large settings UI:** `AvengeMedia/DankMaterialShell quickshell/Modules/Settings/` or
  `na-ive/nandoroid-shell panels/Settings/pages/`
- **First-run onboarding:** `corecathx/whisker windows/firsttime/`
- **Nix packaging of a shell:** `fufexan/dotfiles home/services/quickshell/`,
  `Rexcrazy804/Zaphkiel`, `caelestia-dots/shell flake.nix` and `nix/`
- **X11 rather than Wayland:** `ChrisTitusTech/dwm-titus config/quickshell/`
- **Plasma 6 host:** `ladybug-me/caelestia-dots-kde`, `ladybug-me/end-4dots-kde`

---

## Counts

- **127** repos above 50 stars confirmed to contain Quickshell QML.
- **91** shells / dotfiles-containing-a-shell (plus 1 disqualified: `noctalia-dev/noctalia`).
- **23** components / single-widget projects.
- **14** NOT-A-SHELL entries recorded, plus about 35 further repos explicitly checked and cleared.
- Licence spread across the 91 shells: about 56 with an explicit licence file, about 35 with
  `NONE` -- check before copying.
