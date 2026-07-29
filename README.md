# quickshell

My desktop shell for Hyprland, built on [Quickshell](https://quickshell.org).
A left sidebar with metrics, notifications, control panels and a launcher.

Replaces waybar and a separate notification daemon with one process.

## Running

```bash
nix run .
```

Starts from the working tree. Edit any `.qml` file and it reloads live — same
process, no rebuild. That's the development loop.

Not wired into the system config yet. Once it's better than what it replaces,
it gets a Home Manager module like everything else.

## Layout

```
shell.qml     entry point
docs/         research: every Quickshell project worth reading, and a design gallery
```

## docs/

`docs/catalogue.md` lists every Quickshell project above 50 stars, what each one
does well, and which files to read to learn idiomatic QML. `docs/gallery.html` is
the same set as screenshots, for design reference.

Both exist because QML is thin on the ground in model training data, so any
session working here should read real examples before writing. See
[AGENTS.md](AGENTS.md).
