import "keys" as Pages
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// What the keys do. The launcher's shape — a centred overlay on a keybind,
// a search field that always has the focus, Escape to dismiss, no rail button:
//   qs -p <repo> ipc call keys toggle
//
// Three pages rather than one sheet, because they answer three questions and
// only ever one at a time. The shape is `panels/Control.qml`'s, which is
// vast-shell's: a strip of chips along the top and a single Loader under it.
// The card takes its height *and its width* from whatever the Loader is
// holding, so the board — wide and short — does not have to live in a window
// sized for a 145-row keymap.
//
// It is driven from the keyboard and nothing else needs the mouse. The scheme
// is small on purpose, because two of the three pages are *documenting* keys
// and a sheet that steals `j` from the page explaining `j` is a bad sheet:
//
//   anything printable   goes into the search field, which always has focus.
//                        So there are no bare-letter bindings at all, and `gd`
//                        or `j` mean what the page says they mean.
//   Tab / Shift+Tab      next / previous page. One meaning, everywhere. It used
//                        to flip the board's layers on one page and change page
//                        on the other two, which is why it "worked sometimes".
//   Up / Down            scroll a row.
//   PageUp / PageDown    scroll a screen.
//   Ctrl + Up / Down     the page's own chips — the board's layers, the Neovim
//                        sheet's his-own/vim's-own. They were mouse-only.
//   Left / Right         the text cursor. They used to change page, which fires
//                        while you are editing a query — the same bug again.
//   Escape               clears the query if there is one, and closes if there
//                        is not. Never both at once: one keystroke that both
//                        throws away what you typed and shuts the window is a
//                        keystroke you cannot use to back out of a typo.
PanelWindow {
    id: root

    property bool open: false
    property string page: "board"
    readonly property string query: head.query

    visible: root.open
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "keys"
    // Exclusive focus while open, so Escape and Tab genuinely arrive here and
    // not at the window underneath; None when closed or it would swallow every
    // keystroke on the desktop.
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    readonly property var pages: [["board", "Dactyl"], ["hypr", "Hyprland"], ["nvim", "Neovim"]]

    readonly property bool searchable: loader.item ? loader.item.searchable : false

    // Each page names what its own chips are, so the hint line says "layer"
    // over the keyboard and "filter" over the map list, and says nothing on a
    // page that has no chips at all.
    readonly property string chips: loader.item && loader.item.chips !== undefined
                                  ? loader.item.chips : ""

    function show() {
        head.clear();
        // Always open on the board. The page is remembered while the shell
        // runs, so a session that ended on Hyprland reopened there — and the
        // keyboard is the thing he opens this for.
        root.page = "board";
        root.open = true;
    }

    function hide() {
        root.open = false;
    }

    function step(by) {
        const i = root.pages.findIndex(p => p[0] === root.page);
        root.page = root.pages[(i + by + root.pages.length) % root.pages.length][0];
    }

    function scroll(rows) {
        if (loader.item)
            loader.item.scroll(rows);
    }

    // Every page has a row of chips of its own — the board's layers, the
    // Neovim sheet's his-own/vim's-own — and they were reachable with the mouse
    // and nothing else. Ctrl with the same arrows that scroll: one axis, and
    // the modifier says "the bigger thing on it".
    function cycle(by) {
        if (loader.item)
            loader.item.cycle(by);
    }

    // Focus is taken a tick late, on purpose. `forceActiveFocus()` in `show()`
    // ran before the window was mapped and before the Loader had built the page
    // it was aiming at, so whether it stuck depended on timing. Deferring it
    // past the current pass makes both true first, and doing it on every page
    // change as well covers the Loader tearing down the item that held it.
    function grab() {
        if (root.searchable)
            head.grab();
        else
            card.forceActiveFocus();
    }

    onOpenChanged: if (root.open)
        Qt.callLater(root.grab)
    onPageChanged: Qt.callLater(root.grab)
    onSearchableChanged: Qt.callLater(root.grab)

    // Click anywhere outside the card to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        // Only as big as the page showing, and never bigger than the screen.
        width: Math.min(loader.item && loader.item.sheetWidth > 0 ? loader.item.sheetWidth : 880, parent.width - 80)
        height: Math.min(parent.height - 80, col.implicitHeight + 36)
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.line

        Behavior on width {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        // Every navigation key lives here and nowhere else. The field below has
        // the focus, and what it does not consume — Tab, the arrows, Escape —
        // propagates up to these handlers, so there is exactly one owner of the
        // scheme whether or not the page showing has a field at all.
        focus: true
        // One handler, not seven. `Keys.onPressed` declared next to the named
        // `Keys.onTabPressed` / `onDownPressed` handlers silently swallows most
        // of what it is standing beside — measured on this shell: with both
        // kinds present, Tab, Down and every letter reached neither, and only a
        // bare Shift got through. With this one handler alone every key
        // arrives. So the scheme lives in one switch that can be read top to
        // bottom, which is what it should have been anyway.
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (root.query !== "")
                    head.clear();
                else
                    root.hide();
            } else if (event.key === Qt.Key_Tab)
                root.step(1);
            else if (event.key === Qt.Key_Backtab)
                root.step(-1);
            else if (event.key === Qt.Key_Down)
                event.modifiers & Qt.ControlModifier ? root.cycle(1) : root.scroll(1);
            else if (event.key === Qt.Key_Up)
                event.modifiers & Qt.ControlModifier ? root.cycle(-1) : root.scroll(-1);
            else if (event.key === Qt.Key_PageDown)
                root.scroll(18);
            else if (event.key === Qt.Key_PageUp)
                root.scroll(-18);
            else
                return;
            event.accepted = true;
        }

        // Swallow clicks so they do not reach the dismiss layer behind.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Pages.Head {
                id: head
                Layout.fillWidth: true
                pages: root.pages
                page: root.page
                searchable: root.searchable
                chips: root.chips
                onPicked: p => root.page = p
            }

            Loader {
                id: loader
                Layout.fillWidth: true
                Layout.fillHeight: true
                // What makes the card resize per page: fillHeight alone reports
                // nothing upwards, so the column would ask for the chip strip
                // and stop.
                Layout.preferredHeight: item ? item.implicitHeight : 0
                sourceComponent: root.page === "hypr" ? cHypr : root.page === "nvim" ? cNvim : cBoard
                onLoaded: if (item)
                    item.query = Qt.binding(() => root.query)
            }

            Component {
                id: cBoard
                Pages.Layers {}
            }
            Component {
                id: cHypr
                Pages.Hypr {}
            }
            Component {
                id: cNvim
                Pages.Nvim {}
            }
        }
    }
}
