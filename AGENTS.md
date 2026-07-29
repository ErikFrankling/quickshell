# Working on this repo

A personal Quickshell desktop shell for Hyprland. Left sidebar, notifications,
control panels, launcher. Not a product — nobody else installs this.

## The two rules

### 1. Write as little code as possible, and make it beautiful

This shell exists because the alternatives were 20,000 to 200,000 lines with
settings GUIs and abstraction layers nobody needed. Do not recreate that.

- No settings GUI. Ever. Configuration is editing the source.
- No option that exists so a widget can ask "should I show this?". If it
  shouldn't show, delete it.
- No abstraction until the same thing appears three times. Two is a coincidence.
- Prefer a short file that does one thing over a general mechanism that does
  four. A 40-line widget you can read beats a 200-line configurable one.
- Colours come from one place. Fonts, spacing and radii come from one place.
  Everything else is a literal in the file that uses it.
- If a file passes ~250 lines, it is doing too much. Split it or cut it.

When you finish a change, the diff should be smaller than you expected.

### 2. Read other people's QML before you write any

**Agents are bad at QML.** There is far less of it in training data than there
is Python or TypeScript, and Quickshell's API is newer than most model
knowledge. Confidently-written QML is very often subtly wrong, or written in a
style no human Quickshell author would use.

So, every session, before editing anything:

- Read `docs/catalogue.md` and open two or three real projects listed there.
- Find the thing you are about to write, already written by someone else, and
  read how they did it. Notification servers, layer-shell panels, PipeWire
  volume, tray menus — all of it exists in the wild.
- Copy the idiom. Do not invent one.

`docs/` holds a catalogue of every Quickshell project above 50 stars, a design
gallery, and the research behind the choices here. It is there so you never have
to guess.

## Running it

```bash
nix run .          # starts the shell from the working tree
```

Edit any `.qml` file and it reloads live — same process, no rebuild. That is
the whole development loop. Do not add a build step.

Take a screenshot after visual changes:

```bash
grim -o <output> /tmp/shot.png
```

## Things that will bite you

- Quickshell has no module for CPU, memory, disk, temperature, GPU, fan or
  swap. Read `/proc` or run a command.
- Quickshell has no brightness module. Shell out to `brightnessctl`.
- The notification server advertises almost nothing by default. If actions or
  images do not work, you did not set `actionsSupported` / `imageSupported`.
- Do not run this and another notification daemon at once — they fight over the
  same D-Bus name.
- Keep `//@ pragma ShellId` set, or state and cache directories move around.
