//@ pragma ShellId railplayersurvey

// Contact sheet. Ten real now-playing designs, each redrawn at the rail's
// actual 58px width so they can be compared as the same problem rather than as
// screenshots at ten different scales. Every one is a mock of a specific file
// that was read; the caption under each names it.
//
// Harness only. Nothing here ships.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "file:///home/erikf/projects/personal/quickshell" as Shell

ShellRoot {
    PanelWindow {
        anchors { top: true; left: true }
        margins { left: 40; top: 40 }
        implicitWidth: 1180
        implicitHeight: 430
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "railplayer-survey"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: "#11141a"
            radius: 8

            property color bg: Shell.Theme.bg
            property color ground: Shell.Theme.bgHi
            property color fg: Shell.Theme.fg
            property color dim: Shell.Theme.dim
            property color acc: Shell.Theme.accent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Text {
                    text: "Now-playing in a 58px vertical rail — ten real implementations, redrawn at true width"
                    color: "#d3c6aa"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    spacing: 0
                    Layout.fillHeight: true

                    Repeater {
                        model: [
                            { n: "1. noctalia MediaMini",     f: "Bar/Widgets/MediaMini.qml:348",  k: "ring",    t: "circular art + progress ring.\ntitle in a hover tooltip.\nno transport." },
                            { n: "2. end-4 VerticalMedia",   f: "verticalBar/VerticalMedia:44",   k: "glyphring", t: "progress circle + play glyph.\ntitle in a hover popup.\ntransport on mouse buttons." },
                            { n: "3. DankMaterialShell",     f: "DankBar/Widgets/Media:171",      k: "dms",     t: "note icon + round play button.\nno title at all.\nprev/next on middle+right click." },
                            { n: "4. omarchy-quattro",       f: "services/media/BarWidget:46",    k: "glyph",   t: "glyph only — the title is\nliterally visible: !vertical." },
                            { n: "5. mpris-lyric plugin",    f: "mpris-lyric/BarWidget:53",       k: "glyph2",  t: "square capsule, icon swap.\nlyric/title dropped on vertical." },
                            { n: "6. nucleus-shell",         f: "bar/content/MediaPlayerModule",  k: "art",     t: "square album art, spins while\nplaying. title overflows a rail." },
                            { n: "7. amadeus",               f: "components/Player.qml:15",       k: "grow",    t: "28px button that unfurls to a\n120px art card while playing.\nno title." },
                            { n: "8. cartoon-shell",         f: "MediaSectionVertical.qml:23",    k: "marquee", t: "title rotated -90 as a vertical\nmarquee. no art. play/pause only." },
                            { n: "9. shub39 PlayingMedia",   f: "quickshell/bar/PlayingMedia:65", k: "shub",    t: "title rotated 90, truncated in JS.\nno state, no controls at all." },
                            { n: "10. THIS — RailPlayer",    f: "RailPlayer.qml",                 k: "mine",    t: "art + progress + rotated title\n+ play/pause and next, visible." }
                        ]

                        ColumnLayout {
                            id: cell
                            required property var modelData
                            Layout.preferredWidth: 116
                            Layout.fillHeight: true
                            spacing: 6

                            // the strip, at the real rail width
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 58
                                implicitHeight: 236
                                color: Shell.Theme.bg
                                radius: 6

                                Loader {
                                    anchors.centerIn: parent
                                    sourceComponent: {
                                        switch (cell.modelData.k) {
                                        case "ring": return cRing;
                                        case "glyphring": return cGlyphRing;
                                        case "dms": return cDms;
                                        case "glyph": return cGlyph;
                                        case "glyph2": return cGlyph2;
                                        case "art": return cArt;
                                        case "grow": return cGrow;
                                        case "marquee": return cMarquee;
                                        case "shub": return cShub;
                                        default: return cMine;
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.modelData.n
                                color: cell.modelData.k === "mine" ? Shell.Theme.accent : "#d3c6aa"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: cell.modelData.t.replace(/\n/g, " ")
                                color: "#859289"
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }
        }

        // ---- mocks -------------------------------------------------------

        component Ground: Rectangle {
            implicitWidth: 46
            radius: 15
            color: Shell.Theme.bgHi
        }

        // 1 noctalia: circular art with a progress ring around it
        Component {
            id: cRing
            Ground {
                implicitHeight: 58
                Canvas {
                    anchors.centerIn: parent
                    width: 38; height: 38
                    onPaint: {
                        const c = getContext("2d"); c.reset();
                        c.lineWidth = 2;
                        c.beginPath(); c.arc(19, 19, 18, 0, Math.PI * 2);
                        c.strokeStyle = Shell.Theme.line; c.stroke();
                        c.beginPath(); c.arc(19, 19, 18, -Math.PI / 2, Math.PI * 0.6);
                        c.strokeStyle = Shell.Theme.accent; c.stroke();
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 28; height: 28; radius: 14
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#8f6b52" }
                        GradientStop { position: 1; color: "#4a3f52" }
                    }
                }
            }
        }

        // 2 end-4: filled progress circle with a pause glyph in it
        Component {
            id: cGlyphRing
            Ground {
                implicitHeight: 46
                Canvas {
                    anchors.centerIn: parent
                    width: 30; height: 30
                    onPaint: {
                        const c = getContext("2d"); c.reset();
                        c.lineWidth = 3;
                        c.beginPath(); c.arc(15, 15, 12, 0, Math.PI * 2);
                        c.strokeStyle = Shell.Theme.line; c.stroke();
                        c.beginPath(); c.arc(15, 15, 12, -Math.PI / 2, Math.PI * 0.2);
                        c.strokeStyle = Shell.Theme.accent; c.stroke();
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "󰏤"; color: Shell.Theme.fg; font.pixelSize: 13
                }
            }
        }

        // 3 DMS: note icon stacked over a filled round play button
        Component {
            id: cDms
            Ground {
                implicitHeight: 66
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰝚"; color: Shell.Theme.accent; font.pixelSize: 17
                    }
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 24; height: 24; radius: 12
                        color: Shell.Theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: "󰏤"; color: Shell.Theme.bg; font.pixelSize: 12
                        }
                    }
                }
            }
        }

        // 4 omarchy-quattro: one glyph, title suppressed on vertical
        Component {
            id: cGlyph
            Ground {
                implicitHeight: 40
                Text {
                    anchors.centerIn: parent
                    text: "󰏤"; color: Shell.Theme.fg; font.pixelSize: 16
                }
            }
        }

        // 5 mpris-lyric: square capsule, icon swap only
        Component {
            id: cGlyph2
            Ground {
                implicitHeight: 40
                Rectangle {
                    anchors.centerIn: parent
                    width: 30; height: 30; radius: 8
                    color: Shell.Theme.bgAlt
                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"; color: Shell.Theme.accent; font.pixelSize: 14
                    }
                }
            }
        }

        // 6 nucleus: square album art as the icon
        Component {
            id: cArt
            Ground {
                implicitHeight: 46
                Rectangle {
                    anchors.centerIn: parent
                    width: 30; height: 30; radius: 12
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#6b7f8f" }
                        GradientStop { position: 1; color: "#3a4450" }
                    }
                }
            }
        }

        // 7 amadeus: collapsed button vs the 120px card it becomes
        Component {
            id: cGrow
            Ground {
                implicitHeight: 132
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 28; height: 96; radius: 6
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#7a5f7a" }
                            GradientStop { position: 1; color: "#33303f" }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰏤"; color: Shell.Theme.fg; font.pixelSize: 12
                    }
                }
            }
        }

        // 8 cartoon-shell: rotated marquee title, no art
        Component {
            id: cMarquee
            Ground {
                implicitHeight: 132
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 34; implicitHeight: 96
                        Text {
                            anchors.centerIn: parent
                            rotation: -90
                            width: 96
                            text: "Time to Pretend"
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            color: Shell.Theme.fg; font.pixelSize: 11
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰏤"; color: Shell.Theme.fg; font.pixelSize: 12
                    }
                }
            }
        }

        // 9 shub39: rotated icon + rotated title, readout only
        Component {
            id: cShub
            Ground {
                implicitHeight: 132
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        rotation: 90
                        text: "󰝚"; color: Shell.Theme.dim; font.pixelSize: 14
                    }
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 34; implicitHeight: 92
                        Text {
                            anchors.centerIn: parent
                            rotation: 90
                            width: 92
                            text: "Time to Pretend"
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            color: Shell.Theme.fg
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
            }
        }

        // 10 this one, live off the real component
        Component {
            id: cMine
            Ground {
                implicitHeight: mine.implicitHeight + 12
                Shell.RailPlayer {
                    id: mine
                    anchors.centerIn: parent
                }
            }
        }
    }
}
