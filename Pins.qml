pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick

// Which rail items sit on the rail and which live behind the chevron.
//
// Three states, not two: pinned (on the rail), overflow (in the flyout) and
// hidden (nowhere). Overflow is the default, so a tray icon that appears
// mid-session never shoves the rail around. Plasma's system tray stores exactly
// this — a shownItems list, a hiddenItems list and nothing for the default —
// in systemtraysettings.cpp, and Windows 11 starts new icons behind the chevron.
Singleton {
    id: root

    property list<string> pinned: []
    property list<string> hidden: []

    // Opening a widget's panel from the flyout. shell.qml owns the page and the
    // flyout is loaded inside it, so the request has to come back out here.
    signal activate(string id)

    // The rail's own widgets, addressed by name and never by position: a
    // widget's index changes the moment another one moves to the flyout.
    // `fixed` marks the three that have their own shape and their own place on
    // the rail; the rest are interchangeable buttons in one cluster.
    readonly property var widgets: [
        { id: "workspaces", glyph: "󰕰", label: "Workspaces", fixed: true },
        { id: "monitor", glyph: "󰍹", label: "System monitor", fixed: true },
        { id: "looks", glyph: "󰸉", label: "Looks" },
        { id: "audio", glyph: "󰕾", label: "Audio" },
        { id: "network", glyph: "󰤨", label: "Network" },
        { id: "bluetooth", glyph: "󰂯", label: "Bluetooth" },
        { id: "player", glyph: "󰝚", label: "Media" },
        { id: "notifs", glyph: "󰂚", label: "Notifications" },
        { id: "clock", glyph: "󰥔", label: "Clock", fixed: true }
    ]

    // Everything addressable, tray and widget alike, as one list. The flyout is
    // three filtered views over it.
    readonly property var all: root.widgets.concat(SystemTray.items.values.map(i => ({
        id: root.idOf(i),
        // An em space holds the glyph column open for the icon the row draws
        // there instead.
        glyph: " ",
        // Tooltips are free-form and often several lines. One line fits a row.
        label: (i.tooltipTitle || i.title || i.id).split("\n")[0],
        item: i
    })))

    // The two the rail reads.
    readonly property var railWidgets: root.widgets.filter(w => !w.fixed && root.state(w.id) === "pinned")
    readonly property var railTray: SystemTray.items.values.filter(i => root.state(root.idOf(i)) === "pinned")

    // The StatusNotifierItem Id — the app picks it and it is the same string
    // next launch. tooltipTitle is not: it carries unread counts and sync state,
    // so a pin keyed on it silently detaches.
    function idOf(item) {
        return "tray:" + (item.id || item.title);
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
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.pinned = d.pinned ?? [];
                root.hidden = d.hidden ?? [];
            } catch (e) {}
        }
        // First run keeps the rail as it is today — every widget pinned, every
        // tray icon behind the chevron — and he prunes from there.
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.pinned = root.widgets.map(w => w.id);
                Qt.callLater(() => store.setText(JSON.stringify({ pinned: root.pinned, hidden: [] })));
            }
        }
    }
}
