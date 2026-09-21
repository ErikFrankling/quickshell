# Keep the agent desktop out of the human shell

The headless `AGENT-1` output shares Hyprland's monitor and workspace lists
with the physical desktop. Filter it before creating shell windows, and filter
its workspaces before creating workspace pills. The named `agent` workspace
also stays hidden while its output is being created or removed.

Idioms checked on 2026-09-21:

- [end-4 Bar.qml](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/ii/bar/Bar.qml#L15-L23)
  filters `Quickshell.screens` by screen name directly in the `Variants` model.
- [Caelestia Bar.qml](https://github.com/caelestia-dots/shell/blob/main/modules/bar/Bar.qml#L100-L105)
  filters values before handing them to `ScriptModel`.
- [HyprlandWorkspace API](https://quickshell.org/docs/v0.1.0/types/Quickshell.Hyprland/HyprlandWorkspace/)
  exposes `name` and `monitor`; the latter avoids relying on stale IPC JSON.

The source changes use these existing array-filter idioms. Human workspaces
retain their existing numeric/name sorting, icons, urgency, and click behavior.
Notification popup windows are also excluded from the agent output.
