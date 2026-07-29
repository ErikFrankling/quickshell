pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    // Everything that has arrived and not been cleared. Newest first.
    property list<var> list: []

    readonly property int count: list.length

    function clear() {
        root.list = [];
    }

    NotificationServer {
        // These are all off by default, which is the usual reason actions or
        // images silently don't work.
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true

        onNotification: n => {
            n.tracked = true;
            root.list = [
                {
                    id: n.id,
                    app: n.appName || "",
                    summary: n.summary || "",
                    body: n.body || "",
                    time: Qt.formatDateTime(new Date(), "HH:mm")
                }
            ].concat(root.list).slice(0, 50);
        }
    }
}
