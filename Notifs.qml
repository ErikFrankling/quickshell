pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// Popups leave on their own. History does not — an entry stays until you
// dismiss it, and "save" moves it to a second list.
//
// Both lists are on disk, and they are on disk for different reasons. History
// is there so the panel is not empty after a reboot, and it is capped: 100
// entries or seven days, whichever bites first, which is what noctalia
// (Services/System/NotificationService.qml:22 maxHistory, :603) and vast-shell
// (Qml/Services/Notifs.qml:22-23, a 100/7-day pair) both landed on. Saved is
// there because a saved notification is a to-do, so nothing above ever prunes
// it — it goes when you un-save it and not before.
//
// The one trick worth knowing: an expired notification that still has actions
// keeps its D-Bus id alive here, so Reply still works hours later. Every other
// Linux daemon closes it immediately and the actions die with it. That trick
// ends at the process boundary — see load().
Singleton {
    id: root

    property list<var> popups: []
    property list<var> history: []
    property list<var> saved: []

    // Whichever bites first. 100 cards is far more than anyone scrolls, and a
    // week is how long a notification is still about something happening.
    readonly property int keep: 100
    readonly property int keepMs: 7 * 24 * 60 * 60 * 1000

    // Unread survives a restart, because "seen" is a fact about the entry and
    // is written out with it. Nothing else can be honest: everything-is-read
    // throws away the one thing the badge is for, and everything-is-unread
    // makes it a count of how recently the shell restarted. The age cap is what
    // keeps it from becoming noise — the badge cannot report last month.
    readonly property int unread: history.filter(n => !n.seen).length

    // Live server objects, kept out of the models — putting a Notification in a
    // ListModel role crashes once the server destroys it.
    property var live: ({})

    // One string in, one url out, "" for "draw nothing".
    //
    // The empty answer is the whole point. Only `hicolor` is installed here, so
    // most theme names miss, and a miss must draw nothing: iconPath with one
    // argument answers every name, with the provider's magenta-and-green
    // placeholder for the ones it cannot find, which is the checkerboard the
    // tray menu already had to work around (TrayMenu.qml:85-96). The second
    // argument is the check-exists flag and returns "" instead — measured on
    // this machine, not assumed: iconPath("spotify", true) is "" while
    // iconPath("spotify-client", true) is "image://icon/spotify-client".
    function icon(name) {
        if (!name)
            return "";
        // Unwrapped first. This libnotify no longer puts --icon in the
        // app_icon field at all — it sends it as the image-path hint — and
        // Quickshell hands that back already wrapped as "image://icon/<hint>",
        // whatever the hint was. So an unchecked name arrives looking like a
        // resolved url, and the name has to come back out to be checked.
        const prefix = "image://icon/";
        const bare = name.startsWith(prefix) ? name.slice(prefix.length) : name;
        // A file, or inline image data, is its own answer: neither can be
        // checked here, and the card asks Image instead.
        if (bare.startsWith("/"))
            return "file://" + bare;
        if (bare.includes("://"))
            return bare;
        return Quickshell.iconPath(bare, true);
    }

    // The sending application's logo, resolved once, on arrival.
    //
    // appIcon first because it is the app saying who it is — and Quickshell has
    // already done the desktop-entry lookup behind it, which is worth knowing:
    // a notification carrying only `desktop-entry=spotify` arrives here with
    // appIcon "spotify-client", because nothing called "spotify" is installed
    // and spotify.desktop's `Icon=` line is what connects the two. The explicit
    // entry lookup below is still not redundant; it covers an app that names an
    // icon of its own that nobody has installed.
    //
    // `image` is last because it is the content hint — album art, an avatar —
    // and Erik asked for the application's logo, so a track change should show
    // the Spotify mark and not the sleeve. It is in the chain at all because
    // this libnotify's --icon lands there, which makes it the only thing a
    // plain `notify-send --icon=firefox` sets.
    function iconFor(n) {
        const entry = n.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : null;
        return root.icon(n.appIcon)
            || root.icon(entry ? entry.icon : "")
            || root.icon((n.appName || "").toLowerCase())
            || root.icon(n.image);
    }

    function snapshot(n) {
        return {
            key: String(n.id) + ":" + Date.now(),
            id: n.id,
            app: n.appName || "unknown",
            summary: n.summary || "",
            body: n.body || "",
            icon: root.iconFor(n),
            // Milliseconds the sender asked to be left up. -1 is "the server
            // decides" and is what notify-send sends unless given -t; 0 is
            // "never expire". Both were being thrown away — see shell.qml.
            timeout: n.expireTimeout,
            urgency: n.urgency === NotificationUrgency.Critical ? "critical"
                   : n.urgency === NotificationUrgency.Low ? "low" : "normal",
            actions: n.actions.map(a => ({ id: a.identifier, label: a.text })),
            time: Qt.formatDateTime(new Date(), "HH:mm"),
            date: Qt.formatDateTime(new Date(), "yyyy-MM-dd"),
            ts: Date.now(),
            seen: false
        };
    }

    // Both caps, in the order that keeps the newest: the list is newest-first.
    function prune(list) {
        const cutoff = Date.now() - root.keepMs;
        return list.filter(n => (n.ts ?? 0) > cutoff).slice(0, root.keep);
    }

    function isSaved(key) {
        return root.saved.some(x => x.key === key);
    }

    function dismissPopup(key) {
        root.popups = root.popups.filter(n => n.key !== key);
    }

    function drop(key) {
        root.history = root.history.filter(n => n.key !== key);
        root.popups = root.popups.filter(n => n.key !== key);
        const l = root.live[key];
        if (l) {
            l.dismiss();
            delete root.live[key];
        }
    }

    function save(key) {
        const n = root.history.find(x => x.key === key);
        if (n && !root.saved.some(x => x.key === key)) {
            root.saved = [n].concat(root.saved);
            store.setText(JSON.stringify(root.saved));
        }
    }

    function unsave(key) {
        root.saved = root.saved.filter(x => x.key !== key);
        store.setText(JSON.stringify(root.saved));
    }

    function invoke(key, actionId) {
        const l = root.live[key];
        if (l)
            l.actions.find(a => a.identifier === actionId)?.invoke();
    }

    function markSeen() {
        root.history = root.history.map(n => Object.assign({}, n, { seen: true }));
    }

    function clearHistory() {
        for (const n of root.history)
            root.live[n.key]?.dismiss();
        root.live = ({});
        root.history = [];
        root.popups = [];
    }

    // A reloaded entry is a corpse: its D-Bus id died with the last process, so
    // its actions cannot be invoked. Those have to go, or the card offers
    // buttons that quietly do nothing.
    //
    // The icon is the same question asked of a string. A themed one is an
    // "image://icon/<name>" url that resolves against the installed themes
    // every time it is drawn, so it is as good tomorrow as it was today; a
    // path is whatever the sender had lying around when it fired, usually
    // under /tmp, and by now it is very likely gone. So the themed ones are
    // kept and the paths are dropped, which is what vast-shell does with
    // ephemeral urls on load for the same reason
    // (Qml/Services/Notifs.qml:193-196).
    //
    // Anything that arrived before the file came back is kept in front of it.
    function load(text) {
        const old = JSON.parse(text).map(n => Object.assign({}, n, {
            actions: [],
            icon: (n.icon || "").startsWith("image://icon/") ? n.icon : ""
        }));
        root.history = root.prune(root.history.concat(old));
    }

    // One write a second at most, and only after the load, so a notification
    // arriving during startup cannot truncate the file. noctalia debounces the
    // same write at 200ms, vast-shell at 2s.
    Timer {
        id: writeTimer
        interval: 1000
        onTriggered: histStore.setText(JSON.stringify(root.prune(root.history)))
    }

    property bool ready: false
    onHistoryChanged: if (root.ready) writeTimer.restart()

    FileView {
        id: histStore
        path: Quickshell.statePath("history.json")
        atomicWrites: true
        // No file yet is a first run, not an error.
        printErrors: false
        onLoaded: {
            try {
                root.load(text());
            } catch (e) {}
            root.ready = true;
            writeTimer.restart();
        }
        onLoadFailed: err => {
            root.ready = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => histStore.setText("[]"));
        }
    }

    // Saved notifications outlive the shell, so they live in state, not cache.
    FileView {
        id: store
        path: Quickshell.statePath("saved.json")
        atomicWrites: true
        onLoaded: {
            try {
                root.saved = JSON.parse(text());
            } catch (e) {}
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => store.setText("[]"));
        }
    }

    NotificationServer {
        id: server

        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        persistenceSupported: true
        inlineReplySupported: true
        keepOnReload: false

        onNotification: n => {
            n.tracked = true;
            const s = root.snapshot(n);
            root.live[s.key] = n;

            root.history = root.prune([s].concat(root.history));
            root.popups = [s].concat(root.popups).slice(0, 4);

            // Hold the D-Bus close back while the notification has actions, so
            // it stays answerable from history after the popup is gone.
            n.closed.connect(() => {
                delete root.live[s.key];
            });
        }
    }
}
