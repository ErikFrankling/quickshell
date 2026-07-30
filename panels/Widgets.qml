import ".."
import QtQuick
import QtQuick.Layouts

// The chevron flyout: everything the rail could show, split by where it
// currently lives. The pin button moves a row onto the rail, the eye takes it
// out of circulation entirely. Tray rows stay live — clicking one activates it
// without pinning it first.
ColumnLayout {
    id: root
    spacing: Theme.pad

    component Section: ColumnLayout {
        id: sec

        property string title: ""
        property string want: ""

        Layout.fillWidth: true
        spacing: 6
        visible: rows.count > 0

        Text { text: sec.title; color: Theme.dim; font.pixelSize: 11 }

        Repeater {
            id: rows
            model: Pins.all.filter(e => Pins.state(e.id) === sec.want)

            RowLayout {
                id: row
                required property int index
                required property var modelData

                Layout.fillWidth: true
                spacing: 6

                Entry {
                    // An em space holds the glyph column open for tray rows, so
                    // their icon lands where every other row's glyph is.
                    glyph: row.modelData.item ? " " : row.modelData.glyph
                    label: row.modelData.label
                    onClicked: row.modelData.item?.activate()

                    Image {
                        visible: !!row.modelData.item
                        anchors {
                            left: parent.left
                            leftMargin: 13
                            verticalCenter: parent.verticalCenter
                        }
                        width: 15
                        height: 15
                        source: row.modelData.item?.icon ?? ""
                        smooth: true
                    }
                }

                Btn {
                    glyph: Pins.isPinned(row.modelData.id) ? "󰐃" : "󰤰"
                    active: Pins.isPinned(row.modelData.id)
                    onClicked: Pins.toggle(row.modelData.id)
                }

                Btn {
                    glyph: Pins.state(row.modelData.id) === "hidden" ? "󰈉" : "󰈈"
                    onClicked: {
                        if (Pins.state(row.modelData.id) === "hidden")
                            Pins.reveal(row.modelData.id);
                        else
                            Pins.conceal(row.modelData.id);
                    }
                }
            }
        }
    }

    Text {
        text: "Widgets"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Section { title: "In the flyout"; want: "overflow" }
    Section { title: "On the rail"; want: "pinned" }
    Section { title: "Hidden"; want: "hidden" }

    Item { Layout.fillHeight: true }
}
