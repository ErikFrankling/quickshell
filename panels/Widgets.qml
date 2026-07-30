import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell

// The chevron flyout: everything the rail could show, split by where it
// currently lives. The pin button moves a row onto the rail, the eye takes it
// out of circulation entirely. Rows stay live — clicking one opens its panel or
// activates its tray item, without pinning it first.
ColumnLayout {
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
            // ScriptModel, not the bare array: a tray item that quits while the
            // flyout is open would otherwise have Qt rebuild every delegate
            // from inside the destructor of the one that just went away.
            model: ScriptModel {
                values: Pins.all.filter(e => Pins.state(e.id) === sec.want)
            }

            RowLayout {
                id: row
                required property var modelData

                Layout.fillWidth: true
                spacing: 6

                Entry {
                    glyph: row.modelData.glyph
                    label: row.modelData.label
                    onClicked: row.modelData.item ? row.modelData.item.activate()
                                                  : Pins.activate(row.modelData.id)

                    // Tray rows carry an icon where every other row has a glyph.
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
                    glyph: "󰐃"
                    active: sec.want === "pinned"
                    onClicked: Pins.set(row.modelData.id,
                                        sec.want === "pinned" ? "overflow" : "pinned")
                }

                Btn {
                    glyph: sec.want === "hidden" ? "󰈉" : "󰈈"
                    onClicked: Pins.set(row.modelData.id,
                                        sec.want === "hidden" ? "overflow" : "hidden")
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

    Section { title: "Behind the chevron"; want: "overflow" }
    Section { title: "On the rail"; want: "pinned" }
    Section { title: "Hidden"; want: "hidden" }

    Item { Layout.fillHeight: true }
}
