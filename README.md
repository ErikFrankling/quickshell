# quickshell

My desktop shell for Hyprland, built on [Quickshell](https://quickshell.org).
A left sidebar with metrics, notifications, control panels and a launcher.

Replaces waybar and a separate notification daemon with one process.

## Running

This is the real desktop shell, started on login by `erikshell.service` from a
store copy. It replaces waybar, wofi and the old AGS shell, and it owns
`org.freedesktop.Notifications`.

## Developing

Two ways to iterate, and the second is the good one.

**A second shell alongside the installed one:**

```bash
nix run .
```

Runs from the working tree and reloads any `.qml` file the moment it is saved.
Stop the unit first, or the two fight over the notification name and the tray:

```bash
systemctl --user stop erikshell
```

That only gets you the sidebar and its panels, though. Notifications, the
launcher and everything else that reaches the rest of the desktop still belong
to whichever instance holds the D-Bus name.

**The whole desktop, hot-reloading — `localDev`:**

```nix
programs.erikshell.localDev.enable = true;
```

In `hosts/<host>/home.nix` in the dotfiles. The unit's `ExecStart` then points
at `~/projects/personal/quickshell` instead of the store, so the shell that
comes up on login is the working tree. Save a file and the *live* desktop
reloads — sidebar, notifications, launcher, OSD, tray, all of it, in the process
that actually owns the D-Bus name.

One rebuild to turn on, one to turn off. That is the whole cost, and it is why
it is a flag rather than the default: a store path is what you want when you are
using the machine, and the working tree is what you want when you are changing
it.

It reuses this flake's own `apps.default`, the same script `nix run .` invokes,
so the development and production runtime environments cannot drift apart.

The option is defined in `modules/home-manager/erikshell.nix` in the dotfiles,
not here, because it names a path that only exists on Erik's machines.

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
