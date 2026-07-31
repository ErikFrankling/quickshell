//@ pragma ShellId netglyph

// Contact sheet. Sixteen ways to say *which link* and *is it tunnelled* in the
// rail's single 28px slot, drawn at true rail scale — Theme.slot for the
// ground, Theme.icon for the glyph, Theme.bgHi under it because a rail button
// sits inside a Group and Group draws its ground in bgHi.
//
// Eight columns: the four link states the rail can be in, each without and
// with a tunnel. A design has to survive all eight, not one.
//
// Nothing here is judged by eye. The two red registration marks let
// network-glyph.md's measuring script find the grid in a screenshot and count,
// for every design, how many of the slot's 784 pixels actually change when the
// tunnel comes up, how thin the mark that changes is, and whether the three
// link types are still told apart while it is up. The numbers are in the md.
//
// Harness only. Nothing here ships.
//
//   quickshell -p docs/surveys/network-glyph.qml

import QtQuick
import Quickshell
import Quickshell.Wayland
import "file:///home/erikf/projects/personal/quickshell" as Shell

ShellRoot {
    id: root

    // One slot, drawn sixteen ways. Everything below is the same 28px square
    // with the same 15px glyph in it; only the extra mark differs.
    component Cell: Item {
        id: cell

        property string design: ""
        property string glyph: ""
        property bool vpn: false

        // The Nerd Font glyphs that already fuse wifi and a padlock. There is
        // no ethernet-with-lock and no offline-with-lock in the set, so design
        // 13 cannot cover half the columns — which is the finding, not a gap
        // in the sheet.
        readonly property string fused:
              cell.glyph === "󰤨" ? "󰤪"
            : cell.glyph === "󰤟" ? "󰤡"
            : ""

        width: sheet.slot
        height: sheet.slot

        Rectangle {
            id: ground
            anchors.fill: parent
            radius: Shell.Theme.radiusS
            color: cell.design === "ground" && cell.vpn
                ? Qt.alpha(Shell.Theme.good, 0.22) : Shell.Theme.bgHi

            Text {
                anchors.centerIn: parent
                visible: cell.design !== "stack"
                font.pixelSize: sheet.icon
                text: {
                    if (!cell.vpn)
                        return cell.glyph;
                    switch (cell.design) {
                    case "shield":   return "󰦝";
                    case "key":      return "󰌆";
                    case "keylink":  return "󰌆";
                    case "shieldin": return "󰦝";
                    case "nflock":   return cell.fused || cell.glyph;
                    }
                    return cell.glyph;
                }
                color: cell.vpn && (cell.design === "tint" || cell.design === "ground")
                    ? Shell.Theme.good : Shell.Theme.fg
            }
        }

        // 1 — what this replaces. The link glyph keeps its slot and the tunnel
        // takes a second one, at the rail's real 5px gap.
        Rectangle {
            visible: cell.design === "twoslot" && cell.vpn
            x: sheet.slot + sheet.gap
            width: sheet.slot
            height: sheet.slot
            radius: Shell.Theme.radiusS
            color: Shell.Theme.bgHi
            Text {
                anchors.centerIn: parent
                text: "󰌆"
                color: Shell.Theme.good
                font.pixelSize: sheet.icon
            }
        }

        // 4 — Btn's own badge: an 8px accent disc, 3px in from the corner.
        // This is the mark the rail already uses for an unread count.
        Rectangle {
            visible: cell.design === "dot" && cell.vpn
            anchors { top: parent.top; right: parent.right; margins: 3 }
            width: 8; height: 8; radius: 4
            color: Shell.Theme.accent
        }

        // 5 — the same disc with noctalia's surface-coloured ring round it
        // (NotificationHistory.qml:129), which is what stops a badge
        // dissolving into the glyph underneath.
        Rectangle {
            visible: cell.design === "dotring" && cell.vpn
            anchors { top: parent.top; right: parent.right; margins: 2 }
            width: 9; height: 9; radius: 4.5
            color: Shell.Theme.good
            border.color: Shell.Theme.bgHi
            border.width: 1.5
        }

        // 6, 7 — a glyph rather than a disc in the corner.
        Text {
            visible: (cell.design === "cornkey" || cell.design === "cornlock") && cell.vpn
            anchors { right: parent.right; bottom: parent.bottom; rightMargin: -1; bottomMargin: -3 }
            text: cell.design === "cornkey" ? "󰌆" : "󰌾"
            color: Shell.Theme.good
            font.pixelSize: 9
        }

        // 9 — noctalia's focus underline (Taskbar.qml:870), borrowed to mean
        // tunnelled: 3px tall, half the slot wide.
        Rectangle {
            visible: cell.design === "underline" && cell.vpn
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
            width: 14; height: 3; radius: 1.5
            color: Shell.Theme.good
        }

        // 10 — a hairline round the whole slot.
        Rectangle {
            visible: cell.design === "ring" && cell.vpn
            anchors.fill: parent
            radius: Shell.Theme.radiusS
            color: "transparent"
            border.color: Shell.Theme.good
            border.width: 1
        }

        // 12 — both facts, stacked, inside the one slot.
        Column {
            visible: cell.design === "stack"
            anchors.centerIn: parent
            spacing: -2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: cell.glyph
                color: Shell.Theme.fg
                font.pixelSize: 11
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: cell.vpn
                text: "󰌆"
                color: Shell.Theme.good
                font.pixelSize: 9
            }
        }

        // 14 — the key is the subject and the link type is the footnote.
        Text {
            visible: cell.design === "keylink" && cell.vpn
            anchors { right: parent.right; bottom: parent.bottom; rightMargin: -1; bottomMargin: -2 }
            text: cell.glyph
            color: Shell.Theme.dim
            font.pixelSize: 8
        }

        // 15 — the link glyph shrunk into the shield's face.
        Text {
            visible: cell.design === "shieldin" && cell.vpn
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: cell.glyph
            color: Shell.Theme.bg
            font.pixelSize: 8
        }

        // 16 — a corner of the ground cut to the accent, the way a folded page
        // corner marks a page.
        Rectangle {
            visible: cell.design === "notch" && cell.vpn
            anchors { right: parent.right; bottom: parent.bottom }
            width: 9; height: 9
            radius: Shell.Theme.radiusS
            color: Shell.Theme.good
        }
    }

    PanelWindow {
        id: sheet

        anchors { top: true; left: true }
        margins { left: 20; top: 20 }
        implicitWidth: 800
        implicitHeight: 850
        exclusiveZone: 0
        color: Shell.Theme.bg
        WlrLayershell.namespace: "net-glyph-survey"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        // The rail's own vocabulary, so a mark drawn here is a mark that can
        // be drawn there.
        readonly property int slot: Shell.Theme.slot        // 28
        readonly property int icon: Shell.Theme.icon        // 15
        readonly property int gap: Shell.Theme.slotGap      // 5

        // Grid origin and pitch, fixed so the measuring script is arithmetic
        // rather than image recognition. Column pitch is 64 and not 44 because
        // design 1 — the two-slot baseline this replaces — has to be able to
        // draw its second slot at its true offset inside one cell.
        readonly property int x0: 250
        readonly property int y0: 90
        readonly property int colPitch: 64
        readonly property int rowPitch: 44
        readonly property int rowInset: 8

        readonly property var link: [
            { g: "󰈀", n: "ethernet" },
            { g: "󰤨", n: "wifi 90%" },
            { g: "󰤟", n: "wifi 20%" },
            { g: "󰤮", n: "offline" }
        ]

        readonly property var designs: [
            { id: "twoslot",   name: "1  two slots (baseline)" },
            { id: "shield",    name: "2  swap to shield" },
            { id: "key",       name: "3  swap to key" },
            { id: "dot",       name: "4  corner dot" },
            { id: "dotring",   name: "5  corner dot, ringed" },
            { id: "cornkey",   name: "6  corner key glyph" },
            { id: "cornlock",  name: "7  corner lock glyph" },
            { id: "tint",      name: "8  tint the link glyph" },
            { id: "underline", name: "9  underline" },
            { id: "ring",      name: "10 ring round the slot" },
            { id: "ground",    name: "11 fill the slot ground" },
            { id: "stack",     name: "12 stacked composite" },
            { id: "nflock",    name: "13 Nerd Font wifi+lock" },
            { id: "keylink",   name: "14 key, link as a tick" },
            { id: "shieldin",  name: "15 link inside a shield" },
            { id: "notch",     name: "16 corner notch" }
        ]

        Text {
            x: 20; y: 24
            text: "Link type and tunnel state in one 28px slot — 16 designs at rail scale"
            color: Shell.Theme.fg
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Repeater {
            model: 8
            Text {
                required property int index
                x: sheet.x0 + index * sheet.colPitch
                y: sheet.y0 - 32
                text: sheet.link[Math.floor(index / 2)].n + "\n" + (index % 2 ? "+vpn" : "—")
                color: index % 2 ? Shell.Theme.good : Shell.Theme.dim
                font.pixelSize: 9
            }
        }

        // Registration marks. Pure red, two pixels square, at a known offset
        // from the grid so the script can find it without recognising
        // anything.
        Rectangle { x: sheet.x0 - 6; y: sheet.y0 - 6; width: 2; height: 2; color: "#ff0000" }
        Rectangle {
            x: sheet.x0 - 6 + 8 * sheet.colPitch
            y: sheet.y0 - 6 + 16 * sheet.rowPitch
            width: 2; height: 2; color: "#ff0000"
        }

        Repeater {
            model: sheet.designs.length

            Item {
                id: designRow
                required property int index
                readonly property var d: sheet.designs[index]

                x: 0
                y: sheet.y0 + index * sheet.rowPitch
                width: sheet.width
                height: sheet.rowPitch

                Text {
                    x: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: designRow.d.name
                    color: Shell.Theme.fg
                    font.pixelSize: 11
                }

                Repeater {
                    model: 8
                    Cell {
                        required property int index
                        x: sheet.x0 + index * sheet.colPitch
                        y: sheet.rowInset
                        design: designRow.d.id
                        glyph: sheet.link[Math.floor(index / 2)].g
                        vpn: index % 2 === 1
                    }
                }
            }
        }
    }
}
