pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

// The right-click menu of a system tray item.
//
// A tray item's menu arrives over DBus as a QsMenuHandle. QsMenuAnchor hands
// that handle to the platform, which draws it in Qt's default style — a white
// box with square corners, in the middle of a dark shell. QsMenuOpener instead
// exposes the same menu as a model of QsMenuEntry, so the rows can be drawn
// here in the shell's own palette. Zaphkiel's TrayItemMenu, noctalia's TrayMenu
// and Ricelin's Tray all do exactly this, and none of them use QsMenuAnchor.
//
// The menu gets its own overlay window, as Ricelin's does: a layer surface can
// hold keyboard focus, so Escape closes it, and a full-screen surface catches
// the click that dismisses it.
PanelWindow {
    id: root

    // Non-null exactly while the menu is open.
    property var item: null

    // Top-left of the card, in screen coordinates. Clamped to the screen below.
    property real menuX: 0
    property real menuY: 0

    // Index of the row whose submenu is unfolded; one at a time, and reset on
    // every open. Submenus fold into the list rather than opening a second
    // window, which is Ricelin's trick and saves all the anchoring.
    property int unfolded: -1

    readonly property bool open: item !== null

    function show(trayItem, x, y) {
        root.unfolded = -1;
        root.item = trayItem;
        root.menuX = x;
        root.menuY = y;
    }

    function close() {
        root.item = null;
    }

    visible: root.open
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "shell-tray-menu"

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.close()
    }

    QsMenuOpener {
        id: opener
        menu: root.item ? root.item.menu : null
    }

    // QsMenuEntry.icon is a url string, not an icon name. An entry that came
    // over DBus carrying an icon-name gets "image://icon/<name>"; one carrying
    // inline icon-data gets a url into Quickshell's own image provider.
    //
    // The icon provider does not fail on a name the icon theme has never heard
    // of. It answers with missingPixmap(), the magenta and black checkerboard,
    // as a perfectly valid image, so the Image reaches Ready and nothing
    // downstream can tell that the lookup missed — which is why every project
    // that guards on the url alone still draws the checkerboard. Resolve the
    // name here instead and hand the Image an empty source when it misses, so
    // the row draws nothing rather than a broken square.
    //
    // Two kinds of url pass through untouched. Anything that is not an
    // "image://icon/" url is inline image data, which always loads. And a name
    // that carries a query string has a fallback attached, either a "?path="
    // directory to search or a "?fallback=" second name — Spotify's tray icon
    // is "spotify-linux-32", which exists in no installed theme and only under
    // the path Spotify hands over — and iconPath can check neither of those, so
    // those urls are left to the provider.
    function iconUrl(entry) {
        const url = entry?.icon ?? "";
        const prefix = "image://icon/";
        if (!url.startsWith(prefix))
            return url;
        const name = url.slice(prefix.length);
        if (name.includes("?"))
            return url;
        // Quickshell's own resolver, so this asks exactly the question the
        // provider is about to ask: empty means QIcon has nothing for the name.
        return Quickshell.iconPath(name, true) === "" ? "" : url;
    }

    // Whether the rows hold a column open for their icons. A menu normally
    // mixes entries that have an icon with entries that do not, and a real menu
    // reserves the icon column across the whole menu so that every label starts
    // on the same line: Qt's QMenu measures the widest icon over all of the
    // menu's actions and indents every label by it, and that width falls to
    // zero when no action has an icon at all. josecriane's tray menu arranges
    // the same thing by hand, passing keepEmptySpace to each row
    // (modules/popups/TrayMenu.qml:163) so that a row without an icon still
    // gets an empty item of icon size (ds/list/ListItem.qml:157-162).
    //
    // So a single entry whose icon resolves opens the column for every row, and
    // when none of them resolve the column collapses and the menu reads as
    // plain text instead of as a row of holes. Submenu rows share the top
    // level's column, since they are drawn inline in the same card.
    readonly property bool gutter: {
        const entries = opener.children ? opener.children.values : [];
        for (let i = 0; i < entries.length; i++) {
            if (root.iconUrl(entries[i]) !== "")
                return true;
        }
        return false;
    }

    // Anything outside the card dismisses.
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card

        readonly property int pad: 6

        x: Math.max(Theme.pad, Math.min(root.menuX, root.width - width - Theme.pad))
        y: Math.max(Theme.pad, Math.min(root.menuY, root.height - height - Theme.pad))
        width: 240
        height: col.implicitHeight + card.pad * 2
        radius: Theme.radiusS + 4
        color: Theme.bg
        border.width: 1
        border.color: Theme.line
        clip: true

        // Swallow clicks so they do not reach the dismiss layer.
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: card.pad
            spacing: 0

            Repeater {
                // ScriptModel, not the bare array. Menu entries are destroyed
                // under us when the application closes its menu, and a plain
                // array binding makes Qt rebuild every delegate from inside
                // the dying entry's destructor, which segfaults.
                model: ScriptModel {
                    values: opener.children ? [...opener.children.values] : []
                }

                delegate: Column {
                    id: group

                    required property var modelData
                    required property int index

                    width: col.width

                    MenuRow {
                        width: parent.width
                        entry: group.modelData
                        image: root.iconUrl(group.modelData)
                        gutter: root.gutter
                        open: root.unfolded === group.index
                        onActivated: {
                            if (group.modelData.hasChildren)
                                root.unfolded = root.unfolded === group.index ? -1 : group.index;
                            else {
                                group.modelData.triggered();
                                root.close();
                            }
                        }
                    }

                    QsMenuOpener {
                        id: subOpener
                        menu: root.unfolded === group.index ? group.modelData : null
                    }

                    Repeater {
                        model: ScriptModel {
                            values: subOpener.children ? [...subOpener.children.values] : []
                        }

                        delegate: MenuRow {
                            required property var modelData

                            width: group.width
                            indent: 14
                            entry: modelData
                            image: root.iconUrl(modelData)
                            gutter: root.gutter
                            onActivated: {
                                if (!modelData.hasChildren) {
                                    modelData.triggered();
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // One line of the menu: a separator, or a row with the entry's check or
    // radio state, its icon, its label and a chevron if it has children.
    component MenuRow: Item {
        id: row

        required property var entry
        property real indent: 0
        property bool open: false

        // Passed in rather than read off the entry: resolving the icon and
        // sizing the icon column are decisions for the menu as a whole, and an
        // inline component has its own scope and cannot reach the ids around it.
        property string image: ""
        property bool gutter: false

        signal activated

        // An entry is destroyed the moment the application withdraws its menu,
        // while the row that draws it is still being torn down, so everything
        // below reads the entry through these and never directly.
        readonly property bool separator: row.entry?.isSeparator ?? false
        readonly property bool usable: row.entry?.enabled ?? false
        readonly property int button: row.entry?.buttonType ?? QsMenuButtonType.None
        readonly property bool checked: row.entry?.checkState === Qt.Checked
        readonly property string label: row.entry?.text ?? ""
        readonly property bool foldable: row.entry?.hasChildren ?? false

        implicitHeight: row.separator ? 9 : 30

        Rectangle {
            visible: row.separator
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8 + row.indent
            anchors.rightMargin: 8
            height: 1
            color: Theme.line
        }

        Rectangle {
            visible: !row.separator
            anchors.fill: parent
            anchors.leftMargin: row.indent
            radius: Theme.radiusS
            color: area.containsMouse && row.usable ? Theme.bgHi : "transparent"

            Behavior on color { ColorAnimation { duration: 110 } }

            Rectangle {
                id: box

                readonly property bool radio: row.button === QsMenuButtonType.RadioButton
                readonly property bool shown: box.radio || row.button === QsMenuButtonType.CheckBox
                readonly property bool on: row.checked

                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                visible: box.shown
                width: box.shown ? 11 : 0
                height: 11
                radius: box.radio ? 5.5 : 3
                color: "transparent"
                border.width: 1
                border.color: box.on ? Theme.accent : Theme.dim

                Rectangle {
                    anchors.centerIn: parent
                    visible: box.on
                    width: 5
                    height: 5
                    radius: box.radio ? 2.5 : 1
                    color: Theme.accent
                }
            }

            Image {
                id: glyph

                // Width and visibility are deliberately separate. The column is
                // held open for every row of a menu that has any icon at all,
                // so a row whose icon did not resolve keeps its label in line
                // with the others; but with no source to draw it paints
                // nothing, and visible stays false so it can never paint
                // anything. Geometry is unaffected by visible in Qt Quick, so
                // the reserved width survives.
                readonly property bool reserved: row.gutter || row.image !== ""

                anchors.left: box.right
                anchors.leftMargin: box.shown ? 7 : 9
                anchors.verticalCenter: parent.verticalCenter
                visible: row.image !== ""
                width: glyph.reserved ? 14 : 0
                height: 14
                source: row.image
                sourceSize.width: 28
                sourceSize.height: 28
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                anchors.left: glyph.right
                anchors.leftMargin: glyph.reserved ? 8 : 0
                anchors.right: chevron.visible ? chevron.left : parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: row.label
                color: row.usable ? Theme.fg : Theme.dim
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                id: chevron
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: row.foldable
                text: row.open ? "󰅀" : "󰅂"
                color: row.open ? Theme.accent : Theme.dim
                font.pixelSize: 11
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                enabled: row.usable
                cursorShape: Qt.PointingHandCursor
                onClicked: row.activated()
            }
        }
    }
}
