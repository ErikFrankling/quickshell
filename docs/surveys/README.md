# Surveys

Prior-art surveys done for this shell, kept because they cost hours to produce
and every claim in them cites a real file and line in a real project. Read the
relevant one before rewriting the widget it covers.

| File | Question it answers |
|---|---|
| `osd-survey.html` / `osd-survey.png` | How do fourteen Quickshell shells build the volume/brightness OSD — dwell time, how they detect a change made outside the shell, whether they show a number, how they render mute, how they avoid popping at startup? |
| `player-survey.qml` / `player-survey.png` | How do ten shells fit a now-playing widget into a narrow vertical rail — art, title, transport controls, and what they drop when there is no room? |
| `hover-survey.md` | How do sixteen projects colour and animate the workspace pill on hover, and where does the hover state live (`MouseArea` vs `HoverHandler`)? |
| `wallpaper-survey.md` | How do six projects build a wallpaper + theme switcher — where the images come from, how the wallpaper is applied and persisted, how themes are stored, and whether light/dark is declared or guessed from luminance? |
| `hyprland-lua.md` | Does an earlier session about rewriting the Hyprland config in Lua exist? (No — every transcript store was searched; the answer and the search scope are written down so nobody looks again.) |
| `requirements-audit.md` | Which ticked boxes in `REQUIREMENTS.md` were not actually done, checked against the code and the running shell rather than against the document? |
| `requirements-audit-2.md` | Same, redone against all 86 extracted user messages in order — the fuller and later of the two. |

The `.html` and `.qml` files are the sources the two contact sheets were
rendered from. Both are scrollable and searchable, and both can be re-rendered
after an edit — open the HTML in a browser, run the QML with
`quickshell -p docs/surveys/player-survey.qml`. The QML is a harness that mocks
ten designs side by side at the rail's true width; nothing in it ships, and it
imports the shell by absolute path, so fix the path if the repo moves.
