pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick

// Which rail items sit on the rail and which live behind the chevron.
//
// Three states, not two: pinned (on the rail), overflow (in the flyout) and
// hidden (nowhere). Overflow is the default, so a tray icon that appears
// mid-session never shoves the rail around — Windows 11 starts new icons at
// IsPromoted=0 and Plasma's shownItems/hiddenItems work the same way.
Singleton {
    id: root

    property list<string> pinned: []
    property list<string> hidden: []

    // The rail's own widgets, addressed by name and never by position: a
    // widget's index changes the moment another one moves to the flyout.
    readonly property var widgets: [
        { id: "launcher", glyph: "󰀻", label: "Launcher" },
        { id: "looks", glyph: "󰸉", label: "Looks" },
        { id: "workspaces", glyph: "󰕰", label: "Workspaces" },
        { id: "metrics", glyph: "󰄨", label: "Metrics" },
        { id: "monitor", glyph: "󰍹", label: "Monitor" },
        { id: "audio", glyph: "󰕾", label: "Audio" },
        { id: "network", glyph: "󰤨", label: "Network" },
        { id: "bluetooth", glyph: "󰂯", label: "Bluetooth" },
        { id: "player", glyph: "󰝚", label: "Media" },
        { id: "notifs", glyph: "󰂚", label: "Notifications" },
        { id: "clock", glyph: "󰥔", label: "Clock" }
    ]

    // Everything addressable, tray and widget alike, as one model. Two filtered
    // views over this is all the rail and the flyout ever need.
    readonly property var all: root.widgets.concat(SystemTray.items.values.map(i => ({
        id: root.idOf(i),
        glyph: "",
        // Tooltips are free-form and often several lines. One line fits a row.
        label: (i.tooltipTitle || i.title || i.id).split("\n")[0],
        item: i
    })))

    // A tray item's id is the StatusNotifierItem Id — the app picks it and it is
    // the same string next launch. tooltipTitle is not: it carries unread counts
    // and sync state, so a pin keyed on it silently detaches. Two apps get the
    // Id wrong and Plasma special-cases both in systemtraymodel.cpp: Dropbox
    // appends its pid, and every Chromium/Electron app calls itself
    // chrome_status_icon_N in launch order.
    function idOf(item) {
        const raw = item.id ?? "";
        if (raw.startsWith("dropbox-client-"))
            return "tray:dropbox";
        if (raw.startsWith("chrome_status_icon"))
            return "tray:" + raw + "@" + (item.title || item.tooltipTitle);
        return "tray:" + raw;
    }

    function state(id) {
        return root.hidden.includes(id) ? "hidden"
            : root.pinned.includes(id) ? "pinned" : "overflow";
    }

    function isPinned(id) {
        return root.pinned.includes(id);
    }

    // Copy and reassign, never push: mutating a list in place does not notify,
    // so every binding reading it goes stale. This is the bug in this space.
    function pin(id) {
        root.hidden = root.hidden.filter(x => x !== id);
        if (!root.pinned.includes(id))
            root.pinned = root.pinned.concat([id]);
        root.save();
    }

    function unpin(id) {
        root.pinned = root.pinned.filter(x => x !== id);
        root.save();
    }

    function toggle(id) {
        if (root.isPinned(id))
            root.unpin(id);
        else
            root.pin(id);
    }

    function conceal(id) {
        root.pinned = root.pinned.filter(x => x !== id);
        if (!root.hidden.includes(id))
            root.hidden = root.hidden.concat([id]);
        root.save();
    }

    function reveal(id) {
        root.hidden = root.hidden.filter(x => x !== id);
        root.save();
    }

    function save() {
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
        // tray icon in the flyout — and the user prunes from there.
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.pinned = root.widgets.map(w => w.id);
                Qt.callLater(root.save);
            }
        }
    }
}
