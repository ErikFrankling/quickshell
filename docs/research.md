# Replacing AGS + waybar with a Quickshell desktop shell

Research report, 2026-07-28. Context: NixOS + Hyprland + home-manager, currently running
waybar for the bar and a hand-written AGS/Astal shell (`ErikFrankling/AGS`) as the
notification daemon.

Goals stated up front, because everything below is judged against them:

- one shell process that owns the bar, notifications, and widgets
- notifications surfaced **in the top bar**, with real hide rules and a
  **save-for-later / act-on-it-later** triage model
- theme switcher, and a wallpaper picker where wallpaper and theme move together
- **light**. No settings GUI. Not a product for strangers — a config to be edited directly
- start from something already functional, then cut it down

---

## 1. Recommendation

**Fork [`doannc2212/quickshell-config`](https://github.com/doannc2212/quickshell-config)
(28 files, 5,309 LOC) and port a notification service into it.**

It is the only project found that already has the theme-switcher-plus-wallpaper-picker half
built, with the loosest coupling measured anywhere: each module folder carries its own
`DefaultTheme.qml` fallback and receives the live theme through an explicit `theme:` property,
so the global `Theme` singleton is referenced in **1 of 28 files** (compare 66% for
DankMaterialShell). Largest file is 650 lines. It has no settings GUI. Deleting the parts you
don't want is a one-line change per module.

What it lacks is the notification half — popups only, no persistent centre. That is the part
you actually want to design anyway, and against 5.3k LOC you can hold the whole codebase in
your head while doing it.

**Second choice:** [`Rexcrazy804/Zaphkiel`](https://github.com/Rexcrazy804/Zaphkiel)'s
`kurukurubar` (61 files, 6,791 LOC) — the best Nix story of any small config, MIT, median file
65 lines. But it's a notch/island rather than a flat top bar, so a waybar-shaped replacement
means reworking `Layers/Notch.qml`.

**Do not fork the big four.** Sizes are verified by clone and `wc -l`, not estimated:

| Project | QML LOC | Why not |
|---|---|---|
| DankMaterialShell | 200,225 | `Theme` in 370/559 files; `SettingsData` is a 587-property god-singleton; mandatory 491-file Go daemon. Best Nix support in the ecosystem, worst fit here. |
| Noctalia v4.7.7 | 119,441 | This is the one already in your config, and the size is exactly why it felt "too big". |
| Ambxst | 78,160 | |
| end-4 illogical-impulse | 56,701 | Ships two competing shell designs plus an AI chat client, booru browser, on-screen keyboard, LaTeX rendering and Shazam. Nix is a self-described WIP. |
| caelestia | 38,892 + 15,856 C++ | Cleanest engineering of the four, but **the config system is C++** — adding an option means editing C++, not QML. Theming needs a Python CLI to work at all. |
| Omarchy `quattro` | 31,998 | Architecturally the most interesting thing in the survey, but shells out to 72 `omarchy-*` bash scripts, zero Nix, Arch-coupled, unreleased in an open PR. |

---

## 2. Two corrections to the premise

**Noctalia is no longer a Quickshell config.** `noctalia-dev/noctalia-shell` now redirects to
[`noctalia-dev/noctalia`](https://github.com/noctalia-dev/noctalia); **v5 is a native C++23
Wayland/OpenGL-ES rewrite with no Qt and no Quickshell**, zero `.qml` at HEAD. The QML era ends
at [`v4.7.7`](https://github.com/noctalia-dev/noctalia/tree/v4.7.7). Your
`modules/home-manager/noctalia.nix` is written against the v4 option name
(`programs.noctalia-shell`, renamed to `programs.noctalia` upstream) — harmless today only
because the import is commented out in `hosts/pc/home.nix:87`.

Noctalia v5 is still the most important project to read, for two reasons in §5 and §6.

**QML is the DSL.** There is no separate DSL layered on top, and there is **no TypeScript
story at all** — config is QML plus Qt's JavaScript engine. Type annotations
(`function f(x: string): int`) are optional and are hints for tooling, not a type system.
You get `qmlls` autocomplete and `qmllint`, not soundness. On the "does it type-check" axis
this is strictly worse than AGS/Astal's TypeScript path.

---

## 3. Is Quickshell actually better than AGS?

**On docs: yes, and the reason is structural rather than editorial.**

- The type reference is **auto-generated from source** and covers every type, property and
  signal with defaults. It cannot rot the way a hand-written reference does. That is the
  specific thing AGS lacked.
- You inherit **the entire Qt/QtQuick corpus** — 15 years of documentation, Stack Overflow
  answers and books for layouts, animations, `Repeater`, `ListView`, `MouseArea`, shaders.
  Quickshell only has to document its own ~130 types.
- `qmlls` works, and Quickshell **auto-populates `.qmlls.ini`** with the right import paths at
  runtime. Create the file empty and gitignore it.
- Versioned docs (v0.1 → v0.3) and a changelog with explicit breaking-change callouts.

**Where it is genuinely weak, and you should budget for it:** the usage guide is **7 pages**
and there is **no "build a bar" tutorial** — the single most common use case is undocumented
end to end. The official examples repo has `lockscreen`, `mixer`, `wlogout`, `volume-osd`,
`activate_linux`, `focus_following_panel`, `reload-popup` — **and no bar**. Theming, popups and
scroll input are all "read someone else's config" territory; that is
[quickshell-docs#3](https://github.com/quickshell-mirror/quickshell-docs/issues/3), open, in
the maintainers' own tracker. Plan on reading a real config for a weekend.

**On stability:** the breaking-changes reputation is mostly pre-0.1. Since then the churn has
been small and documented — v0.3.0's only breaking change was "config paths are no longer
canonicalized". The real trap is that **many popular configs track `master`, not tags**, and
`master` has no compatibility guarantee. Pin nixpkgs' `quickshell` (0.3.0, maintained by
upstream's own author) and check what a config requires before adopting it.

**Capabilities** — everything needed to drop waybar *and* the notification daemon is
first-class: `PanelWindow`/`WlrLayershell` (layer-shell bar), `Quickshell.Services.Notifications`
(a real `org.freedesktop.Notifications` server), `SystemTray` + `DBusMenu` (SNI, the thing that
makes waybar's tray work), `Mpris`, native `Pipewire` (including `PwNodePeakMonitor` for
visualisers without cava), `Bluetooth`, `Networking`, `UPower`, `Polkit`, `Pam`, `Greetd`,
`ScreencopyView`, and a dedicated `Quickshell.Hyprland` module. No brightness module yet —
shell out to `brightnessctl`.

---

## 4. Integrating it into your config

**You do not need to write a flake with a home-manager module.** Home Manager has a built-in
[`programs.quickshell`](https://github.com/nix-community/home-manager/blob/master/modules/programs/quickshell.nix)
module (present in 25.11+, absent in 25.05):

```nix
programs.quickshell = {
  enable = true;
  configs.mine = ./quickshell;      # → ~/.config/quickshell/mine
  activeConfig = "mine";
  systemd.enable = true;            # unit bound to hyprland-session.target, Restart=on-failure
};
```

`configs` is an attrset of *named* directories, so `dev` and `stable` can coexist and you swap
`activeConfig`. A separate public repo for the QML still makes sense — but it can be a plain
repo you point a path at, rather than a flake exposing a module. If you do want the flake +
`homeModules.default` shape anyway, [noctalia v4's
`flake.nix`](https://github.com/noctalia-dev/noctalia/blob/v4.7.7/flake.nix) is the cleanest
template in the ecosystem.

Things that will bite:

- **Set `//@ pragma ShellId <name>`** at the top of `shell.qml`. Since 0.3 the shell ID derives
  from the config path; without this, every rebuild rotates your state/cache directory.
- **Don't run it from both `exec-once` and systemd** — two instances fight over the
  `org.freedesktop.Notifications` bus name and the tray.
- **Every notification capability except `bodySupported` is off by default.** If actions or
  images don't work, you didn't set `actionsSupported` / `imageSupported`.
- **Hot reload vs the Nix store.** `programs.quickshell` symlinks the config read-only into the
  store, so edit-save-reload doesn't work while authoring. Run `qs -p ~/dev/myshell` against
  your working tree during development, or add a `localDev.enable` flag that swaps
  `xdg.configFile."quickshell".source` to
  `config.lib.file.mkOutOfStoreSymlink` — that idea is from
  [`calops/nix`](https://github.com/calops/nix) and is the single best Nix trick found.
- **Bind keys via IPC, not `GlobalShortcut`.** `GlobalShortcut` is Hyprland-only by design
  (they explicitly rejected the xdg portal) and *crashes* on `appid:name` collision. Instead:

  ```qml
  IpcHandler { target: "launcher"; function toggle(): void { ... } }
  ```
  ```
  bind = SUPER, D, exec, qs -c mine ipc call launcher toggle
  ```

---

## 5. Notifications — the design worth building

This is where the ecosystem is weakest and where the opportunity is.

**Nobody on Linux has per-notification snooze.** Not dunst
([#1304](https://github.com/dunst-project/dunst/issues/1304), open since 2024), not KDE
([445560](https://bugs.kde.org/show_bug.cgi?id=445560), CONFIRMED since 2021), not GNOME
([#7506](https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/7506)), not swaync
([#299](https://github.com/ErikReider/SwayNotificationCenter/issues/299), zero maintainer
response in three years), not mako. Not one of the five Quickshell shells surveyed.

**The structural blocker**, stated precisely in dunst #1304: every daemon emits
`NotificationClosed` before archiving, which invalidates the ID and tears down the sending
app's action handlers. A restored notification is a dead husk — text you can read, buttons that
do nothing.

**Noctalia v5 solved it**, in
[`src/notification/notification_manager.cpp`](https://github.com/noctalia-dev/noctalia/blob/main/src/notification/notification_manager.cpp):

```cpp
/// Expired notifications with actions: NotificationClosed deferred until dismiss, action,
/// or history removal.
std::unordered_set<uint32_t> m_pendingDBusClose;
...
const bool deferDBusClose = reason == CloseReason::Expired && notificationHasInvokableActions(closed);
if (deferDBusClose) { m_pendingDBusClose.insert(id); }
else if (m_closeCallback) { m_closeCallback(id, reason); }
```

**Don't emit `NotificationClosed` when a notification with actions expires.** The sender keeps
its handlers, the ID stays valid, and the notification stays *actionable* from your history
panel indefinitely. That one trick is what turns "save for later" from a text log into a real
inbox — you can hit Reply on a Discord message three hours later.

**State model.** Omarchy's is the best in the survey and the only one with real unread
semantics: three models — `popupModel` (on screen), `pendingModel` (arrived, not yet seen;
DND-suppressed items land here), `pastModel` (seen, rolling TTL) — with `markAllSeen()` moving
pending → past. Add a fourth bucket, `deferred`, carrying a wake time, and because of the
deferred-close trick the actions still work when it resurfaces. That is the snooze.

**Storage.** Copy [xfce4-notifyd](https://gitlab.xfce.org/apps/xfce4-notifyd)'s schema and
D-Bus surface — it is the best notification-history API on Linux and nobody outside XFCE uses
it. Real wall-clock timestamp *plus timezone*, `is_read`, serialised actions, and
`List(start_after_id, count, only_unread)` / `HasUnread()` / `GetAppIdCounts()` /
`MarkRead` / `Truncate(keep)` with row-level change signals. Its
`log-level = not-fully-shown` default is the right instinct too: **only persist notifications
the user didn't actually see**, so the inbox stays triageable instead of becoming a firehose.

Other things to steal:

- **Rules engine**: DankMaterialShell's shape (field × matchType × action, first match wins),
  extended with Noctalia v5's outcome flags (`showToast` / `saveHistory` / `playSound` /
  `overrideDuration` / `allowedUrgencies`) and swaync's `override-urgency`.
- **Two-layer DND persistence** (Omarchy) — `PersistentProperties` for QML reload, a versioned
  JSON key for process restart. caelestia, end-4 and Noctalia v4 all lose DND on restart.
- **Timed DND with presets** (15m/30m/1h/3h/8h/until-8AM), and Plasma's automatic rules:
  `WhenScreensMirrored`, `WhenScreenSharing`, `WhenFullscreen`.
- **Curated DND bypass, not bare urgency** — chat apps abuse `urgency=critical`. Gate on
  `critical AND app in allowlist`.
- **Put history in `$XDG_STATE_HOME`, not `$XDG_CACHE_HOME`.** Three of five Quickshell shells
  get this wrong. It is user state, not regeneratable cache.
- **Re-render and content-hash notification images** (caelestia) — `image://qsimage/...` URLs
  are dead after restart, so persisted thumbnails break everywhere that just stores the URL.
- **Quickshell provides zero persistence.** A `Notification` is a live C++ object that dies
  when the sender closes it. Every shell snapshots to plain JS on arrival and hand-rolls JSON.
  Landmine documented by Omarchy: storing a `Notification` QObject in a `ListModel` role
  **segfaults** `QQmlListModel::data` once the server destroys it — keep live refs in a
  separate JS map.

**Bar badge.** Four unread models are in use, worst to best: live-list length (DMS, resets when
popups expire); a counter reset when the panel opens (end-4, desyncs from "clear all"); a
persisted `lastSeenTs` watermark (Noctalia v4, survives restart, cheap); and pending/past
buckets with `markAllSeen()` (Omarchy — the only one that models "I saw this but haven't dealt
with it"). Almost everyone renders a bare dot; only end-4 offers a number, off by default.

---

## 6. Theming, wallpapers, and the NixOS tension

**The generators.** `matugen` (Rust, Material You + base16, has a HM module) is what the
Material-You shells use. `wallust` (Rust, 16-colour, built specifically because pywal's
ImageMagick shell-out made wallpaper cycling laggy). `pywal16` (Python, legacy). Note caelestia
uses **neither** — it ships its own generator in `caelestia-dots/cli`.

**The shared pattern** across every Quickshell shell is a two-process split: an external
CLI/daemon computes the palette and writes a JSON scheme file; the QML side just watches it.

```qml
FileView {
    path: `${Paths.state}/scheme.json`
    watchChanges: true
    onFileChanged: reload()
}
```

**The NixOS problem**, stated plainly: home-manager renders config into `/nix/store` and
symlinks it read-only into `~/.config`. A runtime theme generator wants to *write* those exact
paths. These are directly incompatible, and nobody triggers `home-manager switch` on wallpaper
change — far too slow.

- **stylix** is fully declarative and cannot switch at runtime.
  [Issue #447](https://github.com/nix-community/stylix/issues/447) ("toggling between Light and
  Dark") has been open since June 2024 with 35 comments and no resolution.
- **matugen's HM module** runs matugen at eval time inside a derivation. Structurally incapable
  of runtime switching — the wallpaper is a `lib.types.path` baked into a build.
- **nix-colors was archived 2026-04-24.** Don't build on it.
- **Specialisations** work for *N discrete themes* (`/specialisation/light/activate`), not for
  arbitrary wallpaper-derived palettes.

**The answer is Noctalia v5's layered config**, and it is explicitly designed for this:

- **base:** `~/.config/noctalia/*.toml` — all files read, sorted, merged. Can be a read-only
  `/nix/store` symlink from home-manager.
- **overrides:** `~/.local/state/noctalia/settings.toml` — written at runtime, wins.
- If the runtime layer writes a value equal to the resolved base value, **the redundant key is
  removed** rather than kept — so your declarative changes keep taking effect.
- inotify watches both, **including symlink-target directories**, so a rebuild swapping the
  store path is picked up live.

Their docs say it outright: *"Keeping it outside `~/.config` also lets the GUI save changes
when your config directory is read-only, for example on NixOS."*

**For the light/dark axis specifically, implement the portal.**
[darkman](https://gitlab.com/WhyNotHugo/darkman) implements
`org.freedesktop.impl.portal.Settings` for `org.freedesktop.appearance/color-scheme` itself.
GTK4/libadwaita, Firefox and Chromium all follow that with **no rebuild and no file writes at
all**. Your shell could own that interface directly. (Relevant to the bug fixed earlier today:
GTK4 reads `color-scheme` from the *portal* namespace, not gsettings.)

**Propagation mechanics that actually trigger a runtime reload** — the part usually hand-waved:

- **Terminals:** build OSC sequences and write them straight to every `/dev/pts/N` with
  `O_NONBLOCK`. Recolours every running terminal instantly, no per-emulator support needed.
  (caelestia, `src/caelestia/utils/theme.py`)
- **GTK: `~/.config/gtk-N.0/gtk.css` is never live-reloaded.** Traced to source — in both GTK3
  and GTK4, `settings_init_style()` loads it **once** into a `static GtkCssProvider` behind
  `if (G_UNLIKELY (!css_provider))`, and there is no `g_file_monitor` anywhere in
  `gtksettings.c` or `gtkcssprovider.c`. The widespread belief that GTK watches `gtk.css` comes
  from GTK Inspector's Custom CSS tab, which uses its own provider.

  What *does* reload is the **named theme**: `settings_update_theme()` fires on
  `notify::gtk-theme-name` → `gtk_css_provider_load_named()` → `gtk_css_provider_reset()` +
  re-read from disk. So the working trick is to install the generated CSS as a *theme* and flip
  the name:

  ```bash
  install -Dm644 gen.css ~/.local/share/themes/MatYou-a/gtk-4.0/gtk.css
  gsettings set org.gnome.desktop.interface gtk-theme 'MatYou-b'   # must CHANGE to notify
  gsettings set org.gnome.desktop.interface gtk-theme 'MatYou-a'
  ```

  Two traps: `GTK_THEME` is checked first and unconditionally in `get_theme_name()`, so if it's
  exported anywhere the flip is silently ignored — and **libadwaita apps are immune**, because
  `adw-style-manager.c` pins `gtk-theme-name` to `"Adwaita-empty"` on purpose.
- **The portal is the runtime channel on Wayland.** GTK4 on Wayland has *no* GSettings backend
  for interface settings at all — `gdksettings-wayland.c` reads them exclusively from
  `org.freedesktop.portal.Settings` (`ReadAll` + `SettingChanged`). And
  `xdg-desktop-portal-hyprland` does **not** implement `org.freedesktop.impl.portal.Settings`,
  so you need `xdg-desktop-portal-gtk` in `extraPortals` with
  `config.hyprland."org.freedesktop.impl.portal.Settings" = [ "gtk" ]`.
- **libadwaita accent colours cannot take an arbitrary palette.**
  `org.gnome.desktop.interface accent-color` is an *enum* (blue/teal/green/…). The portal's
  `accent-color` key is an arbitrary `(ddd)`, but only xdg-desktop-portal-gnome implements it.
  This is a hard wall, not a Nix problem.
- **Qt:** qt5ct/qt6ct genuinely do live-reload — but the watcher is on the **directory**
  `~/.config/qt6ct`, not `colors/`, with a **3-second debounce**, so writing only
  `colors/matyou.conf` fires nothing; you must also `touch ~/.config/qt6ct/qt6ct.conf`. And it
  is all inside `#ifdef QT_WIDGETS_LIB` — **Qt Quick/QML-only apps get nothing**.
  **Kvantum cannot live-reload at all**, by design ("being a style plugin, Kvantum can't apply
  its themes on the fly" — maintainer). Stylix's Qt target *generates a Kvantum theme*, so
  Stylix's Qt colours are restart-only regardless.
- **kitty:** `auto_reload_config` has defaulted to **on** since kitty 0.47.0 (2026-05-19), so
  the sidecar+`include` pattern just works. **Your `kitty.nix:23` sets `auto_reload_config = -1`**,
  which disables it — worth revisiting. Otherwise `pkill -USR1 -x kitty` or `kitty @ set-colors`.
  ⚠️ If `dark-theme.auto.conf` / `light-theme.auto.conf` exist they override everything,
  including dynamic `set-colors`.
- **Neovim:** the `Signal` autocmd supports **only `SIGUSR1` and `SIGWINCH`** — so
  `vim.api.nvim_create_autocmd('Signal', { pattern = 'SIGUSR1', callback = … dofile … })` plus
  `pkill -USR1 -x nvim` is the simplest robust path. If you iterate sockets instead, prefer
  `--remote-expr` over `--remote-send` (the latter injects keystrokes and corrupts
  insert/terminal/operator-pending state).
- **alacritty** watches recursively-imported files too; **wezterm** needs a `touch` of the top
  file; **foot** only has SIGUSR1/USR2 → two fixed themes, so arbitrary palettes need OSC to
  `/dev/pts/*`.
- **btop/htop/cava:** `SIGUSR2`.
- **Zed:** resolve symlinks before writing — its file watcher doesn't follow them.
- Wrap the whole application in **atomic writes plus an `fcntl` lock**; wallpaper cyclers fire
  fast and will race.

**Home Manager fights you less than its reputation suggests.** Verified on this machine: HM
symlinks **individual leaf files, not directories** — `~/.config/gtk-3.0/` and
`~/.config/kitty/` are real writable directories containing store symlinks for just the files
HM owns. So a runtime generator can freely drop `colors.css` next to them. The one exception is
`xdg.configFile."foo".source = someDir` *without* `recursive = true`, which symlinks the whole
directory and locks it — so **always set `recursive = true` on template directories**.

**Rebuild-per-wallpaper-change is measurably out.** Timed on your flake, warm eval cache:
`nix eval …framework…toplevel.drvPath` took **1m45s–1m52s** — evaluation alone, before any
build or activation. Specialisations move that cost off the critical path but only give you a
fixed finite set of themes, which is exactly wrong for "palette derived from an arbitrary
image". Rebuild-driven theming works for light/dark; it does not work for Material You.

---

## 7. Hyprland is already on Lua

Not a proposal — shipped in **0.55.0 (2026-05-09)**, and the wiki states *"Since Hyprland 0.55,
hyprlang is deprecated in favor of lua"*, with support for **1–2 releases**. Current release is
0.56.1. Announcement: <https://hypr.land/news/26_lua/>.

- Config is `~/.config/hypr/hyprland.lua`, everything on a global `hl` table. Binds return
  handles (`:set_enabled(false)`), loops work, window rules become structured tables with a
  `match` block, `exec-once` becomes `hl.on("hyprland.start", fn)`.
- New capabilities: event callbacks (`hl.on("window.open", …)`), timers, in-process state
  queries (`hl.get_windows()`), and **user-defined layouts in Lua** (`hl.register_layout`) —
  previously a C++ plugin.
- Home Manager supports it: `wayland.windowManager.hyprland.configType` is an enum
  `[ "hyprlang" "lua" ]` that **defaults to `"lua"` at `stateVersion >= 26.05`**. You are on
  25.05, so you are still on hyprlang and haven't noticed.
- **`hyprctl dispatch` now evaluates its argument as Lua.** `dispatch workspace 2` errors;
  it must be `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'`. This already silently broke
  Waybar's workspace clicks ([Alexays/Waybar#5008](https://github.com/Alexays/Waybar/issues/5008)).
  Branch on `hyprctl status`, which reports the config format.
- **Lua does not dissolve the IPC boundary for an external shell.** The Lua VM lives inside the
  compositor; an external process cannot register callbacks. Quickshell's `Quickshell.Hyprland`
  is still a C++ singleton over the two sockets. The tighter-integration win is *not* Lua — it's
  Omarchy's single-process model, where summoning a panel is an IPC call into an already-warm
  process instead of a cold `quickshell -p` start.

**This should be a separate PR from the shell work**, and it is the more time-sensitive of the
two — hyprlang has roughly one release left.

---

## 8. Catalogue

### Big projects
[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) ·
[caelestia-dots/shell](https://github.com/caelestia-dots/shell) ·
[AvengeMedia/DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) ·
[noctalia](https://github.com/noctalia-dev/noctalia) ([v4.7.7 QML](https://github.com/noctalia-dev/noctalia/tree/v4.7.7)) ·
[basecamp/omarchy](https://github.com/basecamp/omarchy/tree/quattro/shell) ·
[Axenide/Ambxst](https://github.com/Axenide/Ambxst) ·
[eq-desktop/eqsh](https://github.com/eq-desktop/eqsh) ·
[AhmedSaadi0/NibrasShell](https://github.com/AhmedSaadi0/NibrasShell) ·
[AxOS-project/Sleex](https://github.com/AxOS-project/Sleex)

### Best-architected small configs — read these
[doannc2212/quickshell-config](https://github.com/doannc2212/quickshell-config) ·
[entailz/thorn](https://github.com/entailz/thorn) ·
[s3rven/silere-shell](https://github.com/s3rven/silere-shell) ·
[retinotopic/CuteShell](https://github.com/retinotopic/CuteShell) ·
[rdnamil/rdnashell](https://github.com/rdnamil/rdnashell) ·
[MannuVilasara/xenon-shell](https://github.com/MannuVilasara/xenon-shell) ·
[hashankur/desktop-shell](https://github.com/hashankur/desktop-shell) ·
[octagonemusic/octashell](https://github.com/octagonemusic/octashell) ·
[stormy-soul/sshell](https://github.com/stormy-soul/sshell) ·
[tpaau/shell](https://github.com/tpaau/shell) ·
[josecriane/quickshell-config](https://github.com/josecriane/quickshell-config) ·
[shub39/dotfiles](https://github.com/shub39/dotfiles) ·
[chaeu-srk/cshell](https://github.com/chaeu-srk/cshell) (smallest complete config found)

### NixOS / home-manager references
[wochap/nix-config](https://github.com/wochap/nix-config) (best overall — ~30 `S*.qml` service
singletons, generates light+dark theme JSON at build time and swaps a symlink at runtime) ·
[calops/nix](https://github.com/calops/nix) (the `localDev` mutable-symlink escape hatch, GLSL
shaders) · [Rexcrazy804/Zaphkiel](https://github.com/Rexcrazy804/Zaphkiel) ·
[TLSingh1/dotfiles](https://github.com/TLSingh1/dotfiles) ·
[asteriau/dotfiles](https://github.com/asteriau/dotfiles) (most decomposed Nix wiring) ·
[mewoocat/NixOS](https://github.com/mewoocat/NixOS) (widget component library + draggable grid) ·
[MaySeikatsu/nixos](https://github.com/MaySeikatsu/nixos) (declaratively themes *third-party*
shells by writing their JSON) · [matthis-k/qs-flake](https://github.com/matthis-k/qs-flake)
(shell as its own flake — the repo-separation model) ·
[isabelroses/dotfiles](https://github.com/isabelroses/dotfiles) ·
[MannuVilasara/qswitch](https://github.com/MannuVilasara/qswitch) (CLI to switch configs)

### Components worth stealing outright
[Shanu-Kumawat/quickshell-overview](https://github.com/Shanu-Kumawat/quickshell-overview) ·
[dom0/qs-hyprview](https://github.com/dom0/qs-hyprview) ·
[samjoshuadud/waylandar](https://github.com/samjoshuadud/waylandar) (calendar w/ Google/CalDAV
sync, has a flake) · [maria-rcks/dropdeck](https://github.com/maria-rcks/dropdeck) ·
[Ronin-CK/QuickSnip](https://github.com/Ronin-CK/QuickSnip) ·
[liixini/skwd-wall](https://github.com/liixini/skwd-wall) `data/matugen/templates/` (18 ready
matugen templates — take the templates, not the app)

### Notification/theming source to read before writing any
- [Noctalia v5 `notification_manager.cpp`](https://github.com/noctalia-dev/noctalia/blob/main/src/notification/notification_manager.cpp) — deferred close
- [Omarchy `shell/plugins/notifications/Service.qml`](https://github.com/basecamp/omarchy/blob/quattro/shell/plugins/notifications/Service.qml) — pending/past model
- [DMS `Services/NotificationService.qml`](https://github.com/AvengeMedia/DankMaterialShell/blob/master/quickshell/Services/NotificationService.qml) — rules engine
- [Gakuseei/Ricelin `pill/Singletons/Notifs.qml`](https://github.com/Gakuseei/Ricelin) — best-documented model
- [caelestia `src/caelestia/utils/theme.py`](https://github.com/caelestia-dots/cli/blob/main/src/caelestia/utils/theme.py) — theme propagation
- [diinki/linux-retroism `Config.qml` + `popups/ThemeMenu.qml`](https://github.com/diinki/linux-retroism) — themes as a dict, each with a `defaultWallpaperPath`; the wallpaper-tied-to-theme model in 1,910 LOC
- [freedesktop notification spec v1.3](https://specifications.freedesktop.org/notification-spec/latest/)

### Rices, for looks only
surface-dots · skwd · rumda · Ricelin · amadeus · hyprzepyx · matteogini · whisker · luyu-wu ·
bjarneo · Hyprdots · lyne-dots · meloworld · Hecate · vroomies · R7rainz · yahr ·
linux-retroism · fibreglass · ChromeX · nullframe · Moonlit · Niruv · NothingLess · Aethr ·
basedgoose · Persona-Quickshell · Unit-3 · cartoon-shell · Brain_Shell · nandoroid ·
StatIndet · tripathiji1312 · dhrruvsharma · 0Crazy-0

---

## 9. Verified locally on `pc`

Ran against nixpkgs `quickshell` 0.3.0 on Hyprland 0.55.4, one at a time, screenshotted:

| | Result |
|---|---|
| doannc2212 | ✅ ran clean, picked up real workspaces/tray/MPRIS |
| tripathiji1312 | ✅ ran, floating-pill bar |
| josecriane | ⚠️ ran but renders wrong — wants a Material Symbols font that isn't installed, so ligature names leak as text; niri-targeted, so no workspaces |
| shub39 | ❌ `module "Qt5Compat.GraphicalEffects" is not installed` |
| caelestia | ✅ ran, vertical left bar, took over the wallpaper |
| DankMaterialShell | ❌ needs `qs` on `PATH` and more setup than a bare invocation |

Missing-QML-module failures are the recurring theme and the reason the packaged shells wrap
`qs` with `quickshell.withModules [...]` rather than relying on the bare binary.

---

## 10. Open questions

1. **Fork doannc2212, or start from `chaeu-srk/cshell`-sized scaffolding?** Forking gets a
   working theme/wallpaper system on day one; starting clean means no inherited idioms. The
   recommendation above assumes forking, but the gap is smaller than it looks.
2. **Own repo as a flake, or a plain directory `programs.quickshell.configs` points at?** Plain
   directory is simpler and loses nothing unless you want others to consume it.
3. **How far to take the notification inbox?** The deferred-close trick is cheap. A full
   snooze/pin/todo system with its own storage schema is a project in itself — worth scoping
   separately.
4. **Hyprland-Lua migration: before, during, or after?** Recommendation: before, and separately.
   It is time-boxed by upstream deprecation and touches different files.
