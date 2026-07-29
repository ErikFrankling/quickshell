import ".."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Theme.pad

    Text {
        text: "System"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Graph {
        Layout.fillWidth: true
        values: Sys.cpuHistory
        tint: Theme.heat(Sys.cpu)
        label: "CPU"
        readout: Sys.cpu + "%"
    }

    Graph {
        Layout.fillWidth: true
        values: Sys.memHistory
        tint: Theme.heat(Sys.mem)
        label: "Memory"
        readout: Sys.memUsedGb.toFixed(1) + " / " + Sys.memTotalGb.toFixed(0) + " GB"
    }

    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        columns: 4
        columnSpacing: Theme.pad
        rowSpacing: Theme.pad

        Ring { label: "disk"; value: Sys.disk }
        Ring { label: "swap"; value: Sys.swap }
        Ring { label: "gpu"; value: Sys.gpu }
        Ring { label: "temp"; value: Sys.temp; text: Sys.temp + "°" }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 6

        Entry { glyph: "󰋊"; label: "Root"; value: Sys.diskUsedGb.toFixed(0) + " / " + Sys.diskTotalGb.toFixed(0) + " GB" }
        Entry { glyph: "󰈐"; label: "Fan"; value: Sys.fan > 0 ? Sys.fan + "%" : "n/a" }
        Entry { glyph: "󰤨"; label: "Network"; value: Sys.net !== "" ? Sys.net : "down" }
    }

    Item { Layout.fillHeight: true }
}
