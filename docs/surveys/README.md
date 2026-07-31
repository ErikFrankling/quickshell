# Surveys

Prior-art surveys done for this shell, kept because they cost hours to produce
and every claim in them cites a real file and line in a real project. Read the
relevant one before rewriting the widget it covers.

| File | Question it answers |
|---|---|
| `osd-survey.html` / `osd-survey.png` | How do fourteen Quickshell shells build the volume/brightness OSD — dwell time, how they detect a change made outside the shell, whether they show a number, how they render mute, how they avoid popping at startup? |
| `player-survey.qml` / `player-survey.png` | How do ten shells fit a now-playing widget into a narrow vertical rail — art, title, transport controls, and what they drop when there is no room? |
| `player-seek-bar.md` | Nine of fifteen shells draw a progress bar in the media panel — where the elapsed and total times go, why every one of them re-emits `positionChanged()` on a timer, and how each gates the seek. Plus what Spotify actually does with `SetPosition` when you wait longer than a second for it, and why the album art was leaving a hole in the panel but not on the rail. |
| `clock-survey.qml` / `.md` / `.png` | How do thirteen shells fit hours, minutes, day and month into a 58px vertical strip, and what does each design actually cost in pixels of rail height? |
| `clock-compact.qml` / `.md` / `.png` | Can the same four fields go *below* 36px? Fifteen new designs measured for height and width against the shipped `RailClock` — including the ones that fail, and why turning the clock's reading direction costs 124px. |
| `metric-fraction.qml` / `.md` / `.png` | A ring says two things and memory and the disks have three — a name, a used value and a total. Twenty-one layouts drawn at the rail's true 58px and measured for what they claim, what they draw and what they cost the rail; plus what six other shells do with two numbers in a narrow strip, and why the mount path stays in the monitor panel. |
| `hover-survey.md` | How do sixteen projects colour and animate the workspace pill on hover, and where does the hover state live (`MouseArea` vs `HoverHandler`)? |
| `pill-bounds.qml` / `.md` | What tells you where one workspace pill ends and the next begins — twenty designs at the rail's true 58px, on the group's real ground, with the empty workspace and the two-digit one drawn as well as the easy cases. Measured in CIE L\* rather than a WCAG ratio because the ratio compresses at the light end and calls two very different borders the same. Two rounds: why a filled ground loses to a hover colour that has not moved, and then the three-step ladder — idle, hover, focused — that lets the ground in, measured on all nine curated palettes. Also why a separator rule between pills is cheaper ink and still the wrong answer, and what the pill going back from 28px to 24px does to the rail's budget. |
| `vpn-glyph.md` | Which glyph reads as "VPN" at the rail's 15px — what five shells use, and every candidate rendered at that size, including why the Nerd Font glyph actually named `vpn` cannot be used. |
| `network-glyph.qml` / `.md` / `.png` | Can the link type *and* the tunnel fit in one 28px rail slot — sixteen designs measured for how many of the slot's 784 pixels change, how thin the changing mark is, and whether ethernet, wifi and offline stay apart while the tunnel is up. Also: does the tunnel matcher catch OpenVPN as well as WARP, proved with the real binary in a network namespace, and both at once. |
| `control-centre.md` | When sixteen shells put several unrelated things behind one button, how do they page between them and how does the panel size itself — and where did each of them put the settings GUI? Also: does a vertical bar round its corners, and how do they mark the bar button whose panel is open? |
| `wallpaper-survey.md` | How do six projects build a wallpaper + theme switcher — where the images come from, how the wallpaper is applied and persisted, how themes are stored, and whether light/dark is declared or guessed from luminance? |
| `warning-states.md` | What did his waybar actually do when a metric went bad — the thresholds, which modules blinked and which only coloured, and why the stated blink duration is half the period? Plus what nine Quickshell shells do about low battery, the one pulse idiom they all share, why `NotificationServer` cannot send, and the contrast cost of a two-level background wash measured across all 335 schemes. |
| `notification-history.md` | Which shells write their notification history to disk, where they put it, what they cap it at, how often they write, and what they do about an image path that is gone by the next boot — plus where "unread" has to live if it is to mean anything after a restart. |
| `notification-popup.md` | How long does a popup stay up in thirteen other shells, do they honour the sender's `expireTimeout` (five try, four get `0` wrong), does critical ever expire, and do they pause on hover? Plus: whose icon goes on the card, why only three of thirteen ask whether the name exists first, and the two things every one of them gets wrong about this machine — `--icon` no longer arrives in the `app_icon` field, and Quickshell has already done the desktop-entry lookup for you. Before-and-after timings measured on the running shell. |
| `hyprland-lua.md` | Does an earlier session about rewriting the Hyprland config in Lua exist? (No — every transcript store was searched; the answer and the search scope are written down so nobody looks again.) |
| `requirements-audit.md` | Which ticked boxes in `REQUIREMENTS.md` were not actually done, checked against the code and the running shell rather than against the document? |
| `requirements-audit-2.md` | Same, redone against all 86 extracted user messages in order — the fuller and later of the two. |
| `requirements-audit-3.md` | The current one, written after seven background agents stopped mid-task: what each of them had actually finished, and every doubtful box re-derived from the code instead of from the two audits above. Also records two claimed bugs that do not exist, and why exact-colour pixel counting cannot see 11px text. |
| `graph-axis.md` | How do other shells draw a history graph, and does anybody label its Y axis? Six do the first, none the second — and two moved off `Canvas` deliberately, which is why keeping it here had to be justified rather than assumed. |

The `.html` and `.qml` files are the sources the contact sheets were rendered
from. All of them are scrollable and searchable, and all of them can be
re-rendered after an edit — open the HTML in a browser, run a QML sheet with
`quickshell -p docs/surveys/player-survey.qml` or
`quickshell -p docs/surveys/clock-survey.qml`. `network-glyph.qml` goes one step
further and is *measured* rather than looked at: two red registration marks let
a script find its grid in a screenshot and count pixels, which is the only way
to compare marks that are three pixels across. Each QML sheet is a harness that
mocks a set of designs side by side at the rail's true width; nothing in them
ships, and they import the shell by absolute path, so fix the path if the repo
moves. `clock-survey.qml` measures each mock rather than labelling it, so the
heights under it stay honest if a font changes; `clock-compact.qml` measures
width the same way, because once a clock goes horizontal the rail runs out
sideways before it runs out of height. `pill-bounds.qml` *prints* rather than
draws, because the thing it decides cannot be drawn: a survey harness has its
own ShellId and therefore its own empty `theme.json`, so it can only ever be
seen in one scheme, and the question is how a mark behaves across all of them.
It instantiates `Themes.qml` unseen, reads its `curated` list and writes every
design against every curated palette to stdout — so the cross-theme numbers
come from the one place the palettes live rather than from a second copy that
can drift, and the sheet can be quoted by somebody who cannot see the picture.
`metric-fraction.qml` prints too: it walks every built mock once the scene has
settled and writes the whole table to stdout as a TSV, for the same reason.
