# Requirements

Every requirement Erik has stated, extracted from the session transcript. Nothing
here is inferred — each line traces to something he actually asked for. Keep it
up to date: when a session adds a requirement, add it here, and when one lands,
tick it. This file exists because requirements were being forgotten between turns.

## Rules that govern all work

- [x] Code stays as simple and trivial as possible. Do not over-engineer.
- [x] Always read other projects' QML before writing any. LLMs are bad at QML and
      have too little of it in training data. `docs/catalogue.md` is the index.
- [x] No settings GUI, ever. Configuration is code.
- [x] Never design an animation from scratch — read how other shells do it first.
- [x] Screenshot every visible change and send it in chat. Erik is remote and
      judges only by screenshots.

## Repo and integration

- [x] Public repo `ErikFrankling/quickshell`, separate from dotfiles
- [x] `nix run` starts the shell from the working tree — no rebuild to iterate
- [x] `docs/catalogue.md` — every Quickshell repo above 50 stars
- [x] `docs/gallery.html` — every screenshot found, star sort, tag filter,
      archived images, commit-pinned links
- [x] `AGENTS.md` + `CLAUDE.md` carrying the two rules
- [ ] Imported through Home Manager as part of the declarative config
      *(deferred by Erik until the shell beats what he has now)*
- [ ] Per-host options exposed to the NixOS config (`nix/hm-module.nix`)

## Rail (left sidebar)

- [x] Left sidebar, Noctalia design language
- [x] Concave corners connecting the rail to open panels
- [x] Workspaces show the number and the real icon of the app running there
- [x] Icons sit to the right of the number so numbers stay close together
- [ ] Workspaces always in numerical order — Hyprland reports them unordered
- [x] Always-visible icons carry state, not just an action: bluetooth on/off,
      wifi vs ethernet vs disconnected
- [ ] Network state always readable without opening a panel — wifi, ethernet,
      VPN, and whether the VPN is up
- [x] Tray lives in the rail
- [x] Tray left-click activates
- [ ] Tray right-click opens the application's context menu
- [x] Metric rings in the rail
- [ ] Rings are clickable — no separate system-monitor button
- [ ] Theme button sits with the other buttons
- [ ] No launcher button in the rail
- [ ] Rail is not cramped

## Panels

- [ ] Panels are only as tall and wide as their content — never full height
- [ ] Escape closes whatever panel is open
- [ ] Opening a panel must not change the rail's width
- [x] Do-not-disturb removed entirely
- [x] Wifi panel
- [x] Bluetooth panel
- [x] Brightness slider (laptop only)
- [ ] Audio: per-application volume, and input and output device selection
- [x] Media player: what is playing, and track switching
- [x] Notification centre

## Notifications

- [x] Popups appear on screen and expire on their own
- [x] History persists until explicitly dismissed, and is scrollable
- [x] Save a notification for later, to act on it another time
- [x] Translucent so you can see what is behind them
- [x] HTML/markup in bodies renders instead of showing raw tags *(AGS, shipped)*
- [x] Multi-message notifications are not squished together *(AGS, shipped)*

## Metrics

- [x] Rings fill as the resource approaches its limit
- [x] Reuse the existing waybar scripts rather than reimplementing them
- [ ] Graphs for every metric, not just CPU and memory
- [ ] Temperature, fan speed, swap usage, swap transfer rate, network throughput
- [ ] Capability detection — no GPU ring on a host without a GPU

## Theming

- [x] Theme switcher listing every theme
- [x] Wallpaper switcher that actually applies the wallpaper
- [x] Download wallpapers from the popular wallpaper sites
- [x] Theme changes apply instantly at runtime — no rebuild
- [ ] Theme written in a standard format so other applications follow it too,
      rather than a bespoke scheme only this shell understands
- [x] A theme is colour only here; fonts, spacing, radii stay hardcoded

## Launcher

- [x] Centred overlay window on top of everything
- [ ] Wired up, and not reachable from a rail button

## Research, for discussion rather than implementation

- [x] Can the QMK/Vial layout of the Dactyl be rendered as a cheatsheet?
- [x] Can Hyprland's binds be read (via hyprctl, not by parsing config)?
- [x] Can Neovim's keymaps be read?
