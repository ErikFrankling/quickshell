# Notification popups: how long they stay, and whose icon they draw

Two questions, asked of every Quickshell config on disk that has a notification
popup at all:

1. **How long does a popup live** — is there one number or one per urgency, is
   the sender's own `expireTimeout` honoured, and does critical ever expire?
2. **Whose icon is on the card** — which of `appIcon` / `desktopEntry` /
   `appName` / `image` is read, is the name checked before it is drawn, and
   what appears when nothing resolves?

Local clones are under
`/tmp/claude-1000/-home-erikf--dotfiles--claude-worktrees-notifications-dark-mode-fix-2b275e/a86c222d-110d-4226-a5b0-f35e8c06695c/scratchpad/clones/`
(abbreviated `CLONES/`); the noctalia checkout is
`/home/erikf/.dotfiles/.claude/worktrees/notifications-dark-mode-fix-2b275e/noct4/` (`NOCT4/`).
Fourteen projects were opened. Four of them (`bjarneo`, `diinki`×2,
`liixini/skwd-wall`) have no notification implementation and are not in the
table.

---

## 1. Timing

| # | Project | Default life | Split by urgency | Reads `expireTimeout` | `0` = never expire | Critical is sticky | Hover |
|---|---------|--------------|------------------|-----------------------|--------------------|--------------------|-------|
| **0** | **OURS, before** | **7000** | low 4000 / rest 7000 | **no — never read** | n/a | **yes** | **no** |
| **0** | **OURS, after** | **12000** | low 6000 / rest 12000 | **yes, as a floor** | **yes** | **yes** | **yes, resets** |
| 1 | noctalia | 8000 | 3000 / 8000 / 15000 | opt-in, **off by default** | **yes** | no — 15 s like any other | pause **and resume** |
| 2 | corecathx/whisker | 5000 | no | yes | no — folds to 5000 | ~yes (`99999`) | stop/restart |
| 3 | doannc2212 | 5000 | no | yes | no — folds to 5000 | yes | `running: !hovered` |
| 4 | josecriane | 4000 | no | yes | no — folds to 4000 | no | no |
| 5 | Gakuseei/Ricelin | 6000 | low 4000 / rest 6000 | no | n/a | yes | no |
| 6 | Brainitech | 5000 | no | no | n/a | no | no |
| 7 | myamusashi/vast-shell | 3000 | no | parsed, never used | n/a | no | pause **and resume** |
| 8 | tripathiji1312 | 7000 | no | no | n/a | no | pause (animation) |
| 9 | Rexcrazy804 kurukurubar | 3500 | no | no | n/a | no | stop/restart |
| 10 | Rexcrazy804 kurumibar | 3000 | no | no | n/a | no | no |
| 11 | shub39 | 3000 | no | no | n/a | no | no |
| 12 | liixini/skwd | 5000 | no | yes | no — folds to 5000 | no (urgency unread) | stop/restart |
| 13 | maxchennn/vroomies | 5000 | no | no | n/a | no | no |

### What the field agrees on, and where it is wrong

**Nobody else is as long as 12 s.** The field runs 3000–8000, clustering on
5000. We were already at the long end at 7000 and Erik still says popups vanish
before he has read them, so this is a deliberate step past the consensus, not a
misreading of it — see §3.

**Five projects read `expireTimeout` and four of them get `0` wrong.** The spec
says `0` means *never expire* and `-1` means *the server decides*. Four
implementations write the same expression and fold both into their default:

`CLONES/liixini_skwd/skwd-notification/qml/NotificationPopup.qml:120-124`
```qml
interval: {
    if (card.notification && card.notification.expireTimeout > 0)
        return card.notification.expireTimeout
    return Config.notificationExpireMs
}
```

`CLONES/doannc2212_quickshell-config/notifications/NotificationData.qml:86`,
`CLONES/josecriane_quickshell-config/services/NotificationService.qml:162` and
`CLONES/corecathx_whisker/services/NotifServer.qml:97-99` are the same shape.
A `0` is a request to leave the popup up; all four take it down.

**noctalia is the only one that gets it right — and ships it disabled.**
`NOCT4/Services/System/NotificationService.qml:398-409`
```qml
function calculateDuration(data) {
    const durations = [ ...low*1000 || 3000, ...normal*1000 || 8000, ...critical*1000 || 15000 ];
    if (Settings.data.notifications?.respectExpireTimeout) {
        if (data.expireTimeout === 0) return -1;   // Never expire
        if (data.expireTimeout > 0) return data.expireTimeout;
    }
    return durations[data.urgency];
}
```
with `respectExpireTimeout: false` at `NOCT4/Commons/Settings.qml:679-682`.
That default is the interesting part: the largest shell in the survey looked at
honouring the sender and decided not to, because an application that asks for
two seconds does not know what its user is doing. It is the argument for the
floor in §3, not against reading the field at all.

**Critical stickiness is genuinely split** — 3 of 13 make it permanent
(doannc2212, Gakuseei, and whisker with a `99999` sentinel at
`CLONES/corecathx_whisker/services/NotifServer.qml:90-92`), noctalia
deliberately does not. Ours already did, and keeps doing it: it is what dunst
and mako do, and a critical notification you can miss is not critical.

### Hover, and why "restart" is enough

Six of thirteen pause on hover. Three do it properly, crediting back the
elapsed time so a hovered popup *resumes*:

`NOCT4/Services/System/NotificationService.qml:882-896`
```qml
function resumeTimeout(id) {
    ...
    notifData.metadata.timestamp += Date.now() - notifData.metadata.pauseTime;
```
(and `CLONES/myamusashi_vast-shell/Qml/Modules/Drawers/Notifications/Components/Wrapper.qml:32-49`,
`CLONES/tripathiji1312_quickshell/modules/bar/components/NotificationPopups.qml:419-432`,
the last by pausing a `NumberAnimation` rather than a timer.)

The other three simply stop the timer on enter and restart it on exit, which
grants a *fresh full life* after the pointer leaves. The cheapest expression of
that is doannc2212's, and it is the one copied here —
`CLONES/doannc2212_quickshell-config/notifications/NotificationData.qml:65-73`:
```qml
running: !notificationData.closed && !notificationData.hovered
      && notificationData.urgency !== NotificationUrgency.Critical
```
A QML `Timer` restarts from zero when `running` goes false → true, so this one
line is the whole feature. Resuming instead of restarting needs a
`Date.now()` pair, a paused flag and a remaining-time field — three projects'
worth of bookkeeping to make a popup you just looked at go away *sooner*. Not
worth it.

---

## 2. The icon

| # | Project | Chain | Checks the name exists | When nothing resolves | Content `image` |
|---|---------|-------|------------------------|-----------------------|-----------------|
| **0** | **OURS, before** | — no image on the card at all | — | — | no |
| **0** | **OURS, after** | `appIcon` → `desktopEntry`'s `Icon=` → lowercased `appName` → `image` | **yes**, `iconPath(n, true)`, on arrival | **nothing** | yes, but last |
| 1 | noctalia | `image` → `appIcon` | **yes** | `bell` glyph | yes, wins, shared 40 px tile |
| 2 | corecathx/whisker | `image \|\| appIcon` straight into `Image.source` | no | Material glyph | yes, wins, 50 px tile |
| 3 | doannc2212 | `appIcon` | **yes** | per-app glyph table, else `󰂚` | yes, separate preview |
| 4 | josecriane | `appIcon` | no (1-arg) | Material glyph | yes, 41 px; app icon a corner badge |
| 5 | Gakuseei/Ricelin | `image` → `appIcon` → `desktopEntry` → lowercased `appName` | **yes** | 7 px rotated square | yes, first in chain |
| 6 | Brainitech | `appIcon` | no | **circle with the first letter of `appName`** | no |
| 7 | myamusashi/vast-shell | `image` → `appIcon` | no (1-arg) | **nothing** | yes; app icon a 20 px badge |
| 8 | tripathiji1312 | `appIcon` | no | `󰂚`, but only if `appIcon` was *empty* | yes, 80 px strip |
| 9 | Rexcrazy804 kurukurubar | `image` only | — | nothing (slot hidden) | yes, only source |
| 10-11, 13 | kurumibar, shub39, vroomies | no icon at all | — | static `󰂚` or nothing | no |
| 12 | liixini/skwd | no icon at all | — | — | no |

### Only three of thirteen ask whether the name exists

`Quickshell.iconPath(name)` with one argument always returns *something* — the
icon provider's placeholder — which is the magenta-and-green checkerboard this
repo already hit once in the tray menu (`TrayMenu.qml:85-96`, and Erik on
seeing it: *"would rather nothing is rendered than this"*). The second argument
is the check-exists flag, and the three projects that pass it are noctalia,
doannc2212 and Gakuseei. noctalia wraps it with one extra guard worth knowing
about — `NOCT4/Commons/ThemeIcons.qml:262-270`:
```qml
const path = Quickshell.iconPath(iconName, true);
return path && path.length > 0 && !path.includes("image-missing");
```

This machine has **only `hicolor`** installed — 344 icon files across all sizes
under `/run/current-system/sw/share/icons/hicolor/*/apps/` plus what individual
packages ship into `~/.nix-profile/share/icons/hicolor/`. A miss is the normal
case here, not the exception, which is why every fallback in the table that
draws *something* (a bell, a letter, a diamond) would be what Erik saw on most
cards. Ours draws nothing.

### Two things every project in the table gets wrong about this machine

Both were found on the wire with `dbus-monitor` and in the live shell's log,
not read out of anyone's source, and both change what the chain has to be.

**1. `--icon` does not go in the `app_icon` field any more.** This libnotify
sends it as the `image-path` *hint*, so the field every project in the table
reads is empty:

```
$ notify-send --icon=firefox "Wire test" "what does --icon become"
   string "notify-send"        <- app_name
   uint32 0
   string ""                   <- app_icon, EMPTY
   ...
   array [ dict entry( string "image-path"  variant string "firefox" ) ... ]
   int32 -1
```

Quickshell puts that hint on the `image` property, and wraps it:
`image = "image://icon/firefox"`. An absolute path comes back wrapped too, as
`"image://icon//run/current-system/sw/share/icons/hicolor/48x48/apps/vlc.png"`.
So `image` cannot be handed to `Image.source` the way whisker
(`windows/notification/Notification.qml:168`) and vast-shell
(`Components/NotifIcon.qml:61-70`) hand it over — it arrives *already looking
like a resolved url*, and `image://icon/nonsense-icon-zzz` is a perfectly valid
url that renders the checkerboard. The prefix has to come back off and the name
be checked, which is the tray menu's idiom (`TrayMenu.qml:85-96`) applied to a
field the tray menu never sees.

**2. Quickshell already does the desktop-entry hop.** A notification carrying
only `desktop-entry=spotify` and no `app_icon` at all arrives in QML with
`appIcon = "spotify-client"` — logged from the live shell. That matters because
nothing called `spotify` is installed:

```
$ grep ^Icon= ~/.nix-profile/share/applications/spotify.desktop
Icon=spotify-client
```

Gakuseei's chain is the longest in the survey
(`CLONES/Gakuseei_Ricelin/configs/quickshell/pill/Singletons/Notifs.qml:35-53`)
and tries `desktopEntry` as an *icon name*, which on this machine resolves
nothing. The useful hop is to the entry's `Icon=` line, and Quickshell has
already made it. The explicit `DesktopEntries.byId(…).icon` step is kept anyway
for the one case Quickshell will not cover: an app that does name an icon of
its own, and names one nobody has installed.

### Content `image`, and where it ended up

Eight of thirteen render the `image` hint and five prefer it over the app icon.
Here it is in the chain, but **last**, after `appIcon`, the desktop entry's
`Icon=` and the lowercased `appName`.

Last, because it is the *content* hint — album art, an avatar — and Erik asked
for the application's logo, so a track change should show the Spotify mark and
not the sleeve. In the chain at all, because of finding 1 above: it is now the
only field a plain `notify-send --icon=firefox` sets, so a shell that ignores
`image` ignores `--icon` entirely.

The persistence problem this creates is the one `Notifs.qml`'s own reload
comment was written about — an `image` is a `/tmp` file that will not survive a
reboot, while a themed icon is an `image://icon/<name>` url that re-resolves
every time it is drawn. So `load()` keeps the themed ones and drops everything
else, which is what vast-shell does with ephemeral urls
(`Qml/Services/Notifs.qml:193-196`).

---

## 3. What was chosen, and why

**12 s normal, 6 s low, critical until dismissed.** Longer than anything in the
table. The justification is not that the field is wrong but that the field is
tuned for a bar you glance at; Erik reads these while working, said 7 s was too
short, and the two things that make a long life obnoxious are both handled — a
popup you reach for stops counting down, and four is still the most that can be
on screen at once.

**The sender's `expireTimeout` is a floor, not an override.** `Math.max` of the
default and what the sender asked for, with `0` honoured as *never expire* and
`-1` (what `notify-send` sends unless given `-t`) meaning our default. An
application that asks for *longer* means it and gets it — before this change
`notify-send -t 20000` was shown for 6.7 s, measured. An application that asks
for *shorter* is usually just repeating a library default and does not know
what its user is doing, which is the same conclusion noctalia reached when it
shipped `respectExpireTimeout: false`.

**The stack cap stays at 4.** Measured on the live shell with six notifications
sent 0.35 s apart, each with a two-line body: the layer-shell surface grew
151 → 291 → 431 → 571 px and then stopped. Four cards is 571 px of a 1080 px
screen; five would be 711 px and six 851 px, and with the four-line bodies a
popup card allows those become roughly 900 and 1080. The drop is already
oldest-first (`[s].concat(popups).slice(0, 4)`), which is the right one to
lose, and it is never actually lost — it is in history with the badge counting
it.

---

## 4. Measured, before and after

Timed on the running shell by watching the `notifications` layer-shell surface
appear and disappear in `hyprctl layers -j`, not by eye. Other agents were
saving files throughout and every save hot-reloads the shell, which empties
`Notifs.popups` and cuts a popup short — a reload can only ever shorten a
sample, so each number is the maximum of three to five runs and the hover run
discards any sample that spans a reload outright.

| Sent with | Before | After | Intended |
|---|---|---|---|
| `notify-send` (no `-t`) | **6.73 s** | **11.56 s** | 12 s |
| `notify-send -u low` | **3.86 s** | **5.75 s** | 6 s |
| `notify-send -t 20000` | **6.72 s** | **19.40 s** | 20 s — the sender's ask |
| `notify-send -t 2000` | 6.7 s | **11.56 s** | 12 s — the floor holds |
| `notify-send -u critical` | never expired | **never expired** (37 s, then dismissed by hand) | never |
| normal, pointer parked on it for 10 s | n/a | **22.58 s** | ~22 s |

The `-t 20000` row is the bug Erik ran into stated as a number: the sender
asked for twenty seconds and got 6.72.

### The icon, case by case

Read out of the live shell's log with a temporary probe on the `Image` itself,
reporting its `status` and its laid-out `width`:

| Sent with | Resolved to | `Image.status` | Drawn |
|---|---|---|---|
| `--icon=firefox` | `image://icon/firefox` | 1 Ready | yes, 16 px |
| `--icon=/…/hicolor/48x48/apps/vlc.png` | `file:///…/vlc.png` | 1 Ready | yes, 16 px |
| `-h string:desktop-entry:spotify` | `image://icon/spotify-client` | 1 Ready | yes, 16 px |
| `--icon=nonsense-icon-zzz` | `""` | 0 Null | **no, width 0** |
| `--icon=/tmp/does-not-exist-zzz.png` | `file:///tmp/…` | 3 Error | **no, width 0** |
| nothing at all | `""` | 0 Null | **no, width 0** |

`status` is already 1 at `Component.onCompleted` for every icon that resolves —
a local file loads synchronously — so the card is laid out with the icon from
its first frame and the app name never shifts sideways afterwards. The same
thing measured from outside, on the layer surface: an identical notification is
**133 px** with no icon and **134 px** with one. `desktop-entry:webcord` and
`desktop-entry:syncthing-ui` both give 134 as well, so the Quickshell
desktop-entry hop is not a Spotify special case.
