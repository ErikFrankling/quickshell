import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var n
    // Two different questions, and they used to be one property, which is why
    // the star in the history list was always hollow and always re-saved.
    // `saved` is whether this notification is in the saved list — the star.
    // `savedList` is whether this card is being drawn in that list, which is
    // all ✕ needs to know: it removes the entry from the list you can see.
    property bool saved: false
    property bool savedList: false
    property bool popup: false

    implicitHeight: col.implicitHeight + 22
    radius: Theme.radiusS + 2
    color: root.popup ? Qt.alpha(Theme.bgAlt, Theme.panelOpacity) : Theme.bgAlt
    border.width: root.n.urgency === "critical" ? 1 : 0
    border.color: Theme.bad

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 11
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.n.app
                color: root.n.urgency === "critical" ? Theme.bad : Theme.accent
                font.pixelSize: 11
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text { text: root.n.time; color: Theme.dim; font.pixelSize: 11 }
        }

        Text {
            text: Markup.plain(root.n.summary)
            color: Theme.fg
            font.pixelSize: 14
            font.weight: Font.DemiBold
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Text {
            visible: text !== ""
            text: Markup.rich(root.n.body)
            textFormat: Text.RichText
            color: Theme.fg
            opacity: 0.82
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            maximumLineCount: root.popup ? 4 : 12
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 6

            Repeater {
                model: root.n.actions ?? []
                Rectangle {
                    required property var modelData
                    implicitHeight: 26
                    implicitWidth: t.implicitWidth + 20
                    radius: Theme.radiusS
                    color: am.containsMouse ? Theme.accent : Theme.bgHi
                    Text {
                        id: t
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: am.containsMouse ? Theme.bg : Theme.fg
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: am
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Notifs.invoke(root.n.key, parent.modelData.id)
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Save for later. This is the point of keeping the id alive.
            Btn {
                visible: !root.popup
                glyph: root.saved ? "★" : "☆"
                implicitWidth: 26
                implicitHeight: 26
                onClicked: root.saved ? Notifs.unsave(root.n.key) : Notifs.save(root.n.key)
            }
            Btn {
                glyph: "✕"
                implicitWidth: 26
                implicitHeight: 26
                onClicked: root.popup ? Notifs.dismissPopup(root.n.key)
                                      : (root.savedList ? Notifs.unsave(root.n.key) : Notifs.drop(root.n.key))
            }
        }
    }
}
