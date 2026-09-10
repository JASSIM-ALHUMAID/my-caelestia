import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var list
    readonly property string input: list.search.text.slice(`${GlobalConfig.launcher.actionPrefix}timer `.length).trim()
    readonly property int parsed: CountdownTimer.parseDuration(input)

    function humanDuration(seconds: int): string {
        if (seconds >= 3600 && seconds % 3600 === 0)
            return qsTr("%1 h").arg(seconds / 3600);
        if (seconds >= 60 && seconds % 60 === 0)
            return qsTr("%1 min").arg(seconds / 60);
        if (seconds < 60)
            return qsTr("%1 s").arg(seconds);
        const m = Math.floor(seconds / 60);
        const s = seconds % 60;
        return `${m}:${String(s).padStart(2, "0")}`;
    }

    function onClicked(): void {
        if (root.parsed > 0) {
            CountdownTimer.start(root.parsed);
            root.list.visibilities.launcher = false;
        } else if (CountdownTimer.active) {
            CountdownTimer.toggle();
            root.list.visibilities.launcher = false;
        }
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.onClicked()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: CountdownTimer.active ? (CountdownTimer.running ? "timer" : "pause") : "timer_off"
            fontStyle: Tokens.font.icon.extraLarge
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            id: label

            color: {
                if (root.input.length > 0 && root.parsed === 0)
                    return Colours.palette.m3error;
                if (root.input.length === 0 && !CountdownTimer.active)
                    return Colours.palette.m3onSurfaceVariant;
                return Colours.palette.m3onSurface;
            }

            text: {
                if (root.input.length > 0 && root.parsed > 0)
                    return qsTr("Start a %1 timer").arg(root.humanDuration(root.parsed));
                if (root.input.length > 0 && root.parsed === 0)
                    return qsTr("Unrecognised duration — try 30s, 5m, 1.5h");
                if (root.input.length === 0 && CountdownTimer.active)
                    return qsTr("%1 remaining — press enter to %2").arg(CountdownTimer.formatted()).arg(CountdownTimer.running ? qsTr("pause") : qsTr("resume"));
                return qsTr("Type a duration, e.g. 5m, 30s, 1.5h");
            }
            elide: Text.ElideLeft

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        StyledRect {
            visible: CountdownTimer.active
            color: Colours.palette.m3tertiary
            radius: Tokens.rounding.large
            clip: true

            implicitWidth: (stateLayer.containsMouse ? resetLabel.implicitWidth + resetLabel.anchors.rightMargin : 0) + resetIcon.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: Math.max(resetLabel.implicitHeight, resetIcon.implicitHeight) + Tokens.padding.small

            Layout.alignment: Qt.AlignVCenter

            StateLayer {
                id: stateLayer

                onClicked: {
                    CountdownTimer.reset();
                    root.list.visibilities.launcher = false;
                }

                color: Colours.palette.m3onTertiary
            }

            StyledText {
                id: resetLabel

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: resetIcon.left
                anchors.rightMargin: Tokens.spacing.small

                text: qsTr("Reset timer")
                color: Colours.palette.m3onTertiary
                font: Tokens.font.label.medium

                opacity: stateLayer.containsMouse ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            MaterialIcon {
                id: resetIcon

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Tokens.padding.medium

                text: "replay"
                color: Colours.palette.m3onTertiary
                fontStyle: Tokens.font.icon.large
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.Emphasized
                }
            }
        }
    }
}
