pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Quickshell has no module for any of this. CPU, memory, swap, temperature,
// network throughput and swap churn come from /proc and /sys; GPU and the
// network label reuse the scripts already driving the waybar config, so there
// is one implementation of each, not two. Nothing here decides what to show —
// that is Caps, whose answers are re-exported so a widget needs one import.
Singleton {
    id: root

    readonly property bool hasGpu: Caps.hasGpu
    readonly property bool hasFan: Caps.hasFan
    readonly property bool hasTemp: Caps.hasTemp
    readonly property bool hasBattery: Caps.hasBattery
    readonly property bool hasBacklight: Caps.hasBacklight
    readonly property bool hasSwap: Caps.hasSwap
    readonly property bool hasNet: Caps.hasNet
    readonly property bool hasCores: Caps.hasCores

    property int cpu: 0
    property var cores: []
    property int mem: 0
    property int swap: 0
    property int temp: 0
    property int fan: 0                 // rpm, or percent under fw-fanctrl
    property int gpu: 0
    property int vram: 0
    property int battery: 0
    property int brightness: -1
    property string net: ""

    property real memUsedGb: 0
    property real memTotalGb: 0
    property real vramUsedGb: 0
    property real vramTotalGb: 0
    property real netDown: 0            // bytes/sec
    property real netUp: 0
    property real swapIn: 0             // bytes/sec
    property real swapOut: 0
    property var disks: []              // [{ path, pct, usedGb, sizeGb }]

    // Sixty samples of every metric, keyed by name. The panel graphs them all
    // the same way, so one object beats a property per metric.
    property var history: ({})

    function record(samples) {
        const h = {};
        for (const k in root.history)
            h[k] = root.history[k];
        for (const k in samples)
            h[k] = (h[k] || []).slice(-59).concat(samples[k]);
        root.history = h;
    }

    function human(bytes) {
        const u = ["B", "K", "M", "G"];
        let v = bytes, i = 0;
        while (v >= 1024 && i < 3) {
            v /= 1024;
            i++;
        }
        return (i > 0 && v < 10 ? v.toFixed(1) : Math.round(v)) + u[i];
    }

    function kb(text, key) {
        const m = text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m"));
        return m ? parseInt(m[1]) : 0;
    }

    // The waybar scripts print human strings; take the numbers out.
    function nums(s) {
        return (String(s).match(/\d+(?:\.\d+)?/g) || []).map(Number);
    }

    // --- /proc, and the deltas that make it mean something ------------------
    property var prevCpu: ({})
    property var prevNet: ({ t: 0, rx: 0, tx: 0 })
    property var prevSwap: ({ t: 0, i: 0, o: 0 })

    FileView { id: stat; path: "/proc/stat" }
    FileView { id: meminfo; path: "/proc/meminfo" }
    FileView { id: netdev; path: "/proc/net/dev" }
    FileView { id: vmstat; path: "/proc/vmstat" }

    // Busy is the change in non-idle jiffies over the change in total, per line.
    function readCpu(text) {
        const cores = [];
        for (const line of text.split("\n")) {
            if (!line.startsWith("cpu"))
                break;
            const f = line.split(/\s+/);
            const n = f.slice(1).map(Number);
            if (n.length < 5)
                continue;
            const total = n.reduce((a, b) => a + b, 0);
            const p = root.prevCpu[f[0]];
            const pct = p && total > p.total ? Math.round(100 * (1 - (n[3] - p.idle) / (total - p.total))) : 0;
            root.prevCpu[f[0]] = { total: total, idle: n[3] };
            if (f[0] === "cpu")
                root.cpu = pct;
            else
                cores.push(pct);
        }
        root.cores = cores;
    }

    // Only interfaces with real hardware behind them, so a VPN tunnel riding on
    // the NIC is not counted twice.
    function readNet(text) {
        let rx = 0, tx = 0;
        for (const line of text.split("\n")) {
            const i = line.indexOf(":");
            if (i < 0 || Caps.nics.indexOf(line.slice(0, i).trim()) < 0)
                continue;
            const f = line.slice(i + 1).trim().split(/\s+/).map(Number);
            rx += f[0];
            tx += f[8];
        }
        const t = Date.now() / 1000, p = root.prevNet;
        if (p.t > 0 && t > p.t) {
            root.netDown = Math.max(0, (rx - p.rx) / (t - p.t));
            root.netUp = Math.max(0, (tx - p.tx) / (t - p.t));
        }
        root.prevNet = { t: t, rx: rx, tx: tx };
    }

    // pswpin/pswpout are cumulative page counts; the delta is the churn.
    function readSwapIo(text) {
        const i = root.nums((text.match(/^pswpin \d+$/m) || [""])[0])[0];
        const o = root.nums((text.match(/^pswpout \d+$/m) || [""])[0])[0];
        const t = Date.now() / 1000, p = root.prevSwap;
        if (i === undefined || o === undefined)
            return;
        if (p.t > 0 && t > p.t) {
            root.swapIn = Math.max(0, 4096 * (i - p.i) / (t - p.t));
            root.swapOut = Math.max(0, 4096 * (o - p.o) / (t - p.t));
        }
        root.prevSwap = { t: t, i: i, o: o };
    }

    // --- shelled-out readings, grouped so each tick forks as little as it can
    Process {
        id: sensorProc
        // The CPU package sensor by name, not whichever hwmon happens to be
        // hottest — under load that would silently become the GPU.
        command: ["sh", "-c", 'for h in /sys/class/hwmon/hwmon*; do case "$(cat $h/name 2>/dev/null)" in k10temp|coretemp|zenpower) t=$(cat $h/temp1_input); break;; esac; done\n'
            + '[ -n "$t" ] || t=$(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | sort -rn | head -1)\n'
            + 'echo "$t"\n' + root.fanCmd]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                if (Caps.hasTemp)
                    root.temp = Math.round((parseInt(l[0]) || 0) / 1000);
                if (Caps.hasFan)
                    root.fan = parseInt(l[1]) || 0;
            }
        }
    }

    readonly property string fanCmd: Caps.fanSource === "fw"
        ? "fw-fanctrl --output-format JSON print speed 2>/dev/null | jq -r .speed"
        : "cat /sys/class/hwmon/hwmon*/fan1_input 2>/dev/null | sort -rn | head -1"

    Process {
        id: gpuProc
        command: ["sh", "-c", "$HOME/.local/bin/gpu-util.sh 2>/dev/null; $HOME/.local/bin/gpu-vram.sh 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                // util%, vram used GB, vram total GB — in that order.
                const n = root.nums(text);
                root.gpu = n[0] || 0;
                if (n.length >= 3 && n[2] > 0) {
                    root.vramUsedGb = n[1];
                    root.vramTotalGb = n[2];
                    root.vram = Math.round(100 * n[1] / n[2]);
                }
            }
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

    Process {
        id: powerProc
        command: ["sh", "-c", 'cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1\n'
            + 'brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %']
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                root.battery = parseInt(l[0]) || 0;
                root.brightness = Caps.hasBacklight ? parseInt(l[1]) || 0 : -1;
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
        id: dfProc
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [], h = {};
                for (const line of text.trim().split("\n")) {
                    const f = line.trim().split(/\s+/);
                    if (f.length < 3 || !(Number(f[2]) > 0))
                        continue;
                    const pct = Math.round(100 * f[1] / f[2]);
                    // Decimal GB, the unit df and the old waybar config used.
                    out.push({ path: f[0], pct: pct, usedGb: f[1] / 1e9, sizeGb: f[2] / 1e9 });
                    h["disk:" + f[0]] = pct;
                }
                root.disks = out;
                root.record(h);
            }
        }
    }

    function readDisks() {
        if (Caps.disks.length === 0) {
            root.disks = [];
            return;
        }
        dfProc.command = ["sh", "-c", "df -B1 --output=target,used,size " + Caps.disks.map(p => "'" + p + "'").join(" ") + " 2>/dev/null | tail -n +2"];
        dfProc.running = true;
    }

    // --- polling ------------------------------------------------------------
    Timer {
        interval: 2000
        running: Caps.probed
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            netdev.reload();
            vmstat.reload();
            sensorProc.running = Caps.hasTemp || Caps.hasFan;
            gpuProc.running = Caps.hasGpu;
            netProc.running = Caps.hasNet;
            powerProc.running = Caps.hasBattery || Caps.hasBacklight;

            root.readCpu(stat.text());
            root.readNet(netdev.text());
            root.readSwapIo(vmstat.text());

            const mi = meminfo.text();
            const mTotal = kb(mi, "MemTotal");
            if (mTotal > 0) {
                root.memTotalGb = mTotal / 1048576;
                root.memUsedGb = (mTotal - kb(mi, "MemAvailable")) / 1048576;
                root.mem = Math.round(100 * root.memUsedGb / root.memTotalGb);
            }
            const sTotal = kb(mi, "SwapTotal");
            if (sTotal > 0)
                root.swap = Math.round(100 * (1 - kb(mi, "SwapFree") / sTotal));

            root.record({ cpu: root.cpu, mem: root.mem, swap: root.swap,
                swapIn: root.swapIn, swapOut: root.swapOut, temp: root.temp,
                fan: root.fan, gpu: root.gpu, vram: root.vram,
                battery: root.battery, netDown: root.netDown, netUp: root.netUp });
        }
    }

    // Disks move slowly and df is a syscall storm; once every half minute is
    // plenty — unless the set of mounts to watch just changed under us.
    Timer {
        interval: 30000
        running: Caps.probed
        repeat: true
        triggeredOnStart: true
        onTriggered: root.readDisks()
    }

    Connections {
        target: Caps
        function onDisksChanged() { root.readDisks(); }
    }
}
