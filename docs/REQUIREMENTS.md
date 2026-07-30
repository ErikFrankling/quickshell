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
- [x] Per-host options exposed to the NixOS config (`nix/hm-module.nix`)

## Rail (left sidebar)

- [x] Left sidebar, Noctalia design language
- [ ] Concave corners connecting the rail to open panels
      *(REOPENED. An agent detached the cards and called the corners obsolete,
      but Erik asked for both in one sentence: "the menu only as tall and wide
      as the content that fills it and then those rounded corners to connect
      it — it is noctalia, this is what noctalia is good at". Dropping them was
      a design decision recorded as a consequence. `ConcaveCorner.qml` is dead
      code today and draws a lens, not a fillet; it needs fixing first.)*
- [x] Workspaces show the number and the real icon of the app running there
- [x] Icons sit to the right of the number so numbers stay close together
- [x] Workspaces always in numerical order — Hyprland reports them unordered
- [x] Always-visible icons carry state, not just an action: bluetooth on/off,
      wifi vs ethernet vs disconnected
- [x] Network state always readable without opening a panel — wifi, ethernet,
      VPN, and whether the VPN is up
- [x] Tray lives in the rail
- [x] Tray left-click activates
- [x] Tray right-click opens the application's context menu
- [x] Metric rings in the rail
- [x] Rings are clickable — no separate system-monitor button
- [x] Theme button sits with the other buttons
- [x] No launcher button in the rail
- [ ] Rail is not cramped
- [ ] The rail carries as many metrics as his waybar does. It currently shows
      four of about eleven — fan, swap, both disks, VRAM and **battery** all
      need a panel opened. On the laptop that is a regression against waybar.
- [ ] Bluetooth panel clips its device list — the first row is cut by the
      card edge

## Panels

- [x] Panels are only as tall and wide as their content — never full height
- [x] Escape closes whatever panel is open
- [x] Opening a panel must not change the rail's width
- [x] Do-not-disturb removed entirely
- [x] Wifi panel
- [x] Bluetooth panel
- [x] Brightness slider (laptop only)
- [x] Audio: per-application volume, and input and output device selection
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
- [x] Temperature, fan speed, swap usage, swap transfer rate, network throughput
- [x] Capability detection — no GPU ring on a host without a GPU
- [x] Graph only what moves. Disk usage and battery are flat over a
      two-minute window, so they get a number, not a graph. *(An earlier pass
      graphed everything; that was too literal a reading of "graphs for every
      metric".)*
- [x] Disk read and write throughput as a graph, like btop
- [x] Say on screen how far back the graphs go
- [ ] Battery over 24h would be interesting but needs persisted history —
      *explicitly out of scope: "that is an entirely different application,
      won't be doing that now"*

## Theming

- [x] Theme switcher listing every theme
- [x] Wallpaper switcher that actually applies the wallpaper
- [x] Download wallpapers from the popular wallpaper sites
- [x] Theme changes apply instantly at runtime — no rebuild
- [x] Theme written in a standard format so other applications follow it too,
      rather than a bespoke scheme only this shell understands
      *(`~/.cache/wal/` in pywal's layout + base16 YAML, and OSC sequences
      broadcast to every pts. Dotfiles still need to point at those files —
      see the note at the bottom. GTK cannot be recoloured at runtime by any
      file; only the portal's light/dark + single accent gets through.)*
- [x] A theme is colour only here; fonts, spacing, radii stay hardcoded
- [ ] A toggle to match the theme to the wallpaper — *"a cute little toggle
      you can turn on if you wanna try it"*. Off by default.

## Rail, continued

- [ ] Windows-style widgets menu: a chevron flyout that decides which items sit
      on the rail and which live behind it. `Pins.qml` and `panels/Widgets.qml`
      exist but were never wired to anything.

## Applications that should follow the theme

- [x] kitty — already follows, via the OSC broadcast, with no config change
- [ ] neovim — use the published palette when it exists, fall back to
      tokyonight-night when it does not. Minimal change, in his `nvim` repo.
- [ ] zellij — find out whether it can follow at all

## Launcher

- [x] Centred overlay window on top of everything
- [x] Wired up, and not reachable from a rail button

## Waiting on Erik

Changes that belong in the dotfiles repo, not here. Nothing has been done to
his system; these are proposals.

- kitty: `include ~/.cache/wal/colors-kitty.conf`, and drop
  `auto_reload_config = -1` from `modules/home-manager/kitty.nix:23` so new
  windows pick it up. Running windows already recolour via the OSC broadcast.
- fish: `cat ~/.cache/wal/sequences` in `interactiveShellInit`, so terminals
  opened later match the ones already running.
- waybar: `@import "/home/erikf/.cache/wal/colors-waybar.css";` plus
  `killall -SIGUSR2 waybar`.
- GTK: not possible from a file. GTK loads `gtk.css` once and never watches
  it, and libadwaita pins the theme name. The only live channel is the
  portal, and it carries light/dark plus one accent colour.

## Research, for discussion rather than implementation

- [x] Can the QMK/Vial layout of the Dactyl be rendered as a cheatsheet?
- [x] Can Hyprland's binds be read (via hyprctl, not by parsing config)?
- [x] Can Neovim's keymaps be read?
