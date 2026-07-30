import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// A centred overlay, not a rail panel: it floats above everything, takes
// keyboard focus while open, and is driven entirely by a keybind.
//   qs -p <repo> ipc call launcher toggle
PanelWindow {
    id: root

    property bool open: false
    property string query: ""
    property int selected: 0

    visible: root.open
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "launcher"
    // Exclusive focus while open, so typing goes here and not to the window
    // underneath; None when closed or it would swallow every keystroke.
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    readonly property var hits: {
        const q = root.query.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        const scored = apps.map(a => {
            const name = a.name.toLowerCase();
            const rank = q === "" ? 0
                : name.startsWith(q) ? 0
                : name.includes(" " + q) ? 1
                : name.includes(q) ? 2
                : (a.genericName ?? "").toLowerCase().includes(q) ? 3 : -1;
            return { app: a, rank: rank };
        }).filter(x => x.rank >= 0);
        scored.sort((a, b) => a.rank - b.rank || a.app.name.localeCompare(b.app.name));
        return scored.slice(0, 30).map(x => x.app);
    }

    function show() {
        root.query = "";
        root.selected = 0;
        root.open = true;
        field.text = "";
        field.forceActiveFocus();
    }

    function hide() {
        root.open = false;
    }

    function run(app) {
        if (app) {
            app.execute();
            root.hide();
        }
    }

    // Click anywhere outside the card to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 620
        height: 460
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.line

        // Swallow clicks so they do not reach the dismiss layer behind.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: Theme.radiusS
                color: Theme.bgAlt

                TextInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.pixelSize: 15
                    onTextChanged: {
                        root.query = text;
                        root.selected = 0;
                    }
                    Keys.onEscapePressed: root.hide()
                    Keys.onReturnPressed: root.run(root.hits[root.selected])
                    Keys.onDownPressed: root.selected = Math.min(root.selected + 1, root.hits.length - 1)
                    Keys.onUpPressed: root.selected = Math.max(root.selected - 1, 0)

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: field.text === ""
                        text: "Search applications"
                        color: Theme.dim
                        font.pixelSize: 15
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 3
                clip: true
                model: root.hits
                currentIndex: root.selected
                highlightMoveDuration: 90
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    implicitHeight: 46
                    radius: Theme.radiusS
                    color: index === root.selected ? Theme.bgHi : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Image {
                            source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                            sourceSize.width: 26
                            sourceSize.height: 26
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                        }
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            Text {
                                text: modelData.name
                                color: Theme.fg
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: text !== ""
                                text: modelData.genericName ?? ""
                                color: Theme.dim
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.run(modelData)
                    }
                }
            }
        }
    }
}
