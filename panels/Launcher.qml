import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    spacing: Theme.pad

    property string query: ""

    readonly property var hits: {
        const q = root.query.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        const scored = apps.map(a => {
            const name = a.name.toLowerCase();
            // Prefix beats word-start beats anywhere, so typing "fi" puts
            // Firefox above things that merely contain "fi".
            const rank = q === "" ? 0
                : name.startsWith(q) ? 0
                : name.includes(" " + q) ? 1
                : name.includes(q) ? 2
                : (a.genericName ?? "").toLowerCase().includes(q) ? 3 : -1;
            return { app: a, rank: rank };
        }).filter(x => x.rank >= 0);

        scored.sort((a, b) => a.rank - b.rank || a.app.name.localeCompare(b.app.name));
        return scored.slice(0, 40).map(x => x.app);
    }

    Text {
        text: "Launch"
        color: Theme.fg
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 38
        radius: Theme.radiusS
        color: Theme.bgAlt
        border.width: field.activeFocus ? 1 : 0
        border.color: Theme.accent

        TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.fg
            font.pixelSize: 13
            focus: true
            onTextChanged: root.query = text
            Keys.onReturnPressed: {
                if (root.hits.length > 0) {
                    root.hits[0].execute();
                    field.text = "";
                }
            }
            Keys.onEscapePressed: field.text = ""

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: field.text === ""
                text: "Type to search"
                color: Theme.dim
                font.pixelSize: 13
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 4
        clip: true
        model: root.hits

        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            implicitHeight: 42
            radius: Theme.radiusS
            color: hov.containsMouse ? Theme.bgHi : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 11

                Image {
                    source: Quickshell.iconPath(parent.parent.modelData.icon, "application-x-executable")
                    sourceSize.width: 22
                    sourceSize.height: 22
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Text {
                        text: parent.parent.parent.modelData.name
                        color: Theme.fg
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: text !== ""
                        text: parent.parent.parent.modelData.genericName ?? ""
                        color: Theme.dim
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                id: hov
                anchors.fill: parent
                hoverEnabled: true
                onClicked: parent.modelData.execute()
            }
        }
    }
}
