pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Quickshell has no module for any of this. CPU, memory and temperature come
// from /proc and /sys; GPU, fan and swap reuse the scripts already driving the
// waybar config, so there is one implementation of each, not two.
Singleton {
    id: root

    property int cpu: 0
    property int mem: 0
    property int swap: 0
    property int temp: 0
    property int fan: 0
    property int gpu: 0
    property int vram: 0
    property int disk: 0
    property string net: ""
    property int brightness: -1        // -1 means no backlight on this machine

    property real memUsedGb: 0
    property real memTotalGb: 0
    property real diskUsedGb: 0
    property real diskTotalGb: 0

    // Recent history for the graphs in the monitor panel.
    property var cpuHistory: []
    property var memHistory: []

    property int lastIdle: 0
    property int lastTotal: 0

    FileView { id: stat; path: "/proc/stat" }
    FileView { id: meminfo; path: "/proc/meminfo" }

    function kb(text, key) {
        const m = text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m"));
        return m ? parseInt(m[1]) : 0;
    }

    // The waybar scripts print human strings; take the first number out.
    function firstNum(s) {
        const m = String(s).match(/(\d+(?:\.\d+)?)/);
        return m ? parseFloat(m[1]) : 0;
    }

    function push(arr, v) {
        const a = arr.slice(-59);
        a.push(v);
        return a;
    }

    Process {
        id: sensors
        command: ["sh", "-c", "cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | sort -rn | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = parseInt(text);
                if (!isNaN(t))
                    root.temp = Math.round(t / 1000);
            }
        }
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df -B1 --output=used,size / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/).map(Number);
                if (p.length >= 2 && p[1] > 0) {
                    root.diskUsedGb = p[0] / 1073741824;
                    root.diskTotalGb = p[1] / 1073741824;
                    root.disk = Math.round(100 * p[0] / p[1]);
                }
            }
        }
    }

    Process {
        id: brightProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %"]
        stdout: StdioCollector {
            onStreamFinished: {
                const b = parseInt(text);
                root.brightness = isNaN(b) ? -1 : b;
            }
        }
    }

    Process { id: setBright }

    function setBrightness(pct) {
        setBright.command = ["brightnessctl", "set", Math.round(pct * 100) + "%"];
        setBright.running = true;
        root.brightness = Math.round(pct * 100);
    }

    Process {
        id: gpuProc

        command: ["sh", "-c", "$HOME/.local/bin/gpu-util.sh 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.gpu = root.firstNum(text)
        }
    }

    Process {
        id: fanProc
        command: ["sh", "-c", "fw-fanctrl --output-format JSON print speed 2>/dev/null | jq -r .speed"]
        stdout: StdioCollector {
            onStreamFinished: root.fan = root.firstNum(text)
        }
    }

    Process {
        id: netProc
        command: ["sh", "-c", "$HOME/.local/bin/network-status.sh 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.net = JSON.parse(text).text.replace(/^\s*\S*\s*/, "").trim() || "net";
                } catch (e) {
                    root.net = "";
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            sensors.running = true;
            diskProc.running = true;
            gpuProc.running = true;
            brightProc.running = true;
            fanProc.running = true;
            netProc.running = true;

            // cpu% is the change in non-idle jiffies over the change in total.
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
            const mTotal = kb(mi, "MemTotal");
            const mAvail = kb(mi, "MemAvailable");
            if (mTotal > 0) {
                root.memTotalGb = mTotal / 1048576;
                root.memUsedGb = (mTotal - mAvail) / 1048576;
                root.mem = Math.round(100 * (1 - mAvail / mTotal));
            }
            const sTotal = kb(mi, "SwapTotal");
            const sFree = kb(mi, "SwapFree");
            if (sTotal > 0)
                root.swap = Math.round(100 * (1 - sFree / sTotal));

            root.cpuHistory = push(root.cpuHistory, root.cpu);
            root.memHistory = push(root.memHistory, root.mem);
        }
    }
}
