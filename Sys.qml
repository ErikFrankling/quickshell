pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Quickshell has no module for any of this. CPU, memory, swap, temperature,
// the fan, the GPU and the two throughputs all come from /proc and /sys, read
// as files. Nothing here decides what to show — that is Caps, whose answers are
// re-exported so a widget needs one import.
Singleton {
    id: root

    readonly property bool hasGpu: Caps.hasGpu
    readonly property bool hasFan: Caps.hasFan
    readonly property bool hasTemp: Caps.hasTemp
    readonly property bool hasBattery: Caps.hasBattery
    readonly property bool hasBacklight: Caps.hasBacklight
    readonly property bool hasSwap: Caps.hasSwap
    readonly property bool hasNet: Caps.hasNet
    readonly property bool hasDiskIo: Caps.hasDiskIo
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
    property bool charging: true
    property int brightness: -1

    property real memUsedGb: 0
    property real memTotalGb: 0
    property real vramUsedGb: 0
    property real vramTotalGb: 0
    property real netDown: 0            // bytes/sec
    property real netUp: 0
    property real swapIn: 0             // bytes/sec
    property real swapOut: 0
    property real diskRead: 0           // bytes/sec
    property real diskWrite: 0
    property var disks: []              // [{ path, pct, usedGb, sizeGb }]

    // How often each thing is asked. Not one rate, and the thing that separates
    // them is not how fast the number moves — it is what asking costs. Timed on
    // this machine: the shell pipeline that used to fetch the temperature and
    // the fan cost 16.5 ms of CPU every time it ran, and the two sysfs files it
    // read cost 0.02 ms — eight hundred times less. So everything that is a
    // file read is on the half second, and everything that still has to start a
    // process stays on the two seconds it was already on. Raising the rate at
    // all is what moving those two readings off `sh` bought.
    //
    // The GPU joined them on the same arithmetic. Timed here the same way: the
    // fork it used to take cost 2.56 ms a call, and the three files that replace
    // it cost 33 µs, 18 µs and 19 µs — 0.07 ms for the lot, which is barely more
    // than the single read of /proc/stat that is already on this tier at 63 µs.
    // A metric that costs one thirty-sixth of what it did can be asked four
    // times as often for less than it used to cost once.
    //
    // Half a second because that is what he asked for: he wants to watch the
    // fan answer a temperature rise, and at two seconds the ring reached a step
    // 0.94 s late on average and 1.84 s late at worst. Ricelin's dials run
    // their /proc and hwmon reads at exactly this rate and say why —
    // "so a slow source never stalls the dials" (Sysmon.qml:9-13) — and
    // noctalia runs CPU at one second ungated (SystemStatService.qml:340).
    readonly property int pollMs: 500
    readonly property int procMs: 2000
    readonly property int diskMs: 30000

    // Still two minutes, and still one window for every graph in the panel:
    // four times as many samples at a quarter of the spacing. The panel prints
    // this on screen, reading it from here, so the label cannot drift away from
    // the thing it describes — which is exactly what raising the rate without
    // raising the count would have done to it.
    readonly property int samples: 240
    readonly property int historySec: samples * pollMs / 1000

    // History, keyed by metric name. The panel graphs them all the same way, so
    // one object beats a property per metric. Only what actually moves inside
    // the window is recorded — a two-minute history of a disk that is 97% full
    // is a flat line, and a flat line is not worth drawing.
    property var history: ({})

    function record(vals) {
        const h = {};
        for (const k in root.history)
            h[k] = root.history[k];
        for (const k in vals)
            h[k] = (h[k] || []).slice(1 - root.samples).concat(vals[k]);
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

    // Every number in a line of text, for the /proc lines that are one.
    function nums(s) {
        return (String(s).match(/\d+(?:\.\d+)?/g) || []).map(Number);
    }

    // --- /proc, and the deltas that make it mean something ------------------
    property var prevCpu: ({})
    property var prevNet: ({ t: 0, rx: 0, tx: 0 })
    property var prevSwap: ({ t: 0, i: 0, o: 0 })
    property var prevDisk: ({ t: 0, r: 0, w: 0 })

    // Parsed where the content arrives, not where it was asked for. reload() is
    // asynchronous — the read runs on a thread and text() keeps returning the
    // old contents until it lands (Quickshell's own fileview.hpp:261 says so) —
    // and the tick used to call reload() and text() on the next line, so every
    // number here was computed from the snapshot the *previous* tick fetched.
    // Measured before the change: 233 ticks out of 233 parsed content a mean of
    // 1.81 s old, while the fresh content landed 2.2 ms after being asked for.
    // That is where four of the five seconds between pinning the CPU and the
    // ring admitting it went.
    FileView { id: stat; path: "/proc/stat"; onLoaded: root.readCpu(text()) }
    FileView { id: meminfo; path: "/proc/meminfo"; onLoaded: root.readMem(text()) }
    FileView { id: netdev; path: "/proc/net/dev"; onLoaded: root.readNet(text()) }
    FileView { id: vmstat; path: "/proc/vmstat"; onLoaded: root.readSwapIo(text()) }
    FileView { id: diskstats; path: "/proc/diskstats"; onLoaded: root.readDiskIo(text()) }

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

    function readMem(text) {
        const mTotal = root.kb(text, "MemTotal");
        if (mTotal > 0) {
            root.memTotalGb = mTotal / 1048576;
            root.memUsedGb = (mTotal - root.kb(text, "MemAvailable")) / 1048576;
            root.mem = Math.round(100 * root.memUsedGb / root.memTotalGb);
        }
        const sTotal = root.kb(text, "SwapTotal");
        if (sTotal > 0)
            root.swap = Math.round(100 * (1 - root.kb(text, "SwapFree") / sTotal));
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

    // The throughput btop draws. Per Documentation/admin-guide/iostats.rst a
    // line is major, minor, name and then the eleven counters, of which the
    // third is sectors read and the seventh sectors written — whole-line fields
    // six and ten. The block layer reports those in 512-byte units whatever the
    // drive's own sector size is. Caps.blocks holds whole devices only, so a
    // partition is never added on top of the disk it lives on.
    function readDiskIo(text) {
        let rd = 0, wr = 0;
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            if (f.length < 10 || Caps.blocks.indexOf(f[2]) < 0)
                continue;
            rd += Number(f[5]);
            wr += Number(f[9]);
        }
        const t = Date.now() / 1000, p = root.prevDisk;
        if (p.t > 0 && t > p.t) {
            root.diskRead = Math.max(0, 512 * (rd - p.r) / (t - p.t));
            root.diskWrite = Math.max(0, 512 * (wr - p.w) / (t - p.t));
        }
        root.prevDisk = { t: t, r: rd, w: wr };
    }

    // --- the sensors, as files ----------------------------------------------
    //
    // Which files, worked out once. hwmon numbering is fixed for the life of a
    // boot, so the search that used to run on every single sample — a shell, a
    // loop, and a cat per hwmon directory — runs once at startup and leaves a
    // couple of paths behind. Everything after that is a read().
    property string tempPath: ""
    property var fanPaths: []

    Process {
        id: sensorProbe
        running: true
        // The CPU package sensor by name, not whichever hwmon happens to be
        // hottest — under load that would silently become the GPU. Where no
        // named sensor answers, the hottest is the fallback it always was, but
        // chosen now, once, rather than re-chosen every tick: picking it afresh
        // each time is what let the reading hop between chips in the first place.
        command: ["sh", "-c",
            'for h in /sys/class/hwmon/hwmon*; do case "$(cat $h/name 2>/dev/null)" in k10temp|coretemp|zenpower) echo "temp=$h/temp1_input"; break;; esac; done\n'
            + 'grep -H . /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | sort -t: -k2 -rn | head -1 | sed "s|^|hot=|; s|:.*||"\n'
            + 'echo "fans=$(ls /sys/class/hwmon/hwmon*/fan1_input 2>/dev/null | tr "\\n" " ")"']
        stdout: StdioCollector {
            onStreamFinished: {
                const v = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        v[line.slice(0, i)] = line.slice(i + 1).trim();
                }
                root.tempPath = v.temp || v.hot || "";
                root.fanPaths = (v.fans || "").split(/\s+/).filter(p => p.length > 0);
            }
        }
    }

    // Gated on the capability rather than on the file existing, so a host that
    // turns the metric off in metrics.json is not read anyway.
    FileView {
        id: tempFile
        path: Caps.hasTemp ? root.tempPath : ""
        printErrors: false
        onLoaded: root.temp = Math.round((parseInt(text()) || 0) / 1000)
    }

    // A machine can expose more than one fan and the ring shows the fastest of
    // them, which is what the old `sort -rn | head -1` did. One reader per file
    // says the same thing without the pipeline; under fw-fanctrl there are no
    // such files and the process below answers instead.
    property var fanRpm: []

    Instantiator {
        id: fanFiles
        model: Caps.hasFan ? root.fanPaths : []

        FileView {
            required property int index
            required property string modelData
            path: modelData
            printErrors: false
            onLoaded: {
                const v = root.fanRpm.slice();
                v[index] = parseInt(text()) || 0;
                root.fanRpm = v;
                root.fan = Math.max.apply(null, [0].concat(v.map(x => x || 0)));
            }
        }
    }

    // The GPU, from the driver rather than from a shell. These three files used
    // to be two scripts in ~/.local/bin that home-manager installed alongside
    // waybar, and unimporting the waybar module took them with it: the shell
    // went on forking `sh` at them twice a second, got nothing back, and drew a
    // ring reading 0% over a card that was busy. Nothing said so, which is the
    // whole argument for reading the kernel's own file — there is no layer left
    // between the number and the driver to go missing.
    //
    // amdgpu publishes gpu_busy_percent as a percentage already and the two
    // memory figures in bytes. Which card they belong to is Caps' answer, worked
    // out once at startup; empty means nothing here can be read and the ring is
    // not drawn at all.
    FileView {
        id: gpuFile
        path: Caps.hasGpu ? Caps.gpuPath + "/gpu_busy_percent" : ""
        printErrors: false
        onLoaded: root.gpu = parseInt(text()) || 0
    }

    // GiB, and printed as "GB" beside the memory reading that is also GiB — the
    // 7900 XT's 21458059264 bytes are the 20 GB written on the box.
    FileView {
        id: vramUsedFile
        path: Caps.hasGpu ? Caps.gpuPath + "/mem_info_vram_used" : ""
        printErrors: false
        onLoaded: {
            root.vramUsedGb = (parseInt(text()) || 0) / 1073741824;
            root.readVram();
        }
    }

    FileView {
        id: vramTotalFile
        path: Caps.hasGpu ? Caps.gpuPath + "/mem_info_vram_total" : ""
        printErrors: false
        onLoaded: {
            root.vramTotalGb = (parseInt(text()) || 0) / 1073741824;
            root.readVram();
        }
    }

    function readVram() {
        root.vram = root.vramTotalGb > 0
            ? Math.round(100 * root.vramUsedGb / root.vramTotalGb) : 0;
    }

    // --- readings that still have to fork ------------------------------------
    //
    // fw-fanctrl is a Python client talking to a daemon over a socket, so this
    // one cannot join the fast tier however much the fan ring would like it to:
    // it is the most expensive reading the shell takes, and it is taken on the
    // laptop, which is the machine whose battery is the reason to care. It
    // stays exactly where it was.
    Process {
        id: fwFanProc
        command: ["sh", "-c", "fw-fanctrl --output-format JSON print speed 2>/dev/null | jq -r .speed"]
        stdout: StdioCollector {
            onStreamFinished: root.fan = parseInt(text) || 0
        }
    }

    // Keyed rather than positional, the way Caps reads its probe: a host with no
    // battery prints nothing for the first two lines, and by position that
    // silently made the backlight the charge.
    Process {
        id: powerProc
        command: ["sh", "-c", 'printf "cap=%s\\n" "$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)"\n'
            + 'printf "st=%s\\n" "$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)"\n'
            + 'printf "bl=%s\\n" "$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %)"']
        stdout: StdioCollector {
            onStreamFinished: {
                const v = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        v[line.slice(0, i)] = line.slice(i + 1).trim();
                }
                root.battery = parseInt(v.cap) || 0;
                // Anything that is not actively draining counts as safe. "Not
                // charging" is what a laptop held at a charge limit reports, and
                // it is not a reason to shout.
                root.charging = v.st !== "Discharging";
                root.brightness = Caps.hasBacklight ? parseInt(v.bl) || 0 : -1;
                root.warnBattery();
            }
        }
    }

    Process { id: setBright }

    function setBrightness(pct) {
        setBright.command = ["brightnessctl", "set", Math.round(pct * 100) + "%"];
        setBright.running = true;
        root.brightness = Math.round(pct * 100);
    }

    // --- the warning that has to arrive when he is not looking ---------------
    //
    // His waybar's own thresholds (config.jsonc:50-53), so the ring lights where
    // it always did. A blinking ring is only worth anything to somebody facing
    // the screen, and the laptop that died was not being watched — so each of
    // the two crossings also raises a notification, and this shell is the thing
    // that will draw it.
    //
    // Once per crossing, never per poll: a watermark that only ever descends
    // while discharging and is thrown away the moment the charge climbs back
    // over the warning line or the mains come back. corecathx_whisker keeps the
    // same single int (services/Power.qml:18, 30-60) and noctalia the same rearm
    // (Services/Hardware/BatteryService.qml:287-323); a set of booleans, one per
    // level, is the same thing spelled longer.
    readonly property int batWarn: 30
    readonly property int batCrit: 15
    property int notifiedAt: 101

    function warnBattery() {
        // Zero is what an unread or absent battery reports, and 0% is not a
        // reading worth waking him for.
        if (!Caps.hasBattery || root.battery <= 0)
            return;
        if (root.charging || root.battery > root.batWarn) {
            root.notifiedAt = 101;
            return;
        }
        // Most severe first, so a long sleep that skipped both lines still says
        // the true thing rather than the first one it passed.
        for (const lvl of [root.batCrit, root.batWarn]) {
            if (root.battery > lvl || root.notifiedAt <= lvl)
                continue;
            root.notifiedAt = lvl;
            const crit = lvl === root.batCrit;
            Quickshell.execDetached(["notify-send", "-a", "erikshell",
                "-u", crit ? "critical" : "normal", "-i", "battery-caution",
                crit ? "Battery critical" : "Battery low",
                root.battery + "% left — plug in" + (crit ? " now" : " soon")]);
            return;
        }
    }

    Process {
        id: dfProc
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.trim().split("\n")) {
                    const f = line.trim().split(/\s+/);
                    if (f.length < 4 || !(Number(f[2]) > 0))
                        continue;
                    // Used over used-plus-available, rounded up — which is
                    // exactly what df prints as Use%, and the only figure that
                    // answers "how much more can I write". Over the raw size it
                    // is not: ext4 holds back 5% for root, so this machine's /
                    // reads 90% full by size and 95% by what is left of it,
                    // which is the difference between a warning and an
                    // emergency. Rounding df's way costs nothing and stops the
                    // ring and the terminal disagreeing by a point.
                    out.push({ path: f[0],
                        pct: Math.ceil(100 * f[1] / (Number(f[1]) + Number(f[3]))),
                        usedGb: f[1] / 1e9, sizeGb: f[2] / 1e9 });
                }
                root.disks = out;
            }
        }
    }

    function readDisks() {
        if (Caps.disks.length === 0) {
            root.disks = [];
            return;
        }
        dfProc.command = ["sh", "-c", "df -B1 --output=target,used,size,avail " + Caps.disks.map(p => "'" + p + "'").join(" ") + " 2>/dev/null | tail -n +2"];
        dfProc.running = true;
    }

    // --- polling ------------------------------------------------------------
    //
    // The fast tier: five files in /proc, the sensor files in /sys, and not one
    // process.
    Timer {
        interval: root.pollMs
        running: Caps.probed
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            netdev.reload();
            vmstat.reload();
            diskstats.reload();
            if (tempFile.path !== "")
                tempFile.reload();
            for (let i = 0; i < fanFiles.count; i++)
                fanFiles.objectAt(i).reload();
            if (gpuFile.path !== "") {
                gpuFile.reload();
                vramUsedFile.reload();
                vramTotalFile.reload();
            }
            sample.restart();
        }
    }

    // The sample that the graphs draw, taken a moment after the tick rather
    // than inside it. Every read above lands on a worker thread a millisecond
    // or two later, so a sample taken in the tick itself is a sample of what
    // the *last* tick found — which is precisely why the temperature ring and
    // the temperature graph beside it never agreed. Measured on the old code, a
    // step in the CPU temperature reached the ring 0.94 s after the sensor saw
    // it and the graph 3.42 s after, so for two and a half seconds out of every
    // two the two disagreed, by as much as twelve degrees on a ramp.
    //
    // 50 ms is eight times the slowest read observed and a tenth of the tick,
    // so the sample is both settled and, on screen, simultaneous.
    Timer {
        id: sample
        interval: 50
        repeat: false
        onTriggered: root.record({ cpu: root.cpu, mem: root.mem, temp: root.temp,
            fan: root.fan, gpu: root.gpu, vram: root.vram,
            swapIn: root.swapIn, swapOut: root.swapOut,
            netDown: root.netDown, netUp: root.netUp,
            diskRead: root.diskRead, diskWrite: root.diskWrite })
    }

    // The slow tier: everything that still starts a process — the laptop's fan
    // daemon, the charge, the backlight. Each of them costs a fork, so they stay
    // on the two seconds they were on before any of this. Raising the fast tier
    // was affordable exactly because it left this list alone, and the list is
    // one shorter than it was: the GPU left it by becoming three file reads.
    Timer {
        interval: root.procMs
        running: Caps.probed
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fwFanProc.running = Caps.fanSource === "fw";
            powerProc.running = Caps.hasBattery || Caps.hasBacklight;
        }
    }

    // Disks move slowly and df is a syscall storm; once every half minute is
    // plenty — unless the set of mounts to watch just changed under us.
    Timer {
        interval: root.diskMs
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
