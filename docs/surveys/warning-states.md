# Warning states

Erik's laptop died because the battery ran out and nothing told him. Waybar had
told him for years. This survey is what waybar was actually doing, what the
Quickshell field does instead, and which of the two this shell copied.

The short version: waybar's mechanism is a pair of thresholds per module that
put a CSS class on the widget, and a stylesheet that colours **the module's
background** and optionally animates it. Almost nobody in Quickshell does the
animation half, and the projects that do all reach for the same three lines of
QML.

## What his waybar actually did

`modules/home-manager/waybar/` in the dotfiles. Thresholds live in the module
config as `states`, which is waybar's own convention: crossing one adds a
`.warning` or `.critical` class to the widget.

| module | warning | critical | file |
|---|---|---|---|
| battery | 30 | 15 | `config.jsonc:50-53` |
| cpu | 70 | 90 | `config.jsonc:84-87` |
| memory | 70 | 90 | `config.jsonc:103-106` |
| disk `/` | 90 | 95 | `config.jsonc:129-132` |
| disk `/mnt/data` | 90 | 95 | `config.jsonc:141-144` |
| temperature | — | 83 °C | `config.jsonc:200` |

Note that disk is *capacity*, not throughput, and that it is on the bar
permanently at 90/95 — the same thresholds for a 883 GB root and a 1.8 TB data
disk.

The stylesheet is where the two levels become visible. There are exactly two
keyframes, and both animate a **background colour**, not a text colour:

```css
/* style.css:17-37 */
@keyframes blink-warning  { 70% { color: white; }
                            to  { color: white; background-color: orange; } }
@keyframes blink-critical { 70% { color: white; }
                            to  { color: white; background-color: red; } }
```

and the blink is `alternate`, so the stated duration is **half** a cycle:

```css
/* style.css:95-117 */
#battery { animation-timing-function: linear;
           animation-iteration-count: infinite;
           animation-direction: alternate; }
#battery.warning  { color: orange; }
#battery.critical { color: red; }
#battery.warning.discharging  { animation-name: blink-warning;  animation-duration: 3s; }
#battery.critical.discharging { animation-name: blink-critical; animation-duration: 2s; }
```

Three things in there are the whole design and all three were copied:

1. **The full breath is 6 s for a warning and 4 s for a critical.** Halving the
   period is how the critical says it is worse.
2. **Only while discharging.** A laptop sitting at 12% on mains does not blink.
3. **Almost nothing else blinks.** `#memory` is given the three timing
   properties and never given an `animation-name` (`style.css:135-147`), so it
   colours and holds perfectly still. `#disk` and `#temperature` get colour only
   (`style.css:149-161`). The single exception is swap *activity*
   (`style.css:163-172`) — the one other thing on that bar that means "act now".

So waybar already encoded the rule Erik restated from memory: blink what he can
answer, colour what he cannot. `#memory` is the proof, and it is in his own file.

## What Quickshell shells do

Sixteen trees read. Nine have battery logic at all; none has disk-capacity
warning of any kind.

| project | thresholds | notifies? | re-fire guard | blinks? |
|---|---|---|---|---|
| noctalia `Services/Hardware/BatteryService.qml` | 20 / 5 (`Commons/Settings.qml:562-563`) | in-shell toast, `:344` | per-device × per-level map, `:73`, `:287-323` | no — static `Color.mError` tint (`Modules/Bar/Widgets/Battery.qml:240-241`) |
| corecathx_whisker `services/Power.qml` | 15 / 10 / 5, `:30-60` | `notify-send` via `execDetached`, `:62-71` | descending int watermark, `:18` | no |
| tripathiji1312 `modules/BatteryMonitor.qml` | 20 / 10 / 5, `:9-19` | `notify-send` via `Process`, `:27` | `_warnedLevels` map, `:46-60` | yes, opacity, `modules/bar/components/Battery.qml:213-219` |
| Brainitech `src/services/BatteryStatus.qml` | 30 / 20 / 10 / 5, `:32-49` | own `FloatingWindow` | array of warned levels, `:35` | yes, opacity, `:112-127` |
| myamusashi_vast-shell `Qml/Modules/Drawers/Drawers.qml` | 20 / 10 / 5 | `notify-send`, `:526-528` | none — exact `===` match, `:522` | one-shot red glow, `:454-510` |
| liixini_skwd `skwd-bar/qml/bar/TopBar.qml` | configurable | `notify-send`, `:385-388` | previous-value crossing test, `:344-389` | no |
| bjarneo `battery-drip/shell.qml` | 20 / 10 | yes | crossing test, `:106-111` | no |
| Gakuseei_Ricelin `Singletons/Battery.qml` | 20, `:26` | no | — | no |
| Rexcrazy804, josecriane | none | — | — | — |

Two things fall out of that table.

**Nobody tints a background by severity except noctalia, and it has one level,
not two.** `Modules/Bar/Widgets/Battery.qml:240-241` is a single ternary onto
`Color.mError` for low-or-critical together. Everyone else recolours the *icon
or the text*, which is the thing waybar's stylesheet deliberately does not stop
at. So the two-level background wash is waybar's idea and this shell is the only
Quickshell one carrying it.

**The pulse idiom is unanimous.** Every project that animates converges on
`SequentialAnimation on <property>` with `loops: Animation.Infinite` and
`running:` bound to the condition:

```qml
// Brainitech src/services/BatteryStatus.qml:113-119
SequentialAnimation on opacity {
    id: pulseAnim
    running:  root.pct <= 10 && !root.charging
    loops:    Animation.Infinite
    NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutSine }
    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
}
```

noctalia's only looping colour animation is the same shape and pulses **alpha of
one colour** rather than between two hues, which reads as a breath instead of a
strobe (`Modules/LockScreen/LockScreenHeader.qml:64-77`). That is the version
copied here.

The one trap, and Brainitech is the only project that handles it: `<Animation>
on <property>` *takes ownership* of the property, so when it stops the property
keeps whatever the last frame left. Brainitech patches it up afterwards with a
`Connections { onRunningChanged: ... }` (`:121-127`). `Ring.qml` avoids needing
that by animating a private scalar and leaving the colour a binding that reads
`breath.running ? pulse : 1` — when the animation stops the binding falls back to
full wash in the same frame, with nothing to restore.

## Notifications

`Quickshell.Services.Notifications` is **receive-only**. `NotificationServer` is
the whole module; it is how a shell replaces dunst, and nothing in sixteen trees
sends through it. Confirmed against
`quickshell-0.3.0/lib/qt-6/qml/Quickshell/`, and by every consumer:
noctalia `Services/System/NotificationService.qml:7,47`, tripathiji1312
`shell.qml:6,27`, vast-shell `Qml/Services/Notifs.qml:6,133`, skwd
`skwd-notification/qml/NotificationShell.qml:3,47`.

So an outbound notification is `notify-send`, and since this shell owns
`org.freedesktop.Notifications` the call lands in its own card stack — verified
on the bus, `busctl --user list` showing the name owned by the shell's pid and
`dbus-monitor` catching the round trip. `Quickshell.execDetached(list<string>)`
is real: `quickshell-core.qmltypes:1046-1049`.

## What this shell does

`Ring.qml` gains `warnAt` / `critAt` in heat's terms, a `level`, and a wash over
the ring's ground at 18% (warning) and 24% (critical) of `Theme.warn` /
`Theme.bad`. `blink` is opt-in; only the disk rings and the battery ring set it.

| ring | warning | critical | blinks |
|---|---|---|---|
| battery | 30% | 15% | yes, while discharging |
| disk (per mount) | 90% | 95% | yes |
| cpu, ram, gpu, temp, fan | 70 | 90 | no |

Battery and disk thresholds are waybar's, unchanged — this is the warning he
already had and lost, not a new opinion about it. cpu/ram/gpu/temp/fan keep
`Theme.heat`'s existing 70/90 steps, so the wash appears exactly where the arc
already changed colour and there is not a second table of numbers to disagree
with the first.

### Contrast

The wash sits under a 10px number in `Theme.fg`, and an earlier attempt at this
left that number at 1.3:1. Measured across all 335 schemes in `schemes.js`, as
`Qt.tint` composites it over `Theme.bgHi`:

| scheme | untinted | warning | critical |
|---|---|---|---|
| Gruvbox dark medium | 5.14 | 3.66 | 4.31 |
| Everforest (dark) | 4.75 | 3.51 | 3.68 |
| Everforest dark hard | 5.30 | 3.68 | 3.79 |
| Everforest Light (Medium) | 4.29 | 3.86 | 3.37 |
| One Light | 9.01 | 7.68 | 6.09 |
| Github (light) | 4.47 | 4.08 | 3.29 |
| Tokyo Night Dark | 5.76 | 4.27 | 3.29 |

Median cost across all 335 is 22%. The floor in the schemes Erik uses is 3.3:1,
above the 3:1 bar for bold text at this size and two and a half times the 1.3:1
that failed. 59 of the 335 schemes are already below 3:1 *untinted* — base05 on
base02 is not this shell's choice and the wash is not what breaks them.

Alpha was chosen by sweep, not by eye: 0.16/0.20 costs 20% median and washes too
faintly to catch peripheral vision, 0.20/0.28 costs 26% and takes Tokyo Night's
critical to 3.00. 0.18/0.24 is the knee.

### Measured, on a 1080px screen

Blink period, sampled every 192 ms and fitted on interpolated mid-crossings:

| state | nominal | measured |
|---|---|---|
| critical | 4000 ms | 3839 / 3840 / 3841 / 3840 / 3841 ms |
| warning | 6000 ms | 5760 / 5761 ms |

Both run 4% fast on this host's virtual output — the animation clock, not the
code: the 1.5 ratio between the two is exact. Ground alpha traces
`0x07..0x2e` (0.027–0.180) warning and `0x09..0x3d` (0.035–0.239) critical,
which is the 0.15 pulse floor times the two wash alphas.

Notification, driven with a faked battery through 100 → 27 → 24 → 11: exactly
two `Notify` calls on the bus, `"Battery low" / "27% left — plug in soon"` and
`"Battery critical" / "11% left — plug in now"`. The 24% step, still inside the
warning band, produced none.
