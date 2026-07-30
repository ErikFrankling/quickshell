# Requirements audit — session a86c222d

Read-only audit. Sources: 70 extracted user messages, the session transcript,
`/home/erikf/projects/personal/quickshell` at commit `cae36c8` (+ uncommitted
in-flight edits), and `/home/erikf/.dotfiles/.claude/worktrees/notifications-dark-mode-fix-2b275e`.

Verification was done against the code and against the **live running shell**
(pid 2157489, `-p /home/erikf/projects/personal/quickshell`) and live
`hyprctl` output — not against `docs/REQUIREMENTS.md`.

---

# 1. UNJUSTIFIED TICKS — claimed done, not done

## 1.1 `[x] Screenshot every visible change and send it in chat` — FALSE

This is the requirement Erik stated most often, and it is the one most
violated.

- **163** screenshots exist in `.../scratchpad/shots/`.
- **53** `.png` files were ever `Read` on the main thread (i.e. ever actually
  rendered into the chat). All 53 were main-thread, none sidechain — so 53 is
  the true upper bound of what he saw.
- **110 captured screenshots were never sent.**

The never-sent list includes entire labelled sets that were captured
*specifically because he asked for them*:

```
G-rail G-popups G-notifs G-monitor G-audio G-network G-bluetooth G-player G-looks
F-rail F-popups F-notifs F-monitor F-audio F-network F-bluetooth F-looks F-player
s-launcher s-audio s-bluetooth s-network s-notifs s-player s-popups s-monitor
x-launcher x-audio x-bluetooth x-network x-notifs x-player x-popups x-monitor
z-launcher f1-launcher f2-looks f3-gruvbox n1-popups n2-notifs n3-monitor …
```

He asked three separate times, naming the exact panels:

> "always show screen shots af all hte htings hsave not seen hta tblotooht or
> wifi menut or the vukcing appp laucnhder and al hte diffrent ways to ahndle
> snotifications do use all hte things take screenshots that you send in chat"

> "and as soon as thigns are odne implelentign show me the screen shots"

> "i want screen hsots of all hte like 20 things i jsut told you to do"

**Bluetooth panel, wifi/network panel, app launcher, media player and the
notification popups were all screenshotted and none of those screenshots were
ever sent.** The tick on line 15 of `REQUIREMENTS.md` is not justified.

## 1.2 `[x] Workspaces always in numerical order` — FALSE at HEAD

`Workspaces.qml` **as committed** (`cae36c8`, line 104-107) sorts by `id`:

```qml
values: [...Hyprland.workspaces.values]
    .sort((a, b) => (a.id < 0) - (b.id < 0) || a.id - b.id)
```

Erik told you exactly what was wrong with this:

> "sitll teh ufkcing hyprland thigns are not numberical **jsut fcking sort them
> based on that nubmer that is actuall deisplayed** do onlin e reserch its veyr
> common isue in hyprland **it ahs 2 types of id for a workspace**"

Live `hyprctl workspaces -j` on his machine right now:

| id | name |
|---|---|
| -1337 | 7 |
| -1338 | 6 |
| -1339 | 11 |
| -1340 | 15 |
| -1341 | 14 |

Applying the committed sort to the live data produces:

```
1 2 3 4 5 8 9 10 12 13 14 15 11 6 7 special:magic     <- committed code
1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 special:magic     <- what he asked for
```

The delegate renders `modelData.name`, so it sorts on one field and displays
another. This is precisely the "2 types of id" bug he named. The tick was
added in commit `b4b1978` "Tick workspace ordering" and was never true.

**In-flight status (do not re-report as missing):** the uncommitted working
tree now has `rank()`/`label()` in `Workspaces.qml` sorting on
`/^\d+$/.test(w.name) ? parseInt(w.name) : Infinity`. That is the correct fix.
It is not committed yet and has not been screenshot-verified.

## 1.3 `[x] Per-host options exposed to the NixOS config (nix/hm-module.nix)` — UNREACHABLE

`nix/hm-module.nix` is a well-written 98-line module, but **`flake.nix` has no
`homeManagerModules` output and no `packages` output**. Full outputs:

```nix
apps.${system}.default = { … };
devShells.${system}.default = { … };
```

So:
- nothing can `imports = [ inputs.quickshell.homeManagerModules.default ]`;
- `programs.erikshell.package` can never be set from this flake, which makes
  the `systemd.enable` assertion permanently unsatisfiable.

The module is dead code until the flake exports it. Tick is not justified —
this should be PARTIAL at best.

## 1.4 `[ ] Concave corners … "regressed on purpose"` — the justification contradicts the user

`REQUIREMENTS.md:33-37` says the concave corners were dropped on purpose
because panels are now floating cards. But Erik asked for **both**, in one
breath:

> "i want the fukcign side menues ot modt take upp hte entier hight hsoudl take
> uppp jsut as mcuh as it need s like this that notalia foes like its does not
> take upp hte entire scerrreen the menu only as tall ans iwde as the content
> tkahat fills it **and then those roundesd cornenrs to connect it** it is
> noctalia this is what noctalia is good at"

And earlier, as the very first design decision of Phase B:

> "the corners that are intelligent and the sidebar. So the left sidebar on the
> panels that you open should be like the dynamic corners… so you open a sidebar
> and it opens as if it was part of that sidebar"

Noctalia does both at once (content-sized card *attached* to the bar with a
fillet). Choosing to detach the card and then declaring the corners obsolete is
a design decision made against a stated requirement, recorded as if it were a
consequence. `ConcaveCorner.qml` (41 lines) is now **dead code — never
instantiated anywhere** (`rg ConcaveCorner -g '*.qml'` matches only its own
file and `qmldir`).

## 1.5 `[x] Bluetooth panel` — device list is clipped off the card

Verified visually just now (`/tmp/claude-1000/audit-bt-crop.png`): opening the
Bluetooth panel shows the header, the two toggles, the "Devices" label, and
then **the first device row is sliced in half by the bottom edge of the card**.

Cause: `shell.qml:381` treats only `notifs` and `network` as list pages
(`card.list`). Everything else is sized `body.item.implicitHeight`. But
`panels/Bluetooth.qml` puts its device list in a `ListView` with
`Layout.fillHeight: true`, and a `ListView`'s `implicitHeight` is 0 — so the
card sizes itself to the header alone (floors at 200px) while the ListView is
laid out at near-full-screen height inside a `clip: true` rectangle.

Fix is one word: add `bluetooth` to the `card.list` set, or give the ListView
an implicit height.

## 1.6 `[x] Theme switcher listing every theme` — 7 hardcoded themes

> "it should list all the themes and probably have, like, the ones I like at the
> top"

`panels/Looks.qml:31-39` hardcodes seven palettes (Tokyo Night, Gruvbox,
Catppuccin Mocha, Nord, Rosé Pine, Everforest, Kanagawa). Favourites-at-top
works (`fav` flag, line 125). "Every theme" — e.g. reading the base16/tinted
scheme set he separately said existed as a standard — does not. PARTIAL, not
DONE.

## 1.7 `[x] Save a notification for later` — the star never lights up in history

`panels/NotifCenter.qml:48` binds `saved: root.showSaved`. In the history view
`showSaved` is always `false`, so an already-saved notification still shows a
hollow `☆`, and clicking it calls `save()` again (a no-op) instead of
un-saving. The mechanism works; the UI can't tell you it worked.

---

# 2. NOT DONE / PARTIAL — including things never written down at all

## 2.1 Requirements missing from `REQUIREMENTS.md` entirely

**(a) Wallpaper→theme auto-match toggle. NOT DONE, NOT TRACKED.**

> "so I can, like, switch the theme to match the background, which I know
> there's a program for, but **that's just a cute little toggle you can turn on
> if you wanna try it**"

There is no such toggle in `panels/Looks.qml`, and no line for it in
`REQUIREMENTS.md`. Themes and wallpapers are entirely independent in the code.

**(b) Most of his waybar metrics are not visible on the rail. PARTIAL, NOT TRACKED.**

> "I still wanna see all my metrics, like fan speed and temperatures and
> percentages. It's like the little circles on the sidebar, but then they should
> be able to open a systems monitor"

His waybar (`modules/home-manager/waybar/config.jsonc:25-41`) always shows:
network, memory, swap-activity, swap, disk#root, disk#data, cpu, temperature,
gpu-util, gpu-vram, fan, backlight, battery, pulseaudio, tray, clock.

The rail rings (`shell.qml:184-187`) show **four**: cpu, ram, gpu, temp.
Fan, swap, swap I/O, both disks, VRAM and **battery** are only reachable by
opening the Monitor panel. On a laptop, battery not being always-visible is a
real regression against what he has today.

## 2.2 Open, correctly tracked as unticked

- `[ ] Say on screen how far back the graphs go` — **NOT DONE.** `Graph.qml`
  draws label + readout only; no window label. He asked directly: *"whould be
  nice isf you said soem were how logn bakc the graphs go liek is it 30sec 60
  sec 10 sec ??"*. (For the record: 60 samples × 2s = 120s.)
- `[ ] Graph only what moves` — **NOT DONE.** `panels/Monitor.qml:93-99` still
  graphs disk usage and battery, which is what he laughed at:
  *"hahah i did not mean every hting every thing shoud have a grpah"*.
  *(in flight — metric graphs being reworked)*
- `[ ] Disk read/write throughput as a graph, like btop` — **NOT DONE.**
  `Sys.qml` reads no `/proc/diskstats`. He asked for it in the same message.
- `[ ] Windows-style widgets menu` — was NOT DONE at `cae36c8`; `Pins.qml` and
  `panels/Widgets.qml` existed but nothing referenced them. *(in flight — the
  uncommitted working tree now wires `Pins.railWidgets`/`railTray` and a
  `widgets` page into `shell.qml`, and the live rail shows the chevron.)*
- `[ ] Rail is not cramped` — looks resolved in the live screenshot; leave open
  until he says so.
- `[ ] Imported through Home Manager` — **legitimately deferred by him**:
  *"let snot wire this into my system config yet right because want this to be
  better then waht i have first"*. Correctly unticked.
- `[ ] neovim / zellij follow the published palette` — NOT DONE, correctly
  unticked.

## 2.3 Smaller caveats found while spot-checking justified ticks

- VPN detection (`shell.qml:120-124`) probes `ip link show tun0` only.
  WireGuard (`wg0`) or Tailscale (`tailscale0`) would read as "no VPN". His ask
  was *"is you are in npm or not"* — narrow but consistent with his existing
  waybar script, so defensible.
- Notification **history** lives only in memory (`Notifs.qml:17`); only
  `saved` is persisted to `saved.json`. History does not survive a shell
  restart. His words were *"all notification sent should … remain … until I
  actually dismiss them"* — arguably in-session only, but worth a decision.
- `Sys.hasGpu` guard on the GPU ring is written `Sys.hasGpu ?? true`
  (`shell.qml:186`) — `hasGpu` is a `bool`, never null, so the `?? true` is
  dead. Harmless, but it means nobody re-read the line after `Caps` landed.

---

# 3. VERIFIED DONE (spot-checks that hold up)

| Requirement | Proof |
|---|---|
| Dark mode fixed system-wide | `~/.dotfiles/.../modules/home-manager/desktop.nix:86` `colorScheme = "dark"`, commit `258bbf5a` |
| AGS follows system nixpkgs | `flake.nix:87` `ags-shell.inputs.nixpkgs.follows = "nixpkgs"` |
| Notification HTML renders | `~/projects/personal/AGS/notifications/markup.ts` (272 lines), Pango probe at `:233-238`; `Notification.tsx:98-101` `wrap` + `useMarkup` fixes the squishing |
| Public repo, separate from dotfiles | `gh repo view` → `ErikFrankling/quickshell`, `PUBLIC` |
| `nix run` from working tree | `flake.nix:21-29`, `-p "${1:-$PWD}"` |
| `docs/catalogue.md` >50 stars | 338 lines, 127 repos confirmed, provenance documented at top |
| `docs/gallery.html` | 138 KB, 367 images archived locally in `docs/images/`, every record carries a `sha` (commit-pinned), `<select id="sort">` with 5 orders incl. stars, tag filter; `docs/index.html` is byte-identical (GitHub Pages) |
| AGENTS.md + CLAUDE.md two rules | `AGENTS.md:8` and `:26`, CLAUDE.md refers to it |
| Workspaces show number + real app icon, icons right of number | `Workspaces.qml:135-170`, confirmed in live screenshot |
| Rail icons carry state | `shell.qml:210-240` — audio/network/bluetooth/player/notifs glyphs and tints all derive from state |
| Rings clickable, no separate monitor button | `shell.qml:190-197` |
| Theme button with the other buttons | `shell.qml:204-208` |
| No launcher button in the rail | confirmed — no launcher entry in the rail Groups |
| Launcher is a centred overlay, wired | `LauncherWindow.qml` + `shell.qml:439-444` `IpcHandler` `launcher toggle` |
| Escape closes any panel | `shell.qml:95-99` + `keyboardFocus: Exclusive`; also `TrayMenu.qml:55-59`, `LauncherWindow.qml:111` |
| DND removed entirely | `rg -i dnd` over all QML → zero hits |
| Opening a panel can't move the rail | `shell.qml:29-37` + `:46-93` — two fixed-size windows, nothing resizes |
| Panels are content-sized cards | `shell.qml:388-389` (with the Bluetooth exception in §1.5) |
| Audio: per-app volume + input/output devices | `panels/Audio.qml:102-157` |
| Brightness slider (laptop only) | `panels/Audio.qml:68-82`, gated on `Sys.brightness >= 0`; `Caps` probes `/sys/class/backlight` |
| Media player + track switching | `panels/Player.qml:72-78` |
| Notification popups expire, history scrolls, translucent | `shell.qml:476-480`, `panels/NotifCenter.qml:37-50`, `NotifCard.qml:13` `Qt.alpha(Theme.bgAlt, 0.82)` |
| Reuse waybar scripts | `Sys.qml:170,187` call `~/.local/bin/gpu-util.sh`, `gpu-vram.sh`, `network-status.sh` — all three exist and return valid JSON, verified by running them |
| Capability detection | `Caps.qml` one-shot probe, GPU/fan/temp/battery/backlight/swap/nics/disks |
| Wallpaper switcher works + wallhaven download | `panels/Looks.qml:91-113`; **16 wallpapers actually on disk** in `~/Pictures/wallpapers`, 13 of them `wallhaven-*` |
| Theme applies instantly | `Theme.qml:60-75` watched `theme.json` |
| Theme published in a standard format | `Scheme.qml`; **`~/.cache/wal/` really is populated** — `colors`, `colors.sh`, `colors.json`, `colors.css`, `colors-waybar.css`, `colors-kitty.conf`, `colors-base16.yaml`, `sequences` |
| Tray in rail, left-click activates, right-click menu | `shell.qml:255-326` + `TrayMenu.qml` (self-drawn via `QsMenuOpener`) |
| Button hover flicker fixed | `Btn.qml:1-8` — explicit `hovering` property, fixed-size centred visual, noctalia's NIconButton idiom |
| Everything pushed | `HEAD == origin/main == cae36c8` |
| QMK repo untouched | `/home/erikf/projects/3d/vial-qmk` — `git status` clean, respecting *"don't change anything in there"* |

---

# 4. Message-by-message

Ordered by topic and roughly by when it was said. Quotes are verbatim.

### Phase A — notifications and dark mode (all shipped)

| # | What he asked | State |
|---|---|---|
| 1 | "i want better rendering of my notifications and a fix to dark mode … programs on my system think i am using light mode" | **DONE** — `desktop.nix:86`, commit `258bbf5a` |
| 2 | "make the html in notifications work like make it actaully render it pars notifications for html tags" | **DONE** — `AGS/notifications/markup.ts` |
| 3 | "when there are several messages in one notifications they get squiched toghether fix" | **DONE** — `Notification.tsx:98-101` |
| 4 | "dont ask me for help so these changes and rebuild send notifications and take screenshots to verify" | **DONE** for Phase A |
| 5 | "you did not have to fuck with ht etransparancy … but actaully i do like that they are transparent … goofy with the very clear boarders … go online looka t some examples of other linux ricers" | **DONE** — he then said "okay banger those notifications are beutiful ship it" |
| 6 | "or you just update to latest or is that jus tnot in nixpkgs yet" | **NOT A REQUIREMENT** — question; he then caught the GTK version error |
| 7 | "and that breaks if you make ags follow my system nixpkgs?" | **NOT A REQUIREMENT** — question; the follows landed anyway (`flake.nix:87`) |
| 8 | "do you think this change and code is good then ship it rust.nix (sccache) isnt" | **DONE** — shipped, sccache excluded |

### Phase B — research and repo setup

| # | What he asked | State |
|---|---|---|
| 9 | Long dictated request: research Quickshell, ~50 configs, big report, new public repo | **DONE** — `docs/research.md` (490 lines), `docs/catalogue.md`, repo public |
| 10 | "Now what's gonna be extremely important in this session is images … Send me all the images" | **PARTIAL** — research images were sent; the *product* screenshots were not (§1.1) |
| 11 | "no dont run all the difffrent forks … do resrach presnet it to me … dont go doewnloading 320 diffrent random ass things" | **RESPECTED** |
| 12 | "at lest 50 stars … good control panel for wifi audio blotooth … notifications center … app launcher … good top bar … find 10 that you think we could fork from" | **DONE** — shortlist delivered; he picked "write our own" |
| 13 | "not realy loading though might want to put all of thme in a html file … i am on a laptop over ssh" | **DONE** — `docs/gallery.html` |
| 14 | "they are all like 400pc big wtf can barly see anything" / "why di you not just getch the original images" | **DONE** — full-res via Pages |
| 15 | "i dont give a shit about some fukcing clade artiffact … jsut fukcing make it a normal fucking html file" | **RESPECTED** |
| 16 | "lets have sort by star count and lets have you use some super cheep subagents that look at each image and tag it … so htat i can filter on htat" | **DONE** — `<select id="sort">` with 5 orders, per-image `tags` array, tag filter |
| 17 | "cant you get it to download all the images incase they move … and include like git commits in the refrence" | **DONE** — 367 local JPEGs, every record has `"sha":"…"` |
| 18 | "okay and you are sure you are not missing a bunch of projects" | **NOT A REQUIREMENT** — challenge; catalogue documents the enumeration method |
| 19 | "tell me about omarchy they use quickshell?" | **NOT A REQUIREMENT** — question |
| 20 | "so does quickshell have like native base16 integration" / "aint there a bunch" / "there is a standard for switching themse" | **DONE** — `Scheme.qml` publishes base16 + pywal |
| 21 | "waybar is not caomaparable in any way … dont compare them" | **RESPECTED** — conceded |
| 22 | "i dont know how quickshell works so be less ajargon hevy" | **RESPECTED** |
| 23 | "i dotn realy have a problem with a notch bar i do kinda want a nice side bar though" / "maybe i am considering it" | **DONE** — sidebar built |
| 24 | "shit like this is a bitt hevy right a whole ass settings poanel … besst to not go with one of them right?? github.com/corecathx/whisker" | **NOT A REQUIREMENT** — became the "no settings GUI" rule |
| 25 | "we can always like pull code from several … prior art is amazing" | **RESPECTED** — rule 2 in AGENTS.md |
| 26 | "no i dont want this new thing … inside my dotfiles repo … possible to run the desktop shell and restart it … with no system config rebuild" | **DONE** — separate repo, `nix run .` |
| 27 | "just like we have right now with ags just with quicksehll instead its imported in hoem manager" | **DEFERRED BY USER** — later: "let snot wire this into my system config yet" |
| 28 | "no that is not waht i mean thse things will be hardcoded the theme in this case is only color" | **DONE** — `REQUIREMENTS.md:104`, `Theme.qml` |
| 29 | "yeah i obviusly want like a runtime them/wallpaperswitcher that applies to all apps and the dektop shell instantly" | **PARTIAL** — shell + terminals yes (`~/.cache/wal` populated + OSC broadcast); GTK apps cannot follow at runtime, documented; **his dotfiles have not been changed to consume the files**, correctly listed under "Waiting on Erik" |

### Phase B — the shell itself

| # | What he asked | State |
|---|---|---|
| 30 | "fuck forking lwts write our own … do not over engineer … as little code as possible" | **DONE** — 4671 lines total, largest file 490 |
| 31 | "a good docs folder with … alll configs you have found … a complete list of like all the quickshell repos … with more thatn 50 stars" | **DONE** |
| 32 | "make the flake make sure you are able to start wuicshell with some super trivial window … htaka screenshot" | **DONE** — commit `f8290f8` |
| 33 | "write a super simpe readme and agent.md and a claude.md … the most important two rules" | **DONE** — `AGENTS.md:8`, `:26` |
| 34 | "create a side bar on the left side realy good notification handling … control panel type stuff … good metricsin the side bar … application launcher" | **DONE** (metrics coverage PARTIAL, §2.1b) |
| 35 | Noctalia design language, "the corners that are intelligent … opens as if it was part of that sidebar" | **NOT DONE** — §1.4 |
| 36 | Bluetooth / Wi-Fi / notification centre / audio per-app + devices / brightness / battery | **DONE** except Bluetooth list clipping (§1.5) and battery not on the rail (§2.1b) |
| 37 | "notification … Go away right after a while … but all notification sent should remain until I actually dismiss them … I should be able to click. Save this notification … put it on a to do kind of thing" | **DONE**, with the star-state bug (§1.7) and in-memory-only history (§2.3) |
| 38 | "system monitoring … it gets filled up the closer to limit you are" | **DONE** — `Ring.qml` + `Theme.heat()` |
| 39 | "open a systems monitor where I can see fucking graphs" | **DONE** — `panels/Monitor.qml` |
| 40 | "I should have Spotify, like, a current audio track thing … switch track" | **DONE** — `panels/Player.qml` |
| 41 | "Make me a the[me] switcher … make a background switcher too … make it work too" | **DONE** — `panels/Looks.qml` |
| 42 | "list all the themes and probably have the ones I like at the top" | **PARTIAL** — 7 hardcoded (§1.6); favourites-at-top works |
| 43 | "switch the theme to match the background … a cute little toggle you can turn on if you wanna try it" | **NOT DONE — and never written into REQUIREMENTS.md** (§2.1a) |
| 44 | "notifications … should be trans… translucent at least so I can see what's behind them" | **DONE** — `NotifCard.qml:13` |
| 45 | "do look at the way bar source code … and the AGS code … those things you can probably reuse the commands" | **DONE** — `Sys.qml:170,187` |
| 46 | "okay no the workspaces are uggly … see teh fucking nubmer and a logo showing whats on the workspace … the acutal icon of the acutall application" | **DONE** — verified in the live screenshot |
| 47 | "the always visable thigns shoudl be informative … is bloututh on or off is we connectected to ethernet or wifi or not connected not jsut button s" | **DONE** — `shell.qml:210-240` |
| 48 | "obviusly hte side bar is very cramped … put hte icons of the staretd apps in workspaces to the right of the number" | **DONE** (icons); rail-cramped left open |
| 49 | "do download some nice popluar wall papers and also set it upp so i can trivialy download wallpapers form the popular wall pper websites" | **DONE** — 16 files on disk, wallhaven search in-panel |
| 50 | "hyprpaper can jsut be a thing in this falke right" | **DONE** — `flake.nix:13-16` + self-start in `Looks.setWall` |
| 51 | "nothing seams to happpen when i click or right lcick the widgets" → "okay clicking on widgets work but i am not getting the right click drop down menu" | **DONE** — `TrayMenu.qml`, commit `5c5a20c` |
| 52 | "you have fucked upp you r button vompononet … hover effect flickers … alsyats have to comapre you r code agisnt the docuumentation" | **DONE** — `Btn.qml` |
| 53 | "the animation of opening one of the side panles … cahnges the width of the side bar … do no tdesign you own … send a rearch agent to read others animidmariton code" | **DONE** — `shell.qml:19-23, 60-73`, M3 emphasized curve copied from noctalia/caelestia |
| 54 | "gotta learn how to screen record the animations and whatch tehm" | **DONE** — `.../scratchpad/anim/`, `cael.mp4` |
| 55 | "lauch thing shoudl be … a thign that pops upp on topp of allht e thigns in a seprate iwndow in the middle of the screen not part odf the side bar does no tnneed to have a … button on the side bar" | **DONE** — `LauncherWindow.qml`; **but no screenshot of it was ever sent** |
| 56 | "and like theme button hodu lbe iwth allhte othe buttons" | **DONE** — `shell.qml:204` |
| 57 | "pi dont fukcing need do not distupr at all usless" | **DONE** — zero `dnd` references |
| 58 | "pressing ec should always close wahtever side menue iopen right now" | **DONE** — `shell.qml:95-99` |
| 59 | "i want the fukcign side menues ot modt take upp hte entier hight … and then those roundesd cornenrs to connect it" | **PARTIAL** — content sizing DONE, connecting corners NOT DONE (§1.4) |
| 60 | "the system resources shti shodu lbe clickable dont need a seprate button" | **DONE** — `shell.qml:190-197` |
| 61 | "shoud lbe grpahs do e all hte ring temp fan speed … swap sapce swap sppee transfer thing" | **DONE** — `panels/Monitor.qml` |
| 62 | "dont shode gpu metrics on hsots with no gpu" | **DONE** — `Caps.qml` |
| 63 | "might need to expose like home manager config options that i cna set in the nicos config for each host" | **PARTIAL** — module written, **not exported from the flake** (§1.3) |
| 64 | "correclyt handling networking … shoud lalways be visable if its wifi vpn or thenerntet … wihtouhg ahving ot opne hte mienu" | **DONE** — `shell.qml:215-227` (tun0-only caveat, §2.3) |
| 65 | "hahah i did not mean every hting … shoud have a grpah … maybe disk usage and bttery change over … days" | **NOT DONE** *(in flight)* |
| 66 | "if you wna ta g[raph] you can have like disk read and write numbers ina grph you know like btop" | **NOT DONE** — no `/proc/diskstats` anywhere |
| 67 | "whould be nice isf you said soem were how logn bakc the graphs go liek is it 30sec 60 sec 10 sec ??" | **NOT DONE** — `Graph.qml` has no window label |
| 68 | "battery over last 24h interesting but … that is a n entierly diffren tapplication wont be doign that now" | **DEFERRED BY USER** — correctly out of scope |
| 69 | "you sitll have not done that windows like widgets menu" | **NOT DONE at HEAD** *(in flight — now wired in the working tree)* |
| 70 | "like for exaple workspace sitll aint umberical" / "jsut fcking sort them based on that nubmer that is actuall deisplayed" | **NOT DONE at HEAD** (§1.2) *(in flight — working-tree fix is correct)* |

### Research-only items (he said discuss, not implement)

| # | What he asked | State |
|---|---|---|
| 71 | "my Dactyl keyboard that's programmed with the QMK … **don't change anything in there** … can we take my keyboard repo as a flake input … investigate all this … send some agents to research all these three things … and write the report" | **DONE as discussion** — QMK/Vial, Hyprland `hyprctl binds -j`, and Neovim `nvim_get_keymap` all answered in chat, including the `keymap-drawer`/QtSvg `dominant-baseline` trap. **No written report file exists** — the three `[x]` ticks in `REQUIREMENTS.md:142-144` rest on chat messages only. QMK repo confirmed untouched. |
| 72 | Hyprland Lua migration / the other OMP session | **NOT A REQUIREMENT** — context he asked you to read |
| 73 | "convert ~60 Hyprland binds to `bindd`" | **AWAITING HIS DECISION** — never answered |

### Process demands

| # | What he asked | State |
|---|---|---|
| 74 | "like sensd a subagetns tht works in parallell on all the diffrent kinds of shit i am telling you to do … you be a rrchistrato" | **DONE** — orchestration used throughout |
| 75 | "find this Claude session file … read all the messages I sent, and make sure all of them have been applied" (said **three separate times**) | **PARTIAL** — `docs/REQUIREMENTS.md` was created in response and is genuinely useful, but it contains at least 5 ticks that the code does not support, and omits at least 2 stated requirements (§2.1) |
| 76 | "make sure allhte things aht atare done so far are pushed" | **DONE** — `HEAD == origin/main` |

---

# 5. Housekeeping found in his dotfiles (not modified, per instructions)

`/home/erikf/.dotfiles/.claude/worktrees/notifications-dark-mode-fix-2b275e`
has untracked agent debris sitting in his repo working tree:

```
?? noct4/          59 MB — a full clone of Noctalia v4
?? a.png
?? b.png
?? q_qs_qml.json
```

`noct4/` in particular should have gone to the scratchpad. Left in place, as
instructed — but he will see it in `git status` and it belongs in
`.gitignore` or `/tmp`.
