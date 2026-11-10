# Power menu (2026-11-10)

Read before implementation:

- [Quickshell examples, WLogout.qml](https://github.com/quickshell-mirror/quickshell-examples/blob/master/wlogout/WLogout.qml): layer surface over applications, exclusive keyboard focus, Escape and outside-click dismissal, action model.
- [DankMaterialShell PowerMenuContent.qml](https://github.com/AvengeMedia/DankMaterialShell/blob/master/quickshell/Modules/PowerMenu/PowerMenuContent.qml): action list and explicit confirmation before ending a session.
- [DankMaterialShell SessionService.qml](https://github.com/AvengeMedia/DankMaterialShell/blob/master/quickshell/Services/SessionService.qml): native systemctl/loginctl actions, capability checks and visible command failures.

Reuse our existing rail/panel surface and Entry rows instead of a second modal
implementation. Query logind CanSuspend/CanHibernate/CanReboot/CanPowerOff on
each panel load, rather than equating kernel disk sleep support with configured
hibernation. Disabled actions remain visible. Lock uses loginctl and the native
hypridle/hyprlock integration; sleep uses logind's existing sleep/lock lifecycle.
Logout/restart/shutdown require a separate confirmation. No disruptive power
actions are executed during UI testing.

The sidebar button opens a centered overlay, matching this shell's
`KeysWindow.qml` and `LauncherWindow.qml` (full-screen transparent overlay,
centered card, exclusive keyboard focus only while open, Escape/outside-click
close). `PowerWindow.qml` reuses that existing pattern. It is not an anchored
rail popover.
