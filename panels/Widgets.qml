import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

// The chevron flyout: every system tray icon, split by where it currently
// lives. The pin button moves one onto the rail, the eye takes it out of
// circulation entirely. Rows stay live — clicking one activates its item
// without pinning it first. Tray icons only; the rail's own buttons are not
// listed because they cannot be moved.
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
                values: SystemTray.items.values.filter(i => Pins.state(Pins.idOf(i)) === sec.want)
            }

            RowLayout {
                id: row
                required property var modelData

                Layout.fillWidth: true
                spacing: 6

                Entry {
                    // An em space holds the glyph column open for the icon
                    // drawn over it. Tooltips are free-form and often several
                    // lines; one line fits a row.
                    glyph: " "
                    label: (row.modelData.tooltipTitle || row.modelData.title
                            || row.modelData.id).split("\n")[0]
                    onClicked: row.modelData.activate()

                    Image {
                        anchors {
                            left: parent.left
                            leftMargin: 13
                            verticalCenter: parent.verticalCenter
                        }
                        width: 15
                        height: 15
                        source: row.modelData.icon
                        smooth: true
                    }
                }

                Btn {
                    glyph: "󰐃"
                    active: sec.want === "pinned"
                    onClicked: Pins.set(Pins.idOf(row.modelData),
                                        sec.want === "pinned" ? "overflow" : "pinned")
                }

                Btn {
                    glyph: sec.want === "hidden" ? "󰈉" : "󰈈"
                    onClicked: Pins.set(Pins.idOf(row.modelData),
                                        sec.want === "hidden" ? "overflow" : "hidden")
                }
            }
        }
    }

    Text {
        text: "Tray icons"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Section { title: "Behind the chevron"; want: "overflow" }
    Section { title: "On the rail"; want: "pinned" }
    Section { title: "Hidden"; want: "hidden" }

    Item { Layout.fillHeight: true }
}
