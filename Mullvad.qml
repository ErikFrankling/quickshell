pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Mullvad, as much of it as a panel row needs: is it up, where does it come
// out, and the two commands that change that. Logging in is the dotfiles' job
// (modules/nixos/mullvad.nix) and the full relay list is the desktop app's.
//
// Nothing here polls. The state is read when one of our own commands finishes
// and when Net sees a tunnel come or go, which is what a connect made from the
// CLI or the app looks like from here.
Singleton {
    id: root

    // False until the daemon has answered once, so a machine without Mullvad
    // draws no rows for it.
    property bool present: false
    property bool connected: false
    property string country: ""
    property string city: ""
    readonly property bool busy: act.running

    function refresh() {
        status.running = true;
    }

    // `code` is a country the way `mullvad relay set location` spells it, or
    // nothing to come back out wherever it last did. `--wait` holds the
    // process open until the tunnel is up, which is what makes `busy` true for
    // exactly as long as the row should say so; the timeout is for a daemon
    // that is logged out and will never get there.
    function connect(code) {
        root.run((code ? "mullvad relay set location " + code + " && " : "")
            + "timeout 20 mullvad connect --wait");
    }

    function disconnect() {
        root.run("timeout 20 mullvad disconnect --wait");
    }

    function run(sh) {
        act.command = ["sh", "-c", sh];
        act.running = true;
    }

    Process {
        id: act
        onExited: root.refresh()
    }

    Process {
        id: status
        command: ["mullvad", "status", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let s;
                try {
                    s = JSON.parse(text);
                } catch (e) {
                    return;
                }
                root.present = true;
                root.connected = s.state === "connected";
                root.country = s.details?.location?.country ?? "";
                root.city = s.details?.location?.city ?? "";
            }
        }
    }

    Connections {
        target: Net
        function onTunnelsChanged() { root.refresh(); }
    }

    Component.onCompleted: root.refresh()
}
