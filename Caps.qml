pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// What this machine can actually measure. Probed once at startup — a desktop
// does not grow a fan while the shell is running — and then overridden per host
// by the JSON nix/hm-module.nix writes. A metric nothing can produce must not
// render at all: a ring reading zero is a lie, not a measurement.
Singleton {
    id: root

    // False until the probe lands, so nothing flashes on screen a tick before
    // being hidden again.
    property bool probed: false

    // The sysfs directory of the GPU to read, or empty. Not a boolean, because
    // the capability and the reading have to be the same fact: a host where
    // this is empty has nothing to read, and a host where it is set has
    // somewhere to read from. That is what stops a ring being drawn over a
    // number nothing can produce.
    property string gpuPath: ""
    property bool foundTemp: false
    property bool foundBattery: false
    property bool foundBacklight: false
    property bool foundSwap: false
    property string fanSource: ""      // "hwmon" (rpm) | "fw" (percent) | none
    property var foundDisks: []
    property var nics: []              // interfaces backed by real hardware
    property var blocks: []            // whole block devices, no partitions

    // Home Manager writes this; anything it does not set falls through to what
    // the probe found.
    property var cfg: ({})

    function set(key, detected) {
        return typeof root.cfg[key] === "boolean" ? root.cfg[key] : detected;
    }

    // The one capability the override cannot switch on. Everything else here is
    // a preference — he may not want the fan on screen even though it answers —
    // but `gpu = true` on a machine with no file to read would put back exactly
    // the ring this replaced: drawn, gated, and reading zero forever. So the
    // override can only take the GPU away.
    readonly property bool hasGpu: gpuPath !== "" && set("gpu", true)
    readonly property bool hasFan: set("fan", fanSource !== "")
    readonly property bool hasTemp: set("temp", foundTemp)
    readonly property bool hasBattery: set("battery", foundBattery)
    readonly property bool hasBacklight: set("backlight", foundBacklight)
    readonly property bool hasSwap: set("swap", foundSwap)
    readonly property bool hasNet: set("net", nics.length > 0)
    readonly property bool hasDiskIo: set("diskio", blocks.length > 0)
    readonly property bool hasCores: set("cores", true)
    readonly property var disks: Array.isArray(cfg.disks) ? cfg.disks : foundDisks

    readonly property string fanUnit: fanSource === "fw" ? "%" : " rpm"

    // One shell, one pass, one parse. Every check is "does the thing answer",
    // never "does the vendor name look right".
    Process {
        running: true
        command: ["sh", "-c", `
# The GPU is whichever card exposes a utilisation file the shell can read, and
# where a machine has two — this one has an RX 7900 XT and the Raphael graphics
# on the CPU — the one with the most memory behind it. That is the discrete
# card every time, and the discrete card is the one worth a ring: the integrated
# one on this host reports the compositor's own work and jumps to 100% for a
# frame at a time. amdgpu is the only driver that publishes this; on anything
# else the loop finds nothing, and nothing is the honest answer.
gpu=
best=-1
for d in /sys/class/drm/card*/device; do
  [ -r "$d/gpu_busy_percent" ] || continue
  vram=$(cat "$d/mem_info_vram_total" 2>/dev/null)
  case "$vram" in ''|*[!0-9]*) vram=0;; esac
  [ "$vram" -gt "$best" ] || continue
  best=$vram
  gpu=$d
done
echo "gpu=$gpu"
fan=
ls /sys/class/hwmon/hwmon*/fan1_input >/dev/null 2>&1 && fan=hwmon
[ -z "$fan" ] && command -v fw-fanctrl >/dev/null 2>&1 && fan=fw
echo "fan=$fan"
ls /sys/class/hwmon/hwmon*/temp1_input >/dev/null 2>&1 && echo temp=1 || echo temp=0
bat=0
grep -qil battery /sys/class/power_supply/*/type 2>/dev/null && bat=1
command -v upower >/dev/null 2>&1 && upower -e 2>/dev/null | grep -qi bat && bat=1
echo "battery=$bat"
[ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ] && echo backlight=1 || echo backlight=0
awk '/^SwapTotal:/ { print "swap=" (($2 > 0) ? 1 : 0) }' /proc/meminfo
echo "nics=$(for d in /sys/class/net/*; do [ -e "$d/device" ] && basename "$d"; done | tr '\\n' ' ')"
# /sys/block lists whole devices only — partitions hang off them — so summing
# these never counts a disk twice. What is left to drop is the devices with no
# spindle or cell behind them, and the mappers stacked on a device already here.
echo "blocks=$(for d in /sys/block/*; do n=\${d##*/}; case "$n" in loop*|ram*|zram*|sr*|fd*|dm-*|md*) continue;; esac; echo "$n"; done | tr '\\n' ' ')"
echo "disks=$(df -B1 --output=target,size -x tmpfs -x devtmpfs -x efivarfs -x overlay -x squashfs -x fuse.portal 2>/dev/null | awk 'NR > 1 && $2 + 0 > 10737418240 { print $1 }' | tr '\\n' ' ')"
`]

        stdout: StdioCollector {
            onStreamFinished: {
                const v = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        v[line.slice(0, i)] = line.slice(i + 1).trim();
                }
                const list = s => (s || "").split(/\s+/).filter(x => x.length > 0);

                root.gpuPath = v.gpu || "";
                root.fanSource = v.fan || "";
                root.foundTemp = v.temp === "1";
                root.foundBattery = v.battery === "1";
                root.foundBacklight = v.backlight === "1";
                root.foundSwap = v.swap === "1";
                root.nics = list(v.nics);
                root.blocks = list(v.blocks);
                root.foundDisks = list(v.disks);
                root.probed = true;
            }
        }
        onExited: root.probed = true
    }

    // Not Quickshell.configPath(), which resolves inside the shell source tree.
    // Home Manager owns ~/.config, so that is where the override lives.
    readonly property string configFile: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/erikshell/metrics.json"

    // watchChanges alone is not enough: home-manager installs this as a symlink
    // into the store and switching swaps the link, which the watcher on the old
    // target never sees — and it cannot watch a file that does not exist yet.
    // Re-reading forty bytes now and then is cheaper than the bug.
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: cfgFile.reload()
    }

    FileView {
        id: cfgFile
        path: root.configFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.cfg = JSON.parse(text());
            } catch (e) {
                root.cfg = {};
            }
        }
        onLoadFailed: root.cfg = ({})
    }
}
