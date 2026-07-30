# Surveys

Prior-art surveys done for this shell, kept because they cost hours to produce
and every claim in them cites a real file and line in a real project. Read the
relevant one before rewriting the widget it covers.

| File | Question it answers |
|---|---|
| `osd-survey.html` / `osd-survey.png` | How do fourteen Quickshell shells build the volume/brightness OSD — dwell time, how they detect a change made outside the shell, whether they show a number, how they render mute, how they avoid popping at startup? |
| `player-survey.qml` / `player-survey.png` | How do ten shells fit a now-playing widget into a narrow vertical rail — art, title, transport controls, and what they drop when there is no room? |
| `clock-survey.qml` / `.md` / `.png` | How do thirteen shells fit hours, minutes, day and month into a 58px vertical strip, and what does each design actually cost in pixels of rail height? |
| `clock-compact.qml` / `.md` / `.png` | Can the same four fields go *below* 36px? Fifteen new designs measured for height and width against the shipped `RailClock` — including the ones that fail, and why turning the clock's reading direction costs 124px. |
| `hover-survey.md` | How do sixteen projects colour and animate the workspace pill on hover, and where does the hover state live (`MouseArea` vs `HoverHandler`)? |
| `control-centre.md` | When sixteen shells put several unrelated things behind one button, how do they page between them and how does the panel size itself — and where did each of them put the settings GUI? Also: does a vertical bar round its corners, and how do they mark the bar button whose panel is open? |
| `wallpaper-survey.md` | How do six projects build a wallpaper + theme switcher — where the images come from, how the wallpaper is applied and persisted, how themes are stored, and whether light/dark is declared or guessed from luminance? |
| `hyprland-lua.md` | Does an earlier session about rewriting the Hyprland config in Lua exist? (No — every transcript store was searched; the answer and the search scope are written down so nobody looks again.) |
| `requirements-audit.md` | Which ticked boxes in `REQUIREMENTS.md` were not actually done, checked against the code and the running shell rather than against the document? |
| `requirements-audit-2.md` | Same, redone against all 86 extracted user messages in order — the fuller and later of the two. |

The `.html` and `.qml` files are the sources the contact sheets were rendered
from. All of them are scrollable and searchable, and all of them can be
re-rendered after an edit — open the HTML in a browser, run a QML sheet with
`quickshell -p docs/surveys/player-survey.qml` or
`quickshell -p docs/surveys/clock-survey.qml`. Each QML sheet is a harness that
mocks a set of designs side by side at the rail's true width; nothing in them
ships, and they import the shell by absolute path, so fix the path if the repo
moves. `clock-survey.qml` measures each mock rather than labelling it, so the
heights under it stay honest if a font changes; `clock-compact.qml` measures
width the same way, because once a clock goes horizontal the rail runs out
sideways before it runs out of height.
