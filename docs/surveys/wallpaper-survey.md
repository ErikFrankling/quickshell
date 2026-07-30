# Wallpaper + theme switcher: how other people built it

Survey of real implementations on disk. Everything cited was opened; file:line given throughout.

---

## 1. Comparison table

Columns follow the ten questions. "LOC" is the wallpaper+theme surface only, not the whole shell.

| # | Project | Where it lives | Grid | Wallpaper source | Applied with | Theme list / preview | base16? | Light+dark | Wall→theme | Reaches other apps | LOC |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | **HIS SHELL** (`/home/erikf/projects/personal/quickshell`) | Page inside the 430px rail panel (`shell.qml:583` `cLooks`), stacked under themes | `GridView`, `cellWidth: width/3`, fixed `Layout.preferredHeight: 250`, `asynchronous`, `sourceSize.width: 220` (`panels/Wallpapers.qml:229-270`) | `~/Pictures/wallpapers`, hardcoded, **capped at 60** by `ls -1t … \| head -60` (`Wallpapers.qml:80`) + wallhaven API | `hyprctl hyprpaper wallpaper` (`Wallpapers.qml:161-170`); persists only via hyprpaper being alive — **not restored on restart** | 7 themes inline in `Looks.qml:40-46`, 4-colour swatch row, **no preview** | Yes, native — palette *is* base16 | **Dark only.** No variant field, no light branch | `wallust` via toggle (`WallMatch.qml`) | `~/.cache/wal/` 8 files + base16 YAML + OSC to `/dev/pts` (`Scheme.qml`) | **752** |
| 1 | **Noctalia** (`noct4/`) | Centred/anchorable overlay, **800×650** capped at half the screen (`WallpaperPanel.qml:15-18`) + colour scheme in a *separate* Settings tab | `NGridView`, on-disk thumbnail cache via `ImageCacheService.getThumbnail()` (`WallpaperPanel.qml:1174-1181`), busy indicator per cell | `find -L … -printf "%T@\|%p\n"` (`WallpaperService.qml:1152-1177`), configurable, recursive, per-monitor + Wallhaven | In-shell painted layer with 7 shader transitions (`WallpaperService.qml:276-306`) | 10 schemes, swatches built from a **hidden `Repeater` of `FileView`s** (`ColorsSubTab.qml:83-104`) | **No** — 14 Material-ish `m*` tokens + separate `terminal` block | **Both, in one file per theme**: `{"dark":{…},"light":{…}}` (`Assets/ColorScheme/Tokyo-Night/Tokyo-Night.json:1,46`); chosen by `Settings…darkMode`, a **declared** setting | Own Python reimplementation of matugen (`Scripts/python/src/theming/`) | 31 templates in `Assets/Templates/` (btop, gtk3/4, kitty, spicetify, telegram…) | **~8 500** |
| 2 | **Caelestia** (`repos/caelestia`) | **Inside the launcher**, typed as a prefix; horizontal `PathView` carousel (`modules/launcher/WallpaperList.qml`) | `PathView`, `pathItemCount: numItems`, `cacheItemCount: 4` (`WallpaperList.qml:63-64`); `CachingImage` = 17 lines of QML over a C++ provider | `FileSystemModel { recursive: true; filter: Images }` (`services/Wallpapers.qml:106-112`) | `caelestia wallpaper -f <path>` CLI (`Wallpapers.qml:36-39`); path persisted in `state/wallpaper/path.txt`, reloaded by `FileView` (`:85-104`) | 14 families / 29 flavours from `caelestia scheme list` JSON (`launcher/services/Schemes.qml:39-61`); **live desktop preview while scrolling** (`Wallpapers.qml:41-47`) | No — M3 token names, but scheme files are flat `key value` text | **Both.** Mode is a **declared field**: `currentLight = scheme.mode === "light"` (`services/Colours.qml:69`), sourced from the filename `<flavour>/<dark\|light>.txt` | `caelestia wallpaper` does it inline; toggled by `GlobalConfig.services.smartScheme` → `--no-smart` (`Wallpapers.qml:15`) | CLI writes templates; OSC via non-blocking `/dev/pts` writes (`caelestia-cli/.../theme.py:129-143`) | **~1 000** QML + 367 py |
| 3 | **doannc2212/quickshell-config** (`clones/doannc2212_quickshell-config/theme-switcher`) | Standalone centred `PanelWindow`, `WlrLayer.Overlay`, exclusive focus (`ThemeSwitcher.qml:66-72`) | n/a (themes only) — searchable `ListView` (`:354-359`) | n/a | n/a | **206 themes in one 89 KB `themes.json`**, grouped by `family`, 5-dot swatch row (`ThemeSwitcher.qml:443-462`), search box showing "N of 206", **live preview on cursor move** (`:49-53`) | No — semantic names (`bgBase`, `accentPrimary`) | Single set; `isDark` derived by **luminance** because the JSON has no variant field (`Theme.qml:31-39`) | `wallpaper-theme/set.sh` → `wallpaperMode` (`Theme.qml:107-128`) | kitty | **940** + 89 KB JSON |
| 4 | **Omarchy** (`repos/omarchy-quattro`) | Shell scripts, no GUI picker (`bin/omarchy-theme-*`) | n/a | `themes/<name>/backgrounds/` | `omarchy-theme-bg-set` | 22 themes = 22 **directories**, each with `colors.toml` + `preview.png` | No | Both (`catppuccin-latte`, `flexoki-light`, `white`). Mode precedence: `mode` key → legacy `theme_type` → `light.mode` sentinel → **luminance last** (`bin/omarchy-theme-color:119-134`) | No | Per-app files in the theme dir + `omarchy-theme-set-*` hooks | 265 (`omarchy-theme-color`) |
| 5 | **liixini/skwd-wall** (`clones/liixini_skwd-wall`) | Standalone app | `MosaicView`, `sourceSize` bound to `ImageService.thumbWidth/Height` = 640×360 (`MosaicView.qml:425-426`) | Local + Wallhaven + Steam Workshop | matugen | — | — | — | matugen, plus an **Ollama** auto-tagger | matugen templates | **20 609** total; `WallpaperSelector.qml` alone is **2 549** |
| 6 | **tinted-theming schemes-spec-0.11** (`scratchpad/sch/`, reference corpus not a shell) | — | — | — | — | **335 base16 YAML files**, 1.4 MB | Yes, canonical | **237 dark / 98 light, declared**: `variant: "light"` (`base16/sagelight.yaml:4`) | — | — | 115 KB as one compact JSON |
| 7 | **KDE Plasma, Image wallpaper plugin** (`plasma-workspace`, read via `git cat-file`; the checkout is sparse) | System Settings module + desktop config dialog; picker UI is 3 QML files, **653 lines**, everything else C++ | `KCM.GridView` over `GridView`, **`view.reuseItems: true`** (`ThumbnailsComponent.qml:162`); cell size derived from *screen aspect ratio* (`:151-160`); `previewSize` = screen/8 with a floor (`:164-186`) | `plasmarc [Wallpapers] usersWallpapers` + every XDG `wallpapers/` dir (`imageproxymodel.cpp:47-55`); KNewStuff for online | Plasma containment config; CLI goes through plasmashell's JS D-Bus API (`plasma-apply-wallpaperimage.cpp:82-109`) | Colour schemes rendered as a **miniature fake window** of real Qt Quick Controls — no screenshots (`kcms/colors/ui/main.qml:156-299`) | **No** — KConfig INI with 7 role groups | One palette per scheme, no variant field. **Light is detected by luminance**: `qGray(window) < 192`, and the constant is copy-pasted into 3 files (`filterproxymodel.cpp:105-115`, `mediaproxy.cpp:231-238`, `packagelistmodel.cpp:112-117`) | Accent colour only, blended in **OKLab** so lightness is never touched (`colorsapplicator.cpp:38-46`) | `kdeglobals` + KConfig change notification | ~12 800 total; **653** for the picker UI |
| 8 | **aylur-pre-astal** (AGS/TypeScript) | One row in a settings dialog — a GTK `FileChooserButton`, **31 lines** (`ags/widget/settings/Wallpaper.ts:13-19`) | None; current wallpaper shown as a CSS `background-image` | Single file `~/.config/background`; "random" downloads from the **Bing API** (`service/wallpaper.ts:53-75`) | `swww img`, transition originating at the cursor (`:31-41`); the file *is* the state | — | No | **Fills both and chooses later**: `matugen --dry-run -j hex` emits `{light, dark}` and both option trees are written (`lib/matugen.ts:22-30`) | matugen, on every wallpaper change | AGS options only | 31 + 99 + 113 = **243** |
| 9 | **end-4 dots-hyprland** (current, Quickshell) | Picker is `kdialog --getopenfilename` (`switchwall.sh:414`); grid lives in `wallpaperSelector/` (456+123+100) | `GridView`, source is `Qt.labs.folderlistmodel` directly (`services/Wallpapers.qml:5,20`); XDG-spec thumbnails generated at `normal\|large\|x-large\|xx-large` with a progress bar, python venv falling back to ImageMagick (`:136-147`) | `FolderListModel` on `~/Pictures/Wallpapers`; random from Konachan/osu APIs | `switchwall.sh`, path persisted with `jq` into the shell's own config (`:144-149`) | — | No — matugen Material tokens | Mode read from **gsettings** if unset (`switchwall.sh:262-270`); **light/dark can select a different image by filename suffix** `-dark`/`-light` (`:447-469`); terminal can be **forced dark independently of the UI** (`:272-280`) | matugen, plus a colourfulness metric to pick the variant (`scheme_for_image.py:27-36`) | 8 matugen templates + gsettings + OSC to `/dev/pts` (`applycolor.sh:67-73`) | 905 (scripts) + 859 (QML) |
| 10 | **end-4, older AGS version** (`dots-ii-ags`) | `yad --file --add-preview` (`switchwall.sh:136-137`) | yad's built-in preview | `~/Pictures/Wallpapers` | swww | — | No | **pywal backend selectable** — `wal -i … -n $lightdark`, then `~/.cache/wal/colors.scss` bridged to Material names by an appended SCSS shim and five `sed -i` passes (`colorgen.sh:68-96`) | pywal or Material | 9 targets fanned out as parallel bash jobs (`applycolor.sh:194-202`) | 652 |

| 11 | **DankMaterialShell** (`repos/dms/quickshell`) | Settings tab. The picker widget itself is only **80 lines** and delegates browsing to a shared `FileBrowserModal` — a text field plus a Browse button, no grid of its own (`Modules/Settings/Widgets/SettingsWallpaperPicker.qml:39-61`) | n/a in the picker; the modal owns it | Any path typed or browsed; 9 extensions incl. `jxl`, `avif`, `heif` (`:32`) | — | **10 named themes, each defined twice** — `StockThemes.DARK.{blue,purple,green,orange,red,cyan,pink,amber,coral,monochrome}` and an identically-keyed `StockThemes.LIGHT` (`Common/StockThemes.js:5,211`) | No — Material token names | **Parallel palettes selected by a declared boolean.** `SessionData.isLightMode` (`Common/Theme.qml:36`), then `const themeData = isLight ? lightTheme : darkTheme;` (`:188`). Flatter than Noctalia's per-theme JSON: one JS file holds both halves | matugen, mode passed in explicitly: `setDesiredTheme("image", rawWallpaperPath, isLight, …)` (`Theme.qml:164-166`) | Large template system | `StockThemes.js` 444 + `Theme.qml` 2 061 + `ThemeColorsTab.qml` 2 981 |

| 12 | **iNiR** (`repos/iNiR`, an `ii` fork) | Fullscreen window with a 1200×690 card anchored top-centre, **plus two alternative fullscreen modes** — a coverflow gallery and a "skew" view — routed by `Config.options.wallpaperSelector.style` (`WallpaperSelector.qml:179-182`) | Grid = `GridView`; filmstrip = `ListView` with `cacheBuffer: 800`; skew = `cacheBuffer: cardWidth*4`. **DPR-aware `sourceSize` everywhere**, a **sourceSize latch** that only ever upscales (`WallpaperSkewView.qml:899-910`), ±8 prefetch, and a **serial thumbnail queue to stop a thundering herd** (`ThumbnailImage.qml:56-64`). File list built **64 at a time on a 0 ms timer** (`services/Wallpapers.qml:287-305`) | Dir tree + **Wallhaven** (`services/Wallhaven.qml`, 623 lines, curl because Qt won't set `User-Agent`) + per-monitor + auto-cycling | **`awww`** (a swww fork) with in-shell fallback | **46 presets as inline QML objects** in one **3 879-line** singleton (`modules/common/ThemePresets.qml`); swatches are 3 circles from the preset's own colours (`ThemePresetCard.qml:62-80`) | No | **Declared `darkmode:` per preset** (39 dark, 5 light); luminance only on the wallpaper-derived path. Branching funnelled into **one** derived boolean `_auroraLightMode` (`Appearance.qml:78-80`) | Toggle — `appearance.theme === "auto"` gates it (`MaterialThemeLoader.qml:118-125`) | matugen + Go/Python generators for VSCode, Zed, OpenCode, Chrome, spicetify, Vesktop | **20 944** QML |
| 13 | **Moonveil / CrescentShell** (`repos/notcandy001_Moonveil`) | **Two parallel, unreconciled systems**: a transparent 1200×690 **hexagon overlay**, and a separate dashboard tab | Hex overlay uses a **`Repeater` over the whole folder model** — no virtualisation, no scrolling, unbounded height, plus two `Canvas` elements per item (`WallpaperSelectorContent.qml:267-385`). The dashboard tab is the opposite and the best-tuned grid in the survey: `reuseItems`, `cacheBuffer`, `displayMarginBeginning/End`, manual viewport cull, async `Loader` + spinner (`WallpapersTab.qml:661-924`) | Two sources that disagree: `FolderListModel` on `~/wallpaper` vs a recursive `find` on a configurable dir | In-shell paint + mpvpaper + a **GLSL palette-quantisation shader** that recolours the wallpaper to the theme | **12 schemes as light/dark JSON pairs** on disk (`assets/colors/<Name>/{light,dark}.json`), ANSI-16-shaped (`red`/`green`/`lightRed`…), applied by `cp` (`Wallpaper.qml:104-120`) | No — closest of the four, but ANSI-shaped not base16 | **Declared** `Config.theme.lightMode`; **but the legacy hex selector still uses luminance** — two contradictory mode systems in one shell. OLED mode is force-disabled in light mode (`Config.qml:3368`) | Default, overridable by a preset; matugen run **twice in parallel** (`Wallpaper.qml:357-393`) | **Six QML generators**, no shell scripts — pywal, kitty, GTK, qt-ct, NvChad, Discord, all off one 100 ms timer (`Colors.qml:55-67`) | **7 096** |
| 14 | **ii-vynx** (`repos/vaguesyntax_ii-vynx`) | Identical to end-4 — `diff` is clean | `GridView` + a **staged reveal**: a 16 ms timer increments `loadedCount` and delegates gate on `index < grid.loadedCount` (`WallpaperSelectorContent.qml:573-596`). A rate limiter, not a viewport cull | Dir tree + favourites + Wallhaven + **colour filtering** — an offline matugen colour index, matched in QML (`:128-148`) | Same as end-4; video wallpapers **re-applied on shell start** because mpvpaper does not survive a restart (`services/Wallpapers.qml:52-58`) | **29 themes as JSON files** (`defaults/themes/*.json`, 1 980 lines), extracted from iNiR's `ThemePresets.qml` and reformatted; preview is a hand-painted 3-wedge `Canvas` pie (`ColorPreviewButton.qml:141-168`) | No — matugen snake_case tokens | **Luminance only** (`MaterialThemeLoader.qml`, byte-identical to end-4); no `darkmode` field in any of the 29 JSONs, so `latte` is light purely because `#eff1f5` is bright. Static themes are one-fixed-mode-each and the light/dark toggle is disabled for them (`QuickConfig.qml:238-247`) | Toggle — `scheme-*` → matugen, anything else → file copy | Same as end-4, **but the static-theme branch skips `applycolor.sh`**, so terminals keep the previous palette (`switchwall.sh:363-375`) | **4 519** |

Not found, despite looking: `ags/` and `eww/` on disk are the **upstream framework sources**, not configs — neither contains a wallpaper picker or theme switcher (`eww/examples/` is two configs, `eww-bar` and `data-structures`, with no image widget at all). `aylur-dotfiles/` has no AGS widget tree in this checkout. GNOME was not examined; no GNOME source is on disk.

**Count: 15 real implementations** (rows 0-5, 7-14, plus caelestia-cli as the engine behind row 2), against a corpus (row 6) that is data rather than an implementation.

---

## 2. Recommended design for his shell

Target: **about 300 lines net**, replacing the current 752. Every element is taken from a named file.

### 2.1 Where it lives — a centred overlay, reusing his own launcher

He already has the exact window. `LauncherWindow.qml` (189 lines) is a full-screen transparent `PanelWindow`, `WlrLayershell.layer: WlrLayer.Overlay`, `keyboardFocus: Exclusive` while open, driven by `qs ipc call launcher toggle`. Copy that shell verbatim into `LooksWindow.qml` and delete `cLooks` from the `shell.qml:583` loader chain.

Size it at roughly **800×650**, which is what Noctalia settled on for the same content (`WallpaperPanel.qml:15-18`: `preferredWidth: 800`, `preferredHeight: 650`, both capped at `0.5` of the screen). A centred card, not full-bleed. Two columns — **themes left, wallpapers right** — because picking one usually means picking the other, which is the premise his own `Looks.qml:1-4` comment already states.

The pairing has precedent. Ambxst keeps `WallpapersTab.qml` and `SchemeSelector.qml` in the same `modules/widgets/dashboard/wallpapers/` directory as one dashboard surface — but at 1 227 + 508 lines for the pair (3 568 for the directory), it is a warning about scope, not a model to copy.

Do **not** copy Noctalia's layout: it splits wallpaper (a 1 937-line panel) from colour scheme (a Settings tab) into two surfaces that have to signal each other, and that split is most of why it costs 8 500 lines.

### 2.2 The wallpaper grid

Keep `GridView`. Three changes, each with a source:

1. **Drop the `head -60` cap** (`Wallpapers.qml:80`). `GridView` only instantiates visible delegates, so the cap solves a problem that does not exist while hiding wallpaper 61 onwards. Noctalia lists unbounded with `find -L … -printf "%T@|%p\n"` (`WallpaperService.qml:1152-1177`) and sorts by mtime in JS — same newest-first result, no cap.
2. **Bind `sourceSize` to the real cell size × DPR** rather than the hardcoded 220. Caelestia's entire thumbnail strategy in QML is four lines (`components/images/CachingImage.qml:10-16`):
   ```qml
   asynchronous: true
   fillMode: Image.PreserveAspectCrop
   sourceSize: {
       const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
       return Qt.size(width * dpr, height * dpr);
   }
   ```
   He sets `sourceSize.width` only; setting width alone lets a 5:1 panorama decode enormously tall.
3. **Give the grid a real height.** His `Layout.preferredHeight: 250` with the apologetic comment at `Wallpapers.qml:232-236` exists because the rail panel sizes itself to content. In an overlay the window has a known size, so the grid can simply `Layout.fillHeight: true` and the workaround and its comment both delete.

4. **Set `cache: false` and `retainWhileLoading: true`, not `cache: true`.** He has `cache: true` (`Wallpapers.qml:262`). KDE — the most mature version of this exact grid anywhere — deliberately does the opposite, because `QQuickPixmapCache` otherwise retains every thumbnail the user has scrolled past (`wallpapers/image/imagepackage/contents/ui/WallpaperDelegate.qml:87-95`):
   ```qml
   Image {
       id: previewImage
       anchors.fill: parent
       asynchronous: true
       retainWhileLoading: true
       cache: false
       fillMode: cfg_FillMode
       source: model.preview
   }
   ```
   (`retainWhileLoading` needs Qt 6.8+; the store has qtbase 6.9.3/6.10.2/6.11.1, so it is available.) `retainWhileLoading: true` is what makes `cache: false` tolerable — it holds the old frame while the new one decodes, so nothing flashes to blank on rebind. That pairing is the answer to both the memory question and the flicker question, and it is two properties. It also makes Trap 2 mostly moot.

5. **Add a floor to the downscale.** KDE computes `previewSize` as screen/8 but never below `Kirigami.Units.gridUnit * 22`, with the reason in the comment (`ThumbnailsComponent.qml:164-186`): `// Set minimum image sample size, otherwise it's very blurry`. Binding purely to cell size × DPR (point 2) gives blurry tiles on a small window; take the max of the two.

**Do not build an on-disk thumbnail cache.** Noctalia's `ImageCacheService.qml` is 784 lines with two concurrency queues (`:44-52`), a mtime-keyed sha256 cache, and a 15-day sweep. `sourceSize` + `cache: false` gets the memory win; the disk cache only buys decode speed, and only on a directory far larger than his. Note what KDE does instead: the model stores **no pixmaps at all**, just a URI string (`model/imagelistmodel.cpp:52-57`), and an async image provider resolves it — so preview cost is proportional to visible tiles rather than to directory size. That is the same guarantee `GridView` + `asynchronous` already gives him for free.

### 2.3 Themes and schemes

**Vendor the tinted-theming corpus as one JSON.** All 335 schemes compact to ~115 KB (measured), against Noctalia's 973-line `SchemeDownloader.qml` that hits four GitHub API endpoints to fetch the same kind of data. A build step converts `sch/schemes-spec-0.11/base16/*.yaml` → `themes.json`; the shell does one `JSON.parse`. doannc2212 already proves the shape works: 206 themes in an 89 KB `themes.json` driving a `ListView`.

**List them the way doannc2212 does, not as a grid.** 335 swatch cards is unusable; a search box over a filtered `ListView` is not (`ThemeSwitcher.qml:55-65`, `:354-359`, with the "N of 206" counter at `:229-230`). Keep his existing 4-swatch row from `Looks.qml:59-70` as the delegate — it already works.

**Swatches beat rendered previews here, but know the alternative.** KDE renders each colour scheme as a miniature fake window — a titlebar, a real `Button`, and three `ItemDelegate`s labelled "Normal text" / "Highlighted text" / "Disabled text", with embedded links coloured from `palette.link` (`kcms/colors/ui/main.qml:156-299`) — because a KConfig scheme has 7 role groups that swatches cannot convey. A base16 palette is 16 flat colours, so swatches convey it exactly. Keep swatches. The reason KDE needs more is a property of its format, not of the problem.

**Live preview via a nullable override index.** This is the single best pattern found, and it is six lines (`doannc2212 .../theme-switcher/Theme.qml:21-27`):

```qml
readonly property var current: {
    if (previewIndex >= 0 && previewIndex < themes.length)
        return themes[previewIndex];
    if (wallpaperMode && wallpaperTheme && wallpaperTheme.bgBase)
        return wallpaperTheme;
    return themes[currentIndex];
}
```

Three sources — preview, wallpaper-derived, chosen — resolved in one derived property with no state mutation. His `Theme.palette` becomes this `current`; hovering a row sets `previewIndex`, leaving sets it to `-1`. His "cute little toggle" is then not a feature at all, just the middle branch — which is exactly what `WallMatch.qml` is already doing the hard way with a `prev` snapshot (`WallMatch.qml:62-74`).

### 2.4 Light and dark

**Keep one set of semantic tokens and let the palette flip. Do not add a variant boolean to the shell's colour reads.** His `Theme.qml:26-49` already names `bg`/`fg`/`accent` semantically over base16 slots, and a light base16 scheme runs those slots the other way by construction — so `bg` becomes light and `fg` dark with no code change. The grep confirms he is ready: there are **no hardcoded colours anywhere outside `Theme.qml` and the theme table**, and no `"black"`/`"white"` literals.

**Detect light from the declared field, never luminance.** tinted-theming ships `variant: "dark"|"light"` in every file (`base16/sagelight.yaml:4`); Caelestia declares it too (`Colours.qml:69`). Only projects that threw the field away have to guess — doannc2212 computes Rec.601 luminance (`Theme.qml:33-39`), and Omarchy shows where that ends: four resolution paths accumulated in precedence order (`omarchy-theme-color:119-134`), with luminance last and only for user themes. Carry `variant` through from the YAML and the question never arises.

**Branch in exactly one place: translucency.** **Three** projects independently reached the same conclusion — light mode must be *more opaque*:

- Caelestia, `services/Colours.qml:151`: `base: Math.max(0, Math.min(1, Tokens.transparency.base - (root.light ? 0.1 : 0)))`
- Noctalia, `Commons/Color.qml:352-355`: `return Settings.data.colorSchemes.darkMode ? baseOpacity : Math.pow(baseOpacity, 1.5);`
- iNiR, `modules/common/Appearance.qml:583-594`: one multiplier applied to every alpha at once —
  ```qml
  // Light mode: reduce transparency slightly for better contrast on light wallpapers
  readonly property real _lightFactor: root._auroraLightMode ? 0.75 : 1.0
  readonly property real overlayTransparentize: (_cfg?.overlay ?? 0.30) * _lightFactor
  readonly property real popupTransparentize: (_cfg?.popup ?? 0.32) * _lightFactor
  ```

**iNiR is the model to copy for the branching itself.** It has 152 `darkmode` references but funnels every real branch through **one derived boolean** (`Appearance.qml:78-80`), and there are exactly three branch sites: text colour over glass, the alpha multiplier above, and border alpha. Everything else is *contrast-solved rather than mode-branched* — `ColorUtils.ensureReadable(fg, bg, 4.5)`. That is the pattern worth stealing, because it scales to any scheme rather than to two modes. For his shell it means: if a light scheme ever looks wrong, reach for a readability helper before reaching for `if (light)`.

He has one knob, `Theme.panelOpacity: 0.82` (`Theme.qml:58`), used at `NotifCard.qml:13` and `Osd.qml:104`. Make it derived:

```qml
readonly property bool light: c("variant", "dark") === "light"
readonly property real panelOpacity: light ? 0.92 : 0.82
```

**Decide separately whether a light *shell* means light *terminals*.** This is the one light-mode question his architecture raises that the others do not, because `Scheme.qml` broadcasts the same palette to both. end-4 hit it and added an explicit escape hatch — `switchwall.sh:272-280` passes `--mode light` to matugen for the UI while forcing the terminal generator to `dark`, gated on a config key literally named `forceDarkMode`:
```bash
    # enforce dark mode for terminal
    if [[ -n "$mode_flag" ]]; then
        matugen_args+=(--mode "$mode_flag")
        if [[ $(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode' "$SHELL_CONFIG_FILE") == "true" ]]; then
            generate_colors_material_args+=(--mode "dark")
```
His `Scheme.publish(p)` has one palette and one destination set, so picking a light scheme will repaint every open terminal white with no way to decline. Worth deciding deliberately rather than discovering it — either accept it (defensible: one palette everywhere is the whole premise of `Scheme.qml`) or split the OSC broadcast off behind a flag.

That is the whole light-mode change. The five `Qt.alpha(Theme.accent, …)` selection tints (`Entry.qml:23`, `Looks.qml:68`, `Workspaces.qml:149`, `Graph.qml:44`) are worth re-checking by eye once a light scheme is loaded, but they are alpha over a token that flips, so they should hold.

### 2.5 Applying and persisting the wallpaper

Keep `hyprpaper`. Add the one thing missing: **persist the path and restore it at startup.** Caelestia writes the current path to a state file and a `FileView` reads it back on load, falling back to a shipped default (`services/Wallpapers.qml:85-104`). He already has `Quickshell.statePath` in use for `theme.json` (`Theme.qml:98`), so this is about eight lines.

**"Clicking a result does nothing" was a name collision, and it has just been fixed** — by another agent, while this survey was being written. `Wallpapers.qml` declared `readonly property string pick` and `function pick(cell)` on the same object; the property won, and `root.pick(cell.modelData)` died on `"" is not a function`. The property is now `matchTarget` and the comment at `panels/Wallpapers.qml:36-42` records it. Nothing about the picker's design needs to change for this — but see Trap 17.

### 2.6 Budget

| Piece | Lines | From |
|---|---|---|
| `LooksWindow.qml` — overlay, focus, IPC | ~60 | copied from his `LauncherWindow.qml:1-30` |
| Theme list — search + `ListView` + swatch delegate | ~90 | doannc2212 `ThemeSwitcher.qml` |
| `Theme.qml` — `current` resolution chain + `light` | +15 net | doannc2212 `Theme.qml:21-27` |
| Wallpaper grid | ~80 | his existing `Wallpapers.qml:229-270`, minus the cap and the height workaround |
| wallhaven browse | ~60 | unchanged from `Wallpapers.qml` |
| `themes.json` | 0 (data) | tinted-theming |
| **Total** | **~305** | vs 752 now, vs 8 500 in Noctalia |

---

## 3. Traps

**1. Blocking writes to `/dev/pts` can hang the shell — he has this bug now.**
`Scheme.qml:73` ends with a serial, blocking loop:
```
'for t in /dev/pts/[0-9]*; do printf %s "$s" > "$t" 2>/dev/null; done\n'
```
A pts whose reader is stopped (suspended `less`, a full tty buffer) blocks the write, and `2>/dev/null` hides nothing because blocking is not an error. Both projects that do OSC broadcast guard against exactly this. caelestia-cli opens non-blocking, with the reason in a comment (`caelestia-cli/src/caelestia/utils/theme.py:133-143`):
```python
# Use non-blocking write with timeout to prevent hangs
fd = os.open(str(pt), os.O_WRONLY | os.O_NONBLOCK | os.O_NOCTTY)
```
end-4 instead backgrounds every write (`scripts/colors/applycolor.sh:67-73`): `{ cat … >"$file" } & disown || true`. His fix is one word — background the write inside the loop.

**2. Rebuilding the model flashes every thumbnail.**
Noctalia hit this and left the note (`WallpaperPanel.qml:807-808`):
> `// Reorder wallpaperModel to match filteredItems using in-place moves.`
> `// Avoids clear+rebuild which would destroy delegates and flash thumbnails.`

Any re-sort or re-filter that replaces the model array destroys and recreates delegates, and every `Image` reloads. His `ScriptModel { values: root.cells }` (`Wallpapers.qml:242`) is rebuilt wholesale whenever `root.online` flips or `walls` changes. With `cache: true` the reload is cheap, but it is visible. Filter in the delegate's `visible`, or accept the flash — do not build Noctalia's reconciliation loop.

**3. `sourceSize.width` alone does not bound memory.** Setting one axis lets the other scale freely; a panoramic wallpaper still decodes huge. Caelestia sets both via `Qt.size(…)` (`CachingImage.qml:13-16`); skwd-wall sets both explicitly (`MosaicView.qml:425-426`).

**4. ImageMagick can hang on a corrupt or enormous image.** skwd-wall wraps every invocation (`qml/services/ImageService.qml:29`): `"timeout --kill-after=5 10 magick "`. Noctalia instead caps concurrency at 4 magick processes and 16 utility processes with the reason stated (`ImageCacheService.qml:44-52`): `// Process queues to prevent "too many open files" errors`. Relevant only if he adds a disk cache — which is an argument for not adding one.

**5. A property named `onSomething` is parsed as a signal handler.** Noctalia prefixes its whole palette to dodge this (`Commons/Color.qml:15-17`):
> `NOTE: All color names are prefixed with 'm' (e.g., mPrimary) to prevent QML from misinterpreting them as signals (e.g., the 'onPrimary' property name).`

Not a problem for base16 slot names, but it will bite the moment he adds an `onAccent` or `onSurface`.

**6. A plain JS array as a model segfaults Quickshell on removal.** His own note at `Wallpapers.qml:241` — worth keeping visible, since the overlay rewrite is a chance to accidentally drop `ScriptModel`.

**7. JS objects do not emit change signals, so swatch caches need a manual version counter.** Noctalia carries `property int cacheVersion` and reads it purely to create a dependency (`ColorsSubTab.qml:41-42`): `var _ = cacheVersion;`. Vendoring one `themes.json` avoids this entirely — the array is loaded once and never mutates.

**8. If the variant field is not declared on day one, you accumulate mechanisms.** Omarchy now resolves mode through four paths in precedence order, two of them explicitly legacy (`bin/omarchy-theme-color:119-134`, and the comment at `:17`: `Theme mode precedence: 'mode' key, legacy 'theme_type' key, a light.mode…`).

**9. `cache: true` on a grid thumbnail is a slow memory leak.** Covered in §2.2 point 4 — KDE sets `cache: false` with `retainWhileLoading: true` (`WallpaperDelegate.qml:87-95`) precisely because `QQuickPixmapCache` retains everything scrolled past. He currently has `cache: true` (`Wallpapers.qml:262`). This is the "thumbnail memory on large wallpaper directories" trap in its exact form, and the fix is two properties.

**10. A luminance threshold gets copy-pasted and then drifts.** KDE's `192` appears in three separate files, one carrying the comment `// 192 is from kcm_colors` (`mediaproxy.cpp:231-238`, also `filterproxymodel.cpp:105-115`, `packagelistmodel.cpp:112-117`). Meanwhile caelestia-cli thresholds `Hct.tone > 60` and end-4 thresholds colourfulness at `40` where caelestia uses `10/20` — **the same Hasler–Süsstrunk formula, incomparable numbers, because each reimplemented it**. Another argument for reading the declared `variant` field instead of computing anything.

**11. A lock that silently drops work.** caelestia-cli guards theme application with a `flock` that returns quietly if held (`utils/theme.py:414-418`), so a rapid second theme change is dropped rather than queued — and the lock file is `unlink`ed in a `finally`, which is racy. Relevant because his `Scheme.publish` does `write.running = false; write.running = true`, which has the same shape: fast successive theme clicks cancel rather than queue. Probably fine, but it is a choice, not an accident to inherit.

**12. Directory scanning that is off-thread can still be accidentally quadratic.** KDE scans in `QtConcurrent` with a bindable `loading` property (`imagelistmodel.cpp:120-136`), so the UI never blocks — but the finder itself uses a linear membership test inside the walk (`finder/imagefinder.cpp:63`, `if (!visitQueue.contains(...))`), which is O(n²) in directory count. Off-thread hides it; it does not fix it.

**13. A `Repeater` over a folder model is the one genuinely fatal grid mistake.** Moonveil's hex overlay does exactly this (`WallpaperSelectorContent.qml:267-290`) — a `Repeater` instantiates *every* item, and each one carries an FBO plus two software-rastered `Canvas` surfaces plus a decoded image. There is no `clip`, no scroll view, and the container is sized `rows * cellH`, so with 300 wallpapers it is fifty rows tall and **the ones past the window cannot be reached at all**. His `GridView` is already right; the trap is that a `Repeater` looks simpler and is the natural thing to reach for when moving code into an overlay.

**14. A theme-application path that forgets to publish.** ii-vynx's static-theme branch copies the JSON and returns *without* running `applycolor.sh` (`switchwall.sh:363-375`), so picking `nord` leaves every terminal and GTK app on the previous wallpaper-derived palette. His `Theme.apply()` unconditionally calls `Scheme.publish(p)` (`Theme.qml:94-98`), so he is already immune — worth knowing that the obvious refactor (special-casing the derived path) is how others broke it.

**15. Manual `gc()` and race-delay knobs are the smell of an over-coupled pipeline.** iNiR ships a 2-second timer whose only job is to call `gc()` after each wallpaper change (`services/Wallpapers.qml:98-113`), a 50 ms debounce whose comment names the bug it hides (`MaterialThemeLoader.qml:235-249`, *"races the previous reload op and drops it"*), a 6-attempt **polling** fallback because inotify is unreliable (`:170-194`), and a 3-second suppression window (`:464-473`). end-4 has a config key literally called `arbitraryRaceConditionDelay` (`modules/common/Config.qml:595-597`) and a commented-out `# sleep 0 # idk i wanted some delay or colors dont get applied properly` (`applycolor.sh:13`). All of it comes from the same root cause: state living in files that several writers touch. His design keeps the palette in one `FileView` written only by `Theme.apply` — do not add a second writer.

**16. The same bug survives three forks unfixed.** end-4, Moonveil and ii-vynx all carry a `StdioCollector` that sets `root.directory` to the candidate path *before* reading the validation result, so an invalid path is already applied by the time it is rejected (`end4/services/Wallpapers.qml:89-99`). The odd indentation on that line is the tell. Forked code is not reviewed code.

**17. A property and a function of the same name silently collide, and QML says nothing.**
Found live in his own tree during this survey and fixed concurrently — `panels/Wallpapers.qml:36-42` now carries the post-mortem:
> `A property and a function of the same name are one name on the QObject, the property wins silently, and every click on a wallpaper died on `"" is not a function` with nothing said to anyone.`

This is the failure mode the whole "read other people's QML first" rule exists for: no compile error, no runtime warning, just a dead click. Worth a grep for other collisions before the rewrite, since the overlay will move a lot of names into new scopes.

**18. One malformed file breaks a naive parser.** Of 335 tinted-theming schemes, 334 write `variant: "dark"` and one writes it unquoted. A build-time conversion catches that once; a runtime YAML-ish regex would silently mis-parse it forever.

---

## 4. Where his current approach looks wrong

**The wallpaper cap is the most user-visible defect and it is one line.** `head -60` (`Wallpapers.qml:80`) silently truncates a synced, growing directory. Nothing else in the survey caps: Noctalia and Caelestia both list unbounded and let the view virtualise. This is a workaround for a performance problem `GridView` already solves.

**The `prev` snapshot in `WallMatch.qml` is a state machine where a resolution chain would do.** `toggle()` stashes `Theme.palette` into `prev`, persists it to a second state file, and restores it on the way back (`WallMatch.qml:62-74`). doannc2212 gets the same behaviour by making wallpaper-mode one branch of a derived property (`Theme.qml:21-27`) — nothing is stashed because nothing is overwritten. Adopting §2.3 deletes `wallmatch.json`, the `prev` property, and the restore path.

**Themes as an inline array in a UI file is why there are only seven.** `Looks.qml:40-46` is data living in a view. Every project that ships more than a dozen separates them: Noctalia one JSON per theme, Caelestia one text file per flavour, doannc2212 one JSON for all 206. The corpus he wants is already on disk and costs 115 KB.

**Nothing restores the wallpaper on restart.** `setWall` starts hyprpaper if absent and sets the image (`Wallpapers.qml:161-170`), but no path is persisted — a fresh login gets whatever hyprpaper's own config says, which the shell never writes. He persists the *theme* (`Theme.qml:98`) but not the wallpaper, so the two drift apart after a reboot. That asymmetry is invisible until it happens.

**`base03` is right and the survey supports it.** His `Theme.qml:32-41` comment defends splitting `line` out of `base03`. tinted-theming's spec agrees — `base03` is "Comments, Invisibles, Line Highlighting" — and Caelestia carries a genuine `outline` token separately (`SchemeItem.qml:35`). Worth noting because it is the one place his design is *ahead* of the reference implementations.
