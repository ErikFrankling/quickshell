# quickshell

My desktop shell for Hyprland, built on [Quickshell](https://quickshell.org).
A left sidebar with metrics, notifications, control panels and a launcher.

Replaces waybar and a separate notification daemon with one process.

## Running

This is the real desktop shell, started on login by `erikshell.service` from a
store copy. It replaces waybar, wofi and the old AGS shell, and it owns
`org.freedesktop.Notifications`.

## Developing

Three ways to iterate. The first is the one to reach for.

**The whole desktop, hot-reloading, no rebuild — `erikshell-dev`:**

```bash
erikshell-dev on      # the unit now runs the working tree
erikshell-dev off     # back to the store copy
erikshell-dev         # which mode is live, and where it is running from
```

Points the running `erikshell.service` at `~/projects/personal/quickshell` by
writing a runtime systemd drop-in over its `ExecStart`, and restarts it. Save a
`.qml` file and the *live* desktop reloads — sidebar, notifications, launcher,
OSD, tray, all of it, in the process that owns the D-Bus name. One instance, no
rebuild either way.

The drop-in lives in `$XDG_RUNTIME_DIR`, so a reboot puts the store copy back on
its own; a rebuild does not, and the shell stays on the working tree until you
say otherwise. `erikshell-dev` with no argument is how you find out which.

If the working tree does not load, the unit is swapped straight back to the
store copy and the command says so — a broken `.qml` cannot leave you with no
shell.

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

**The same swap, but across reboots — `localDev`:**

```nix
programs.erikshell.localDev.enable = true;
```

In `hosts/<host>/home.nix` in the dotfiles. The unit's `ExecStart` then points
at `~/projects/personal/quickshell` instead of the store, so the shell that
comes up on login is the working tree. Save a file and the *live* desktop
reloads — sidebar, notifications, launcher, OSD, tray, all of it, in the process
that actually owns the D-Bus name.

One rebuild to turn on, one to turn off. That is the whole cost, and it buys the
one thing `erikshell-dev` does not do: the working tree is still what comes up
after a reboot. Otherwise prefer the command.

Both reuse this flake's own `apps.default`, the same script `nix run .` invokes,
so the development and production runtime environments cannot drift apart.

The option and the command are both defined in
`modules/home-manager/erikshell.nix` in the dotfiles, not here, because they
name a path that only exists on Erik's machines.

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
