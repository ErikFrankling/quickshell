import ".."
import QtQuick
import QtQuick.Layouts

// Everything this machine can actually measure, one graph each, newest on the
// right. What is absent from `rows` is absent from the hardware — no zeroed
// ring standing in for a GPU that is not there.
Flickable {
    id: root

    // The card sizes itself to implicitHeight and caps it at the screen; the
    // Flickable is only here for the machine that has one metric too many.
    implicitHeight: col.implicitHeight
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var rows: {
        const h = Sys.history;
        const r = [{
            label: "CPU",
            values: h.cpu,
            tint: Theme.heat(Sys.cpu),
            readout: Sys.cpu + "%"
        }, {
            label: "Memory",
            values: h.mem,
            tint: Theme.heat(Sys.mem),
            readout: Sys.memUsedGb.toFixed(1) + " / " + Sys.memTotalGb.toFixed(0) + " GB"
        }];

        if (Sys.hasNet)
            r.push({
                label: "Network",
                values: h.netDown,
                values2: h.netUp,
                max: 262144,
                autoscale: true,
                readout: "↓ " + Sys.human(Sys.netDown) + "  ↑ " + Sys.human(Sys.netUp)
            });
        if (Sys.hasSwap) {
            r.push({
                label: "Swap",
                values: h.swap,
                tint: Theme.heat(Sys.swap),
                readout: Sys.swap + "%"
            });
            r.push({
                label: "Swap I/O",
                values: h.swapIn,
                values2: h.swapOut,
                max: 1048576,
                autoscale: true,
                readout: "in " + Sys.human(Sys.swapIn) + "  out " + Sys.human(Sys.swapOut)
            });
        }
        if (Sys.hasTemp)
            r.push({
                label: "Temperature",
                values: h.temp,
                tint: Theme.heat(Sys.temp),
                readout: Sys.temp + "°C"
            });
        if (Sys.hasFan)
            r.push({
                label: "Fan",
                values: h.fan,
                max: Caps.fanUnit === "%" ? 100 : 1500,
                autoscale: Caps.fanUnit !== "%",
                readout: Sys.fan + Caps.fanUnit
            });
        if (Sys.hasGpu) {
            r.push({
                label: "GPU",
                values: h.gpu,
                tint: Theme.heat(Sys.gpu),
                readout: Sys.gpu + "%"
            });
            r.push({
                label: "VRAM",
                values: h.vram,
                tint: Theme.heat(Sys.vram),
                readout: Sys.vramUsedGb.toFixed(0) + " / " + Sys.vramTotalGb.toFixed(0) + " GB"
            });
        }
        if (Sys.hasBattery)
            r.push({
                label: "Battery",
                values: h.battery,
                tint: Theme.heat(100 - Sys.battery),
                readout: Sys.battery + "%"
            });
        for (const d of Sys.disks)
            r.push({
                label: "Disk " + d.path,
                values: h["disk:" + d.path],
                tint: Theme.heat(d.pct),
                readout: d.usedGb.toFixed(0) + " / " + d.sizeGb.toFixed(0) + " GB"
            });
        return r;
    }

    ColumnLayout {
        id: col
        width: root.width
        spacing: Theme.pad

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "System"
                color: Theme.fg
                font.pixelSize: 18
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            Text {
                text: Sys.net !== "" ? Sys.net : "offline"
                color: Sys.net !== "" ? Theme.dim : Theme.bad
                font.pixelSize: 11
            }
        }

        // One bar per core, so a single pinned thread is visible even while the
        // average sits low.
        RowLayout {
            Layout.fillWidth: true
            visible: Sys.hasCores && Sys.cores.length > 0
            spacing: 3

            Repeater {
                model: Sys.cores

                Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 20
                    radius: 2
                    color: Theme.bgAlt

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: Math.max(1, parent.height * Math.min(100, parent.modelData) / 100)
                        radius: 2
                        color: Theme.heat(parent.modelData)
                    }
                }
            }
        }

        Repeater {
            model: root.rows

            Graph {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                values: modelData.values ?? []
                values2: modelData.values2 ?? []
                tint: modelData.tint ?? Theme.accent
                max: modelData.max ?? 100
                autoscale: modelData.autoscale ?? false
                label: modelData.label
                readout: modelData.readout
            }
        }

        Item { Layout.preferredHeight: 4 }
    }
}
