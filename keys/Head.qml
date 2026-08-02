import ".."
import QtQuick
import QtQuick.Layouts

// The strip above every page: which page you are on, what the keyboard does,
// and the one field that always has the focus.
//
// The field is the reason there are no bare-letter bindings anywhere in this
// window. Two of the three pages are *documenting* keys, so a sheet that took
// `j` for itself would be a sheet that lies about `j`; giving every printable
// character to the search box settles that once instead of key by key. It is
// the launcher's field, in the launcher's shape.
ColumnLayout {
    id: root

    property var pages: []
    property string page: ""
    property bool searchable: false
    // What Ctrl with the arrows does on the page in front of him. It is not
    // the same thing everywhere and a hint that says "filter" over a keyboard
    // is worse than none — he read it and reached for the mouse.
    property string chips: ""

    readonly property string query: field.text

    signal picked(string page)

    function clear() {
        field.text = "";
    }

    function grab() {
        field.forceActiveFocus();
    }

    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            text: "Keys"
            color: Theme.fg
            font.pixelSize: 18
            font.weight: Font.DemiBold
            Layout.rightMargin: 8
        }

        Repeater {
            model: root.pages

            Rectangle {
                id: chip

                required property var modelData
                readonly property bool here: chip.modelData[0] === root.page

                implicitWidth: tab.implicitWidth + 22
                implicitHeight: 26
                radius: 13
                color: chip.here ? Theme.bgHi : "transparent"
                border.width: 1
                border.color: chip.here ? Theme.accent : Theme.line

                Text {
                    id: tab
                    anchors.centerIn: parent
                    text: chip.modelData[1]
                    color: chip.here ? Theme.fg : Theme.dim
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.picked(chip.modelData[0])
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // The whole scheme, written where it is needed. There is no other
        // documentation of it and there should not have to be.
        Text {
            text: "Tab page · ↑↓ scroll"
                + (root.chips !== "" ? " · Ctrl↑↓ " + root.chips : "")
                + " · Esc close"
            color: Theme.dim
            font.pixelSize: 11
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: Theme.radiusS
        color: Theme.bgAlt
        // The board is a picture of a keyboard, not a list, so there is nothing
        // on it to filter and no field for it.
        visible: root.searchable

        TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.fg
            font.pixelSize: 13

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: field.text === ""
                text: "Search keys and descriptions"
                color: Theme.dim
                font.pixelSize: 13
            }
        }
    }
}
