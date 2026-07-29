pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Quickshell has no module for any of this, so read /proc directly.
Singleton {
    id: root

    property int cpu: 0
    property int mem: 0
    property int temp: 0

    property int lastIdle: 0
    property int lastTotal: 0

    FileView {
        id: stat
        path: "/proc/stat"
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
    }
    FileView {
        id: thermal
        path: "/sys/class/thermal/thermal_zone0/temp"
    }

    function num(text, key) {
        const m = text.match(new RegExp(key + ":\\s+(\\d+)"));
        return m ? parseInt(m[1]) : 0;
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            thermal.reload();

            // First line of /proc/stat is aggregate jiffies; cpu% is the
            // change in non-idle over the change in total since last tick.
            const f = stat.text().split("\n")[0].split(/\s+/).slice(1).map(Number);
            if (f.length > 4) {
                const total = f.reduce((a, b) => a + b, 0);
                const idle = f[3];
                const dt = total - root.lastTotal;
                if (dt > 0 && root.lastTotal > 0)
                    root.cpu = Math.round(100 * (1 - (idle - root.lastIdle) / dt));
                root.lastTotal = total;
                root.lastIdle = idle;
            }

            const mi = meminfo.text();
            const totalKb = num(mi, "MemTotal");
            const availKb = num(mi, "MemAvailable");
            if (totalKb > 0)
                root.mem = Math.round(100 * (1 - availKb / totalKb));

            const t = parseInt(thermal.text());
            if (!isNaN(t))
                root.temp = Math.round(t / 1000);
        }
    }
}
