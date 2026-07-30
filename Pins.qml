pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick

// Which system tray icons sit on the rail.
//
// Tray icons and nothing else. The rail's own buttons are written out in
// shell.qml and are not removable: moving one is a code change, not a setting.
// Noctalia's tray drawer draws the same line — it pins tray items and never
// touches the bar's own widgets.
//
// Two states, and unpinned is the default, so an icon that appears mid-session
// never shoves the rail around. It is not lost by being unpinned: every tray
// item is listed in the flyout whether it is pinned or not.
Singleton {
    id: root

    property list<string> pinned: []

    // The one list the rail reads.
    readonly property var railTray: SystemTray.items.values.filter(i => root.pinned.includes(root.idOf(i)))

    // The StatusNotifierItem Id — the app picks it and it is the same string
    // next launch. tooltipTitle is not: it carries unread counts and sync state,
    // so a pin keyed on it silently detaches.
    function idOf(item) {
        return item.id || item.title;
    }

    function has(id) {
        return root.pinned.includes(id);
    }

    // Copy and reassign, never push: mutating a list in place does not notify,
    // so every binding reading it goes stale. This is the bug in this space.
    function toggle(id) {
        root.pinned = root.has(id) ? root.pinned.filter(x => x !== id)
                                   : root.pinned.concat([id]);
        store.setText(JSON.stringify({ pinned: root.pinned }));
    }

    FileView {
        id: store
        path: Quickshell.statePath("pins.json")
        atomicWrites: true
        // No file yet is a first run, not an error, and the empty list above is
        // already what it would have said: nothing pinned.
        printErrors: false
        // Only the one key is read, so a file written by the version that also
        // kept a "hidden" list loads with its pins intact and drops the rest on
        // the next write.
        onLoaded: {
            try {
                root.pinned = JSON.parse(text()).pinned ?? [];
            } catch (e) {}
        }
    }
}
