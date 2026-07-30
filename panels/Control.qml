import ".."
import "." as Pages
import QtQuick
import QtQuick.Layouts

// Everything that did not earn a permanent slot on the rail, behind the one
// arrow that did: notifications, volume, and the tray.
//
// Almost nothing in this space pages. Noctalia's control centre is a stack of
// cards and sends anything deeper to a sibling panel through
// PanelService.getPanel() (Modules/Panels/ControlCenter/ControlCenterPanel.qml
// :99-140); whisker's is one fixed 460x670 surface (QuickPanel.qml:151-152) and
// tripathiji1312's one scrolling 440px column (ControlCenterWindow.qml:35-36).
// Two of the fifteen shells read for this page at all, and vast-shell's is the
// one worth copying: a strip of tab buttons along the top and a single Loader
// under it, one page live at a time (Qml/Modules/Drawers/QuickSettings
// /QuickSettings.qml:59-149, 212-218). Brainitech's Dashboard.qml:156-169 is
// the same shape with a component for the strip.
//
// No page here is a settings page, and none of them will be. What is on the
// rail, in what order, and what these three pages are is a code change.
//
// The card in shell.qml sizes itself to whatever this reports, so the panel is
// exactly as tall as the page showing and eases between the two. Ricelin needs
// a per-surface descriptor table to manage that (pill/Pill.qml:213-239) and
// Brainitech a lookup of page widths (popups/Dashboard.qml:31-42); the Loader
// below gets it for nothing, because a Layout already asks its child.
ColumnLayout {
    id: root

    spacing: Theme.pad

    property string page: "notifs"

    // Both are raised because they belong to shell.qml — the tray menu is a
    // window of its own and so is the looks overlay, and a panel cannot reach
    // either from its own scope.
    signal menuRequested(var item, real x, real y)
    signal looksRequested

    // Landing on the notifications page is reading them, which is what the
    // bell used to mean when it was still a button of its own.
    onPageChanged: if (root.page === "notifs") Notifs.markSeen()
    Component.onCompleted: Notifs.markSeen()

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Btn {
            glyph: "󰂚"
            active: root.page === "notifs"
            tint: Theme.fg
            onClicked: root.page = "notifs"
        }
        Btn {
            glyph: "󰕾"
            active: root.page === "audio"
            tint: Theme.fg
            onClicked: root.page = "audio"
        }
        Btn {
            glyph: "󰀻"
            active: root.page === "tray"
            tint: Theme.fg
            onClicked: root.page = "tray"
        }

        Item { Layout.fillWidth: true }

        // Not a page. A wallpaper grid in a 430px column gets three thumbnails
        // to a row, so looks is a centred window of its own on its own key;
        // this is the button for the times he does not remember the key.
        Btn {
            glyph: "󰸉"
            tint: Theme.fg
            onClicked: root.looksRequested()
        }
    }

    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        // What makes the card resize per page: fillHeight alone reports
        // nothing upwards, so the column would ask for the tab strip and
        // stop.
        Layout.preferredHeight: item ? item.implicitHeight : 0
        sourceComponent: root.page === "audio" ? cAudio
            : root.page === "tray" ? cTray : cNotifs
    }

    // Qualified: this directory and the one above it both have an Audio, and
    // only one of them is the pipewire singleton.
    Component { id: cNotifs; Pages.NotifCenter {} }
    Component { id: cAudio; Pages.Audio {} }
    Component {
        id: cTray
        Pages.Widgets {
            onMenuRequested: (item, x, y) => root.menuRequested(item, x, y)
        }
    }
}
