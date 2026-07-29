pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// Popups leave on their own. History does not — an entry stays until you
// dismiss it, and "save" moves it to a list that survives a restart.
//
// The one trick worth knowing: an expired notification that still has actions
// keeps its D-Bus id alive here, so Reply still works hours later. Every other
// Linux daemon closes it immediately and the actions die with it.
Singleton {
    id: root

    property list<var> popups: []
    property list<var> history: []
    property list<var> saved: []
    property bool dnd: false

    readonly property int unread: history.filter(n => !n.seen).length

    // Live server objects, kept out of the models — putting a Notification in a
    // ListModel role crashes once the server destroys it.
    property var live: ({})

    function snapshot(n) {
        return {
            key: String(n.id) + ":" + Date.now(),
            id: n.id,
            app: n.appName || "unknown",
            summary: n.summary || "",
            body: n.body || "",
            urgency: n.urgency === NotificationUrgency.Critical ? "critical"
                   : n.urgency === NotificationUrgency.Low ? "low" : "normal",
            actions: n.actions.map(a => ({ id: a.identifier, label: a.text })),
            time: Qt.formatDateTime(new Date(), "HH:mm"),
            date: Qt.formatDateTime(new Date(), "yyyy-MM-dd"),
            seen: false
        };
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

            root.history = [s].concat(root.history).slice(0, 200);
            if (!root.dnd || s.urgency === "critical")
                root.popups = [s].concat(root.popups).slice(0, 4);

            // Hold the D-Bus close back while the notification has actions, so
            // it stays answerable from history after the popup is gone.
            n.closed.connect(() => {
                delete root.live[s.key];
            });
        }
    }
}
