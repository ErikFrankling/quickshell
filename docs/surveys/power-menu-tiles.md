# Centered power tiles (2026-11-10)

Erik requested the familiar centered power overlay, then explicitly requested
large beautiful controls based on popular community designs. Five direct
actions, no logout, no confirmation, no explanatory copy. Native logind
capability checks remain; unsupported hibernation stays disabled.

## References actually read

- [r/unixporn: What do you think?](https://www.reddit.com/r/unixporn/comments/1n0if4i/hyprland_what_do_you_think/)
  indexed at 1,010 votes in search; this is a highly voted example, not a claim
  to have ranked every Reddit post. Its linked
  [wlogout CSS](https://github.com/huuquockiet/dots/blob/c952fa9013b3cfa460eebce0bd35eb47ff5824c0/.config/wlogout/style.css)
  uses large rounded tiles, spaced apart, short fade/hover transitions and a
  backdrop. Source excerpt: `border-radius: 30; background-size: 25%;
  transition: all 100ms ease-in;`. Keep its visual hierarchy, not its hardcoded
  white palette or desktop-specific artwork.
- [Illogical Impulse SessionActionButton](https://github.com/end-4/dots-hyprland/blob/cb1c428bf841dabccff1b126904047c28e89ba8c/dots/.config/quickshell/ii/modules/ii/sessionScreen/SessionActionButton.qml)
  uses 120px buttons, 45px icons, changing corner radius and background on
  hover/focus, with native key navigation. Source excerpt: `property real
  size: 120`; `buttonRadius: (button.focus || button.down) ? size / 2 :
  Appearance.rounding.verylarge`. The containing SessionScreen centers its
  grid and uses `exclusionMode: ExclusionMode.Ignore` to cover the full screen.
- [Quickshell's wlogout example](https://github.com/quickshell-mirror/quickshell-examples/blob/c6d1236efe265ae34e8c78a27ee9e196ea19d895/wlogout/WLogout.qml)
  uses a full-screen overlay, centered icon grid, labels under icons, Escape
  and outside click dismissal. Source excerpt: `anchors.centerIn: parent`;
  `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive`.
- Caelestia `modules/session/Content.qml` was also read: icon buttons with
  native keyboard navigation, distinct focused backgrounds and changing
  radii. Its vertical sidebar arrangement is not the user's requested layout.

## Applied

A 696px centered card holds five equal tiles, with 38px icons and one short
label each. A theme-colored scrim gives contrast against busy windows. Colors
come from Theme; only shutdown uses the existing danger accent. Hover/focus
changes radius and tint over 140ms. Qt AbstractButton supplies button semantics,
Tab/Space; explicit left/right navigation and Enter work without custom input
injection. No new generic widget, service, or configuration abstraction.

Visual proof is a real Quickshell render on the agent output, then the deployed
Samsung overlay. No power actions are executed to test appearance.
