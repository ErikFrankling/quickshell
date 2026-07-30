pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick

// Which system tray icons sit on the rail and which live behind the chevron.
//
// Tray icons and nothing else. The rail's own buttons are written out in
// shell.qml and are not removable: moving one is a code change, not a setting.
// Noctalia's tray drawer draws the same line — it pins tray items and never
// touches the bar's own widgets.
//
// Three states, not two: pinned (on the rail), overflow (in the flyout) and
// hidden (nowhere). Overflow is the default, so an icon that appears
// mid-session never shoves the rail around. Plasma's system tray stores exactly
// this — a shownItems list, a hiddenItems list and nothing for the default —
// in systemtraysettings.cpp, and Windows 11 starts new icons behind the chevron.
Singleton {
    id: root

    property list<string> pinned: []
    property list<string> hidden: []

    // The one list the rail reads.
    readonly property var railTray: SystemTray.items.values.filter(i => root.state(root.idOf(i)) === "pinned")

    // The StatusNotifierItem Id — the app picks it and it is the same string
    // next launch. tooltipTitle is not: it carries unread counts and sync state,
    // so a pin keyed on it silently detaches.
    function idOf(item) {
        return item.id || item.title;
    }

    function state(id) {
        return root.hidden.includes(id) ? "hidden"
            : root.pinned.includes(id) ? "pinned" : "overflow";
    }

    // Copy and reassign, never push: mutating a list in place does not notify,
    // so every binding reading it goes stale. This is the bug in this space.
    function set(id, s) {
        root.pinned = root.pinned.filter(x => x !== id);
        root.hidden = root.hidden.filter(x => x !== id);
        if (s === "pinned")
            root.pinned = root.pinned.concat([id]);
        else if (s === "hidden")
            root.hidden = root.hidden.concat([id]);
        store.setText(JSON.stringify({ pinned: root.pinned, hidden: root.hidden }));
    }

    FileView {
        id: store
        path: Quickshell.statePath("pins.json")
        atomicWrites: true
        // No file yet is a first run, not an error, and the empty lists above
        // are already what it would have said: everything behind the chevron.
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.pinned = d.pinned ?? [];
                root.hidden = d.hidden ?? [];
            } catch (e) {}
        }
    }
}
