import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// One column of notification popups in a corner of one screen (shell.qml
// makes one per screen and corner).
PanelWindow {
    id: column
    required property var modelData
    // Which corner this column stands in. A sender picks one with the hint
    // `x-erikshell-corner` (`notify-send --hint=string:x-erikshell-corner:top-left`);
    // everything else goes top-right. speak (the personal agent's voice) uses
    // top-left, so its words stay up without covering the chat's Send button.
    property string corner: "top-right"
    readonly property var cards: Notifs.popups.filter(p =>
        (p.corner === "top-left" ? "top-left" : "top-right") === column.corner)
    screen: modelData

    visible: cards.length > 0
    anchors { top: true; right: corner === "top-right"; left: corner === "top-left" }
    implicitWidth: 400
    implicitHeight: Math.max(1, stack.implicitHeight + 20)
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: "notifications"

    ColumnLayout {
        id: stack
        anchors { fill: parent; margins: 10 }
        spacing: 9

        Repeater {
            model: column.cards
            NotifCard {
                id: card
                required property var modelData
                Layout.fillWidth: true
                n: modelData
                popup: true

                // How long this one is allowed to stay, in ms, where 0
                // is "until it is dismissed".
                //
                // Critical never expires, which is what dunst, mako and
                // three of the thirteen shells surveyed do; a critical
                // notification you can miss is not critical.
                //
                // Everything else starts from what the sender asked
                // for, which used to be thrown away entirely: measured
                // before this change, `notify-send -t 20000` was on
                // screen for 6.7 seconds. 0 means never expire and is
                // honoured — four of the five shells that read the
                // field at all fold 0 into their default instead, which
                // takes down the one popup that asked to stay.
                //
                // The ask is a floor rather than an override. An
                // application asking for longer means it; one asking
                // for shorter is usually just repeating its toolkit's
                // default and does not know he is mid-sentence. That is
                // the same conclusion noctalia reached from the other
                // direction, shipping respectExpireTimeout off by
                // default (Commons/Settings.qml:679-682).
                //
                // 12s is longer than any of the thirteen — they run
                // 3-8s — because this one is read while working, and
                // the two things that make a long popup obnoxious are
                // both handled: hovering one stops the clock, and four
                // is still the most that can be on screen.
                readonly property int life: {
                    const asked = modelData.timeout ?? -1;
                    if (modelData.urgency === "critical" || asked === 0)
                        return 0;
                    return Math.max(modelData.urgency === "low" ? 6000 : 12000, asked);
                }

                // Reaching for a popup must not lose it. A Timer starts
                // its interval again from zero when `running` goes back
                // true, so leaving the card grants a fresh full life
                // rather than the remainder — the one-line version of
                // hover-to-pause, and the one doannc2212 uses
                // (notifications/NotificationData.qml:65-73). Resuming
                // instead needs a paused flag, a timestamp pair and a
                // remaining-time field, all to make a popup you just
                // looked at leave sooner.
                //
                // HoverHandler rather than a MouseArea because the
                // action buttons have MouseAreas of their own, and one
                // underneath them would report the card un-hovered
                // exactly while he is reaching for Reply.
                HoverHandler { id: hov }

                Timer {
                    running: card.life > 0 && !hov.hovered
                    interval: card.life
                    onTriggered: Notifs.dismissPopup(modelData.key)
                }
            }
        }
    }
}
