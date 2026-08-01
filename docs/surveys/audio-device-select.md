# Picking an output and an input device

Written because "I can't select input and output device" turned out not to be a
bug in the enumeration, the setter or the tracker — all three already matched
what everybody else does — but in what the panel showed when there was nothing
to pick. The survey is kept anyway, because the tracker question below has a
clear answer that is easy to get wrong, and because it records what the
Quickshell API actually offers so the next person does not have to re-read the
metadata.

Paths are relative to each project's own root. The fifteen clones were read from
a scratchpad that no longer exists; the catalogue in `docs/catalogue.md` says
where each one lives.

## What the API actually is

Read off
`/nix/store/*quickshell-0.3.0/lib/qt-6/qml/Quickshell/Services/Pipewire/quickshell-service-pipewire.qmltypes`
rather than assumed, because this repo has shipped against five Quickshell APIs
that did not exist:

| Member | Verdict |
|---|---|
| `Pipewire.preferredDefaultAudioSink` | Real. `qml.hpp:114`, type `PwNodeIface*`, **writable** (`write: setDefaultConfiguredAudioSink`). Takes the node object, not an id and not a name. |
| `Pipewire.preferredDefaultAudioSource` | Real. `qml.hpp:121`, same shape. |
| `Pipewire.defaultAudioSink` / `...Source` | Real, **read-only** — these are the *current* default, and they follow a change made outside the shell. Assigning to them is the mistake to avoid; the `preferred*` pair is the writable one. |
| `PwNode.isSink`, `isStream`, `description`, `nickname`, `name`, `audio` | All `isPropertyConstant: true` — readable **without** a `PwObjectTracker`. |
| `PwNode.properties`, `PwNode.ready`, and everything on `PwNodeAudio` (`volume`, `muted`) | Have notify signals and report nothing until the node is tracked. This is the half that needs `PwObjectTracker`. |
| `Pipewire.nodes` | `UntypedObjectModel`, `isPropertyConstant` — the model object never changes, but `.values` notifies, so a binding that reads `.values` does re-run when a node appears. Verified live: loading a null sink made the list grow without a reload. |

So a device list renders its *names* fine untracked, and goes dead — no volume,
no mute, empty `properties` — the moment you read anything else. That asymmetry
is why "the list renders but selecting does nothing" is a plausible-sounding
bug, and why the tracker column below matters.

`PwNodeType` exists but nobody uses it for enumeration; see below.

## The fifteen shells

Nine of the fifteen have a device picker. Six do not: `diinki_linux-retroism`
(no audio at all), `doannc2212_quickshell-config` (default sink only,
`osd/OSD.qml:22-24`), `shub39_dotfiles`, `tripathiji1312_quickshell`
(`services/Audio.qml`, polls `wpctl get-volume` on a 1 s timer),
`diinki_linux-antiquity` (default sink only), and `maxchennn_vroomies` (shells
out to `wpctl … @DEFAULT_AUDIO_SINK@`).

| Project | Enumeration filter | Sets the default with | `PwObjectTracker.objects` | Name | Model | Empty state |
|---|---|---|---|---|---|---|
| noctalia | `!isStream`, then `isSink` vs `audio`; drops its own `quickshell` node | `preferredDefaultAudioSink` (`Services/Media/AudioService.qml:1231`) | **whole list** `[...sinks, ...sources]` (:349) | `description` | live array | no |
| Gakuseei_Ricelin | `isSink && !isStream && audio`; sources also `!/monitor/i` | `preferredDefaultAudioSink` (`pill/Mixer.qml:470`) | **whole list** (:182) | `description \|\| nickname \|\| name` | live array | no |
| liixini_skwd | `n && n.isSink && !n.isStream && n.audio` | `preferredDefaultAudioSink` (`VolumeDropdown.qml:153`) | **whole list** (:86-92) | `description \|\| name \|\| "Unknown Output"` | live `.values.filter()` in `model:` | no |
| Brainitech_Brain_Shell | `audio !== null && !isStream && isSink` | `preferredDefaultAudioSink` (`AudioControl.qml:127`) | **everything** — `Pipewire.nodes.values` (:15) | `nickname \|\| description \|\| name` | live array | **yes** (:131-137, :156-162) |
| josecriane | `!isStream`, then `isSink` vs `audio` | `preferredDefaultAudioSink` (`services/Audio.qml:44`) | **whole list** (:73) | `description` | live array | no |
| corecathx_whisker | `isSink && !isStream && audio` | `preferredDefaultAudioSink` (`services/Audio.qml:62`) | the **model object** `[…, Pipewire.nodes, Pipewire.links]` (:11-18) | `description` | `.map(s => s.description)` — loses node identity | **yes** (`SoundsMenu.qml:225-250`) |
| Zaphkiel kurukurubar | `node.audio` only — streams **not** excluded | `preferredDefaultAudioSink` (`AudioSlider.qml:69`) | **whole list** `sModel.values` (`AudioTab.qml:31-33`) | hover-dependent | **ScriptModel** | no |
| Zaphkiel kurumibar | `audio != null && !description.startsWith("Tiger")` | same | **per delegate** `[modelData]` (`SoundChannelMenu.qml:73`) | `description == "" ? name : description` | **ScriptModel** | no |
| myamusashi_vast-shell | `isSink && !isStream`, mapped to plain JS objects | **`wpctl set-default <id>`** via `execDetached` (`VolumeSettings.qml:105-107`) | only `[defaultAudioSink]` | `description` | **ScriptModel** | no |
| bjarneo | parses `wpctl status` with awk — no Pipewire module | `wpctl set-default` (`Navbar.qml:310`) | n/a | awk field | live array | no |

## The tracker question

**Every project that offers a picker tracks the whole candidate list, not just
the two defaults.** Three shapes, in descending tidiness:

```qml
// noctalia Services/Media/AudioService.qml:347-349
// Bind all devices to ensure their properties are available
PwObjectTracker { objects: [...root.sinks, ...root.sources] }
```

```qml
// Brainitech_Brain_Shell src/services/AudioControl.qml:14-16
PwObjectTracker { objects: Pipewire.nodes.values }
```

```qml
// Zaphkiel kurumibar Components/SoundChannelMenu.qml:73
PwObjectTracker { objects: [ modelData ] }   // one per delegate
```

The only projects that track just the defaults are the ones with no picker, or
`myamusashi`, which bypasses the Pipewire API and shells out to `wpctl` — it has
no node object to read, so it has nothing to track. This shell already tracks
the whole list (`Audio.qml:36-38`), which is the noctalia shape.

## Enumeration

`isSink && !isStream && audio` is the idiom — five of nine write exactly that.
The `audio` term is what removes the MIDI bridges and the v4l2 camera, which are
otherwise indistinguishable from a device by the two flags alone. Nobody uses
`PwNodeType` for this; it shows up only in screenshare/privacy indicators
(`corecathx_whisker/services/Privacy.qml:15-21`,
`myamusashi_vast-shell/Qml/Services/Privacy.qml:12-13`).

Gakuseei is the only one that kills monitor sources, and says why:

```qml
// Gakuseei_Ricelin pill/Mixer.qml:41-57
// … The sink monitors that Pipewire exposes alongside real mics also match
// isSink=false, so they are dropped by name to keep the list to actual
// capture devices.
if (n && !n.isSink && !n.isStream && n.audio && !/monitor/i.test(n.name || ""))
```

On this machine that filter is dead code: PipeWire exposes a sink's monitor as
*ports* on the sink node, not as a node of its own, so nothing named `monitor`
ever reaches the list. It is worth knowing about rather than copying.

Two anti-patterns worth naming. Zaphkiel filters on `node.audio` alone, so
per-application streams land in the device list and get a meaningless "make
default" button, patched over with `visible: !root.node?.isStream`
(`AudioSlider.qml:58`). And kurumibar hardcodes one machine's hardware:
`!node.description.startsWith("Tiger")`.

## Empty and single-device states

Two of nine handle empty. **None** of the nine handle "only one device" — every
one of them renders a single row that highlights, shows a pointing-hand cursor,
and does nothing when clicked, because it is already the default.

```qml
// Brainitech_Brain_Shell src/services/AudioControl.qml:131-137
Text {
    visible: root.sinkNodes.length === 0
    text:    "No output devices"
    ...
}
```

corecathx does the fullest job — an icon-and-label empty card, plus every input
control gated on `Audio.sources.length > 0` (`SoundsMenu.qml:216, 253, 261, 300,
309, 341`). Gakuseei's popup instead collapses to a 4px sliver
(`Mixer.qml:409`), which is the worst of the three: it neither lists nor
explains.

`diinki_linux-antiquity` has no picker but does have the minimal form of the
honest string, which is the one idea worth taking:

```qml
// configs/quickshell/AudioSystem.qml:11
readonly property string audioDeviceName:
    sink?.description || sink?.name || "No Device Detected"
```

## What this machine actually has

Measured with `wpctl status` and `pw-dump`, not assumed:

- **One** audio sink — `alsa_output.usb-FIIO_FiiO_K11-01.analog-stereo`,
  "FiiO K11 Analog Stereo".
- **Zero** audio sources.
- Five ALSA *devices*, four of them with their profile set to `off`. The two
  HDMI devices and the Ryzen controller offer nothing but `off` and `pro-audio`,
  so there is genuinely no second output. The Unitek Y-247A adapter is the only
  one holding anything back: with profile `input:mono-fallback` it produces a
  real `Audio/Source`, and it is switched off.

Quickshell's Pipewire service exposes `nodes`, `links` and `linkGroups` and
**no device or profile API at all**, so a shell built on it cannot turn a
profile on — only `wpctl set-profile` or `pavucontrol` can. That is why the
list is honestly empty rather than wrongly filtered, and it is the reason the
fix is a sentence rather than a feature.

One thing the survey does *not* justify: `media.class=Audio/Source/Virtual`
(what `module-null-sink` creates for a virtual mic) is classified by Quickshell
as `type=0`, `audio=null` — it is **not** picked up as a source, even while
`Pipewire.defaultAudioSource` happily points at it. Real hardware sources are
plain `Audio/Source` (`type=9`) and enumerate correctly. Anyone testing an input
picker with a null sink will conclude the filter is broken when it is not.
