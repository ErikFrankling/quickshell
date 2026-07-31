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

    // Which graphs this machine has, and nothing about what they currently
    // read. That separation is the whole point: this list is rebuilt only when
    // the hardware answer changes, so the model behind the Repeater is stable
    // and the delegates below live for as long as the panel does.
    //
    // It used to carry the live values and readouts too, which made it a new
    // list of new objects on every sample. ScriptModel compares by value, found
    // every row different, and emitted insert-then-remove for the lot — nine
    // Graphs, and with them nine Canvases, torn down and rebuilt twice a
    // second. Measured over two poll ticks: 36 constructions, 36 destructions,
    // and nine of those Graphs destroyed without ever having painted. A fresh
    // Canvas has no scene-graph node until its context arrives two queued event
    // loop hops later (qquickcanvasitem.cpp:530-541, :661), so every one of
    // those rebuilds was a chance to present an empty graph.
    //
    // The live figures are bound per row in the delegate instead, so a CPU
    // sample repaints the CPU graph and touches nothing else.
    readonly property var rows: {
        const r = [
            { key: "cpu", label: "CPU", unit: "%" },
            { key: "mem", label: "Memory", unit: "%" }
        ];
        if (Sys.hasNet)
            r.push({ key: "netDown", key2: "netUp", label: "Network",
                unit: "B/s", floor: 262144, autoscale: true });
        if (Sys.hasDiskIo)
            r.push({ key: "diskRead", key2: "diskWrite", label: "Disk I/O",
                unit: "B/s", floor: 1048576, autoscale: true });
        if (Sys.hasSwap)
            r.push({ key: "swapIn", key2: "swapOut", label: "Swap I/O",
                unit: "B/s", floor: 1048576, autoscale: true });
        if (Sys.hasTemp)
            r.push({ key: "temp", label: "Temperature", unit: "°C" });
        if (Sys.hasFan)
            r.push({ key: "fan", label: "Fan",
                unit: Caps.fanUnit === "%" ? "%" : "rpm",
                floor: Caps.fanUnit === "%" ? 100 : 1500,
                autoscale: Caps.fanUnit !== "%" });
        if (Sys.hasGpu) {
            r.push({ key: "gpu", label: "GPU", unit: "%" });
            r.push({ key: "vram", label: "VRAM", unit: "%" });
        }
        return r;
    }

    // The current reading for a row, as words. Reading the Sys properties in
    // here rather than in `rows` is what keeps the model still: the binding
    // that calls this is the delegate's own, so only the row whose numbers
    // moved is re-evaluated.
    function readoutFor(row) {
        switch (row.key) {
        case "cpu": return Sys.cpu + "%";
        case "mem": return Sys.memUsedGb.toFixed(1) + " / " + Sys.memTotalGb.toFixed(0) + " GB";
        case "netDown": return "↓ " + Sys.human(Sys.netDown) + "  ↑ " + Sys.human(Sys.netUp);
        case "diskRead": return "R " + Sys.human(Sys.diskRead) + "/s  W " + Sys.human(Sys.diskWrite) + "/s";
        case "swapIn": return "in " + Sys.human(Sys.swapIn) + "  out " + Sys.human(Sys.swapOut);
        case "temp": return Sys.temp + "°C";
        case "fan": return Sys.fan + Caps.fanUnit;
        case "gpu": return Sys.gpu + "%";
        case "vram": return Sys.vramUsedGb.toFixed(0) + " / " + Sys.vramTotalGb.toFixed(0) + " GB";
        }
        return "";
    }

    // Warm where the metric is high, for the metrics where "high" means
    // anything. A rate has no full, so it keeps the accent.
    function tintFor(row) {
        switch (row.key) {
        case "cpu": return Theme.heat(Sys.cpu);
        case "mem": return Theme.heat(Sys.mem);
        case "temp": return Theme.heat(Sys.temp);
        case "gpu": return Theme.heat(Sys.gpu);
        case "vram": return Theme.heat(Sys.vram);
        }
        return Theme.accent;
    }

    // --- how far back the graphs go ------------------------------------------
    //
    // Erik wants to choose the window. Sys keeps one buffer — `samples` of them,
    // one every `pollMs` — and that buffer is the longest window there can be;
    // the shorter ones are the same history read back over fewer samples, so
    // switching between them throws nothing away and takes effect on the next
    // frame rather than after a two-minute refill.
    //
    // The presets are fractions of what Sys actually keeps rather than typed
    // durations, so they stay true when the poll rate changes underneath —
    // whole, half and quarter of the buffer, printed as the seconds they are
    // worth at the rate Sys is running now. A window *longer* than the whole
    // buffer is not this panel's to give: that is Sys.samples, and the panel
    // cannot honestly print a span it has no samples for.
    readonly property var spans: [1, 2, 4]
    property int spanDiv: 1
    readonly property int spanSamples: Math.max(2, Math.round(Sys.samples / root.spanDiv))
    readonly property int spanSec: Math.round(root.spanSamples * Sys.pollMs / 1000)

    // Compact, because these three sit in the header next to the link readout
    // and the row has to survive a long SSID without pushing the card wider
    // than the card is.
    function spanText(div) {
        const s = Math.round(Math.max(2, Math.round(Sys.samples / div)) * Sys.pollMs / 1000);
        return s % 60 === 0 ? s / 60 + "m" : s + "s";
    }

    // The levels, not the traffic. Swap occupancy is here rather than in the
    // graphs because it only climbs while the kernel is already paging, and the
    // Swap I/O graph is what shows that the moment it starts — the percentage
    // itself would take the better part of an hour to visibly bend.
    //
    // Which bars, not what they read — the same split as `rows`, for the same
    // reason: a df run every half minute must not rebuild the rows it reports.
    readonly property var bars: {
        const b = [];
        if (Sys.hasSwap)
            b.push({ kind: "swap", label: "Swap" });
        if (Sys.hasBattery)
            b.push({ kind: "battery", label: "Battery" });
        for (const d of Sys.disks)
            b.push({ kind: "disk", label: d.path });
        return b;
    }

    function disk(path) {
        for (const d of Sys.disks)
            if (d.path === path)
                return d;
        return null;
    }

    function barPct(bar) {
        if (bar.kind === "swap")
            return Sys.swap;
        if (bar.kind === "battery")
            return Sys.battery;
        const d = root.disk(bar.label);
        return d ? d.pct : 0;
    }

    function barTint(bar) {
        return bar.kind === "battery"
            ? Theme.heat(100 - Sys.battery) : Theme.heat(root.barPct(bar));
    }

    function barReadout(bar) {
        if (bar.kind === "swap")
            return Sys.swap + "%";
        if (bar.kind === "battery")
            return Sys.battery + "%";
        const d = root.disk(bar.label);
        return d ? d.pct + "%  ·  " + d.usedGb.toFixed(0) + " / " + d.sizeGb.toFixed(0) + " GB" : "";
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
                text: "graphs · last"
                color: Theme.dim
                font.pixelSize: 11
                Layout.bottomMargin: 2
                verticalAlignment: Text.AlignBottom
            }
            // The window, and the choice of window, in one place: the label
            // that says how far back the graphs go is the control that sets it.
            // Three presets is a control on a panel; anything more would be a
            // settings screen, which this shell does not have.
            Repeater {
                model: root.spans

                Row {
                    id: span
                    required property int modelData
                    required property int index
                    spacing: 5
                    Layout.bottomMargin: 2
                    Layout.alignment: Qt.AlignBottom

                    Text {
                        text: "·"
                        visible: span.index > 0
                        color: Theme.line
                        font.pixelSize: 11
                    }

                    Text {
                        text: root.spanText(span.modelData)
                        color: root.spanDiv === span.modelData ? Theme.fg : Theme.dim
                        font.pixelSize: 11
                        font.weight: root.spanDiv === span.modelData ? Font.DemiBold : Font.Normal
                        font.features: ({ tnum: 1 })

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -3
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.spanDiv = span.modelData
                        }
                    }
                }
            }
            // The link this machine actually reaches the internet on.
            //
            // This read `Sys.net`, which Sys fills from the output of
            // ~/.local/bin/network-status.sh — a waybar script that does not
            // exist on this machine. The Process fails, the catch sets the
            // property to "", and the panel therefore said "offline" in
            // Theme.bad over a live gigabit link, permanently. The rail was
            // moved onto the Net singleton in 64d5e6a; this readout was the
            // last thing left behind on the old script.
            //
            // Net works the interface out from the default route rather than
            // from whichever card exists, so this and the rail glyph are now
            // answering from one source and cannot disagree.
            //
            // It elides and takes the slack rather than sizing the row: a
            // RowLayout is only as narrow as its widest child insists on being,
            // and a header that insists stretches every graph under it past the
            // edge of the card. An SSID can be any length.
            Text {
                text: Net.online
                    ? Net.link + (Net.rate !== "" ? " · " + Net.rate : "")
                    : "offline"
                color: Net.online ? Theme.dim : Theme.bad
                font.pixelSize: 11
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
        }

        // One bar per core, so a single pinned thread is visible even while the
        // average sits low.
        RowLayout {
            Layout.fillWidth: true
            visible: Sys.hasCores && Sys.cores.length > 0
            spacing: 3

            // Counted, not listed. A ScriptModel over the percentages themselves
            // was undefined behaviour by its own documentation — "only works
            // with lists of unique values" (scriptmodel.hpp:44-45) — and an idle
            // machine hands it a dozen equal numbers. It answered by destroying
            // and rebuilding a handful of cells on every sample; the count only
            // changes when the CPU does.
            Repeater {
                model: Sys.cores.length

                Rectangle {
                    id: core
                    required property int index
                    readonly property int load: Sys.cores[core.index] ?? 0
                    Layout.fillWidth: true
                    implicitHeight: 20
                    radius: 2
                    color: Theme.bgAlt

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: Math.max(1, parent.height * Math.min(100, core.load) / 100)
                        radius: 2
                        color: Theme.heat(core.load)
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
                        width: Math.max(2, parent.width * Math.min(100, root.barPct(bar.modelData)) / 100)
                        radius: 3
                        color: root.barTint(bar.modelData)
                    }
                }

                Text {
                    text: root.barReadout(bar.modelData)
                    color: Theme.fg
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    // A readout that re-flows the bar beside it every time a
                    // digit changes width is a bar that never stands still.
                    font.features: ({ tnum: 1 })
                }
            }
        }

        Repeater {
            model: ScriptModel { values: root.rows }

            Graph {
                id: graph
                required property var modelData
                readonly property var all: Sys.history[graph.modelData.key] ?? []
                readonly property var all2: graph.modelData.key2
                    ? (Sys.history[graph.modelData.key2] ?? []) : []

                Layout.fillWidth: true
                // The window is a slice of the one buffer Sys keeps, so
                // narrowing it is instant and widening it again finds the
                // history still there.
                span: root.spanSamples
                values: graph.all.slice(-root.spanSamples)
                values2: graph.all2.slice(-root.spanSamples)
                tint: root.tintFor(graph.modelData)
                max: graph.modelData.floor ?? 100
                autoscale: graph.modelData.autoscale ?? false
                unit: graph.modelData.unit
                label: graph.modelData.label
                readout: root.readoutFor(graph.modelData)
            }
        }

        Item { Layout.preferredHeight: 4 }
    }
}
