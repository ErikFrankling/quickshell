import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

// The chevron flyout: every system tray icon, pinned ones first. The rows are
// live and behave as the rail's icons do — left-click activates the item, right
// -click opens its own menu — and the one button pins a row to the rail or takes
// it off again. Tray icons only; the rail's own buttons are not listed because
// they cannot be moved.
ColumnLayout {
    id: root

    spacing: Theme.pad

    // Raised because the TrayMenu window belongs to shell.qml and a panel
    // cannot reach it from here. x and y are screen coordinates.
    signal menuRequested(var item, real x, real y)

    Text {
        text: "Tray icons"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Repeater {
        // ScriptModel, not the bare array: a tray item that quits while the
        // flyout is open would otherwise have Qt rebuild every delegate from
        // inside the destructor of the one that just went away.
        //
        // Pinned first, because with no headings the order is the only grouping
        // left, and the rail is the short deliberately chosen list.
        model: ScriptModel {
            values: [...SystemTray.items.values].sort(
                (a, b) => Pins.has(Pins.idOf(b)) - Pins.has(Pins.idOf(a)))
        }

        RowLayout {
            id: row

            required property var modelData
            readonly property bool isPinned: Pins.has(Pins.idOf(row.modelData))

            Layout.fillWidth: true
            spacing: 6

            Entry {
                // An em space holds the glyph column open for the icon drawn
                // over it. Tooltips are free-form and often several lines; one
                // line fits a row.
                glyph: " "
                label: (row.modelData.tooltipTitle || row.modelData.title
                        || row.modelData.id).split("\n")[0]
                // Pinned rows carry the accent wash as well as the lit pin, so
                // the state is legible from the row and not only the button.
                on: row.isPinned
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

                // Right button only, so the left one is declined here and falls
                // through to the row's own area underneath.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        if (!row.modelData.hasMenu)
                            return;
                        // Beside the flyout and top aligned with the row, which
                        // is what the rail does with its own icons. Mapping to
                        // the window's root item gives screen coordinates, and
                        // TrayMenu clamps them, so the bottom row is safe.
                        const p = row.mapToItem(null, row.width, 0);
                        root.menuRequested(row.modelData, p.x + Theme.pad, p.y - 6);
                    }
                }
            }

            Btn {
                glyph: "󰐃"
                active: row.isPinned
                onClicked: Pins.toggle(Pins.idOf(row.modelData))
            }
        }
    }

    Item { Layout.fillHeight: true }
}
