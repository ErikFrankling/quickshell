import ".."
import Quickshell
import QtQuick
import QtQuick.Layouts

// Everything this machine can actually measure. What moves inside the graph
// window gets a graph, newest on the right; what only creeps — disk fullness,
// charge, swap occupancy — gets a number and a bar, because a two-minute
// history of it would be a flat line saying nothing. What is absent from both
// lists is absent from the hardware: no zeroed ring standing in for a GPU that
// is not there.
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
        if (Sys.hasDiskIo)
            r.push({
                label: "Disk I/O",
                values: h.diskRead,
                values2: h.diskWrite,
                max: 1048576,
                autoscale: true,
                readout: "R " + Sys.human(Sys.diskRead) + "/s  W " + Sys.human(Sys.diskWrite) + "/s"
            });
        if (Sys.hasSwap)
            r.push({
                label: "Swap I/O",
                values: h.swapIn,
                values2: h.swapOut,
                max: 1048576,
                autoscale: true,
                readout: "in " + Sys.human(Sys.swapIn) + "  out " + Sys.human(Sys.swapOut)
            });
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
        return r;
    }

    // The levels, not the traffic. Swap occupancy is here rather than in the
    // graphs because it only climbs while the kernel is already paging, and the
    // Swap I/O graph is what shows that the moment it starts — the percentage
    // itself would take the better part of an hour to visibly bend.
    readonly property var bars: {
        const b = [];
        if (Sys.hasSwap)
            b.push({ label: "Swap", pct: Sys.swap, readout: Sys.swap + "%" });
        if (Sys.hasBattery)
            b.push({
                label: "Battery",
                pct: Sys.battery,
                tint: Theme.heat(100 - Sys.battery),
                readout: Sys.battery + "%"
            });
        for (const d of Sys.disks)
            b.push({
                label: d.path,
                pct: d.pct,
                readout: d.pct + "%  ·  " + d.usedGb.toFixed(0) + " / " + d.sizeGb.toFixed(0) + " GB"
            });
        return b;
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
            }
            // Every graph below is sampled by the same timer, so one label is
            // the whole truth — and it is read off the timer, not typed here.
            Text {
                text: "graphs · last " + (Sys.historySec % 60 === 0
                    ? Sys.historySec / 60 + " min" : Sys.historySec + "s")
                color: Theme.dim
                font.pixelSize: 11
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                verticalAlignment: Text.AlignBottom
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
                model: ScriptModel { values: Sys.cores }

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

        // Above the graphs, because these are the two lines you open the panel
        // to read and the graphs below them are what scrolls off the bottom.
        Repeater {
            model: ScriptModel { values: root.bars }

            RowLayout {
                id: bar
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.pad

                Text {
                    text: bar.modelData.label
                    color: Theme.dim
                    font.pixelSize: 11
                    Layout.preferredWidth: 52
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Theme.bgAlt

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: Math.max(2, parent.width * Math.min(100, bar.modelData.pct) / 100)
                        radius: 3
                        color: bar.modelData.tint ?? Theme.heat(bar.modelData.pct)
                    }
                }

                Text {
                    text: bar.modelData.readout
                    color: Theme.fg
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }

        Repeater {
            model: ScriptModel { values: root.rows }

            Graph {
                required property var modelData
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
