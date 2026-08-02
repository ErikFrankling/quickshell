import ".."
import QtQuick

// The body both list pages share: named sections of key/description rows, in
// balanced columns, filtered live by the window's search box.
//
// Vim ships two documents about its own keys and they disagree, which is the
// whole argument for this shape. `:help index` groups by mode and prints one
// alphabetical wall of 553 Ex commands; `:help quickref` — vim's own cheat
// sheet — throws mode away and groups by *task*, 41 sections of two to
// thirty-two entries, median thirteen, ordered the way you work: move, then
// find, then edit, then compose, then manage. rtorr, devhints and the printed
// reference cards all landed in the same place independently
// (docs/surveys/vim-cheatsheet.md). So a section here is a task, and one that
// grows past twenty-odd rows is a section that wants splitting.
//
// The other half of being readable is that the key stops being prose. It gets
// a monospace cap on its own ground and a fixed column to start in, so the eye
// has one edge to run down instead of scanning two kinds of text set alike.
Flickable {
    id: root

    // [{ name, items: [{ key, desc, modes, derived }] }]
    property var sections: []
    property string query: ""
    property int cols: 3
    property int keyW: 108
    property int gap: 20

    readonly property int rowH: 19

    clip: true
    contentHeight: body.implicitHeight
    contentWidth: width
    boundsBehavior: Flickable.StopAtBounds

    // Both halves of a mapping are searchable, and so is the way he would type
    // it. `fold` throws away everything that is punctuation-in-the-notation
    // rather than meaning — the angle brackets round `<leader>`, the `+` in
    // `Super + D`, and which-key's mnemonic brackets in `[S]earch [F]iles` —
    // so `leader sf`, `<leader>sf` and `search files` all land on the same row,
    // and typing a key sequence straight in finds it.
    function fold(s) {
        return (s ?? "").toLowerCase().replace(/[\[\]<>+_\s-]/g, "");
    }

    function match(it, q, f) {
        return it.hay.indexOf(q) >= 0 || (f !== "" && it.fold.indexOf(f) >= 0);
    }

    readonly property var shown: {
        const q = root.query.trim().toLowerCase();
        if (q === "")
            return root.sections;
        const f = root.fold(q);
        const out = [];
        for (const s of root.sections) {
            const kept = s.items.filter(it => root.match(it, q, f));
            if (kept.length > 0)
                out.push({
                    name: s.name,
                    items: kept
                });
        }
        return out;
    }

    readonly property int hits: root.shown.reduce((a, s) => a + s.items.length, 0)

    // Newspaper columns, not a masonry: sections stay in the order the page put
    // them in, and a column ends at the first section that would take it past
    // its share of the total. Reading order is therefore down and then right,
    // which is the order the sections were sorted into in the first place.
    readonly property var laid: {
        const secs = root.shown, cost = s => s.items.length + 2.4;
        const target = secs.reduce((a, s) => a + cost(s), 0) / root.cols;
        const out = [];
        let cur = [], h = 0;
        for (const s of secs) {
            if (out.length < root.cols - 1 && cur.length > 0 && h + cost(s) / 2 > target) {
                out.push(cur);
                cur = [];
                h = 0;
            }
            cur.push(s);
            h += cost(s);
        }
        out.push(cur);
        while (out.length < root.cols)
            out.push([]);
        return out;
    }

    function scroll(rows) {
        const to = root.contentY + rows * root.rowH;
        root.contentY = Math.max(0, Math.min(Math.max(0, root.contentHeight - root.height), to));
    }

    onQueryChanged: root.contentY = 0

    Row {
        id: body
        width: root.width
        spacing: root.gap

        Repeater {
            model: root.laid

            Column {
                id: colm

                required property var modelData

                width: (root.width - (root.cols - 1) * root.gap) / root.cols
                spacing: 15

                Repeater {
                    model: colm.modelData

                    Column {
                        id: sec

                        required property var modelData

                        width: colm.width
                        spacing: 4

                        Item {
                            width: sec.width
                            height: 18

                            Text {
                                id: head
                                text: sec.modelData.name
                                color: Theme.fg
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.left: head.right
                                anchors.leftMargin: 6
                                anchors.baseline: head.baseline
                                text: sec.modelData.items.length
                                color: Theme.dim
                                font.pixelSize: 10
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: Theme.line
                            }
                        }

                        Repeater {
                            model: sec.modelData.items

                            Item {
                                id: line

                                required property var modelData

                                width: sec.width
                                height: root.rowH

                                Rectangle {
                                    width: Math.min(cap.implicitWidth + 11, root.keyW)
                                    height: 16
                                    radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    // base02, not base01: against base00 the
                                    // card is already drawn on, base01 is a
                                    // difference you have to look for, and a
                                    // keycap you have to look for is a keycap
                                    // that has gone back to being prose.
                                    color: Theme.bgHi

                                    Text {
                                        id: cap
                                        anchors.centerIn: parent
                                        width: Math.min(implicitWidth, root.keyW - 11)
                                        text: line.modelData.key
                                        color: Theme.fg
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                // Modes only earn a mark when they are not just
                                // normal, which is most of the sheet.
                                Text {
                                    id: modes
                                    x: root.keyW + 6
                                    width: 32
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: line.modelData.modes ?? ""
                                    color: Theme.accent
                                    font.family: "monospace"
                                    font.pixelSize: 9
                                }

                                Text {
                                    anchors.left: modes.right
                                    anchors.leftMargin: 4
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    // A row whose label the shell derived is
                                    // drawn dim and italic, so the sheet never
                                    // claims somebody wrote that label for it.
                                    text: line.modelData.desc
                                    color: line.modelData.derived ? Theme.dim : Theme.fg
                                    font.italic: line.modelData.derived
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
