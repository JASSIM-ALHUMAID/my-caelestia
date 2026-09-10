import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.screensaver
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> timeoutItems: [
        MenuItem { text: qsTr("1 minute") },
        MenuItem { text: qsTr("3 minutes") },
        MenuItem { text: qsTr("5 minutes") },
        MenuItem { text: qsTr("10 minutes") },
        MenuItem { text: qsTr("15 minutes") },
        MenuItem { text: qsTr("30 minutes") },
        MenuItem { text: qsTr("Never") },
    ]
    readonly property list<int> timeoutValues: [60, 180, 300, 600, 900, 1800, 0]
    readonly property string videoName: {
        const path = GlobalConfig.general.screensaver.videoPath;
        if (!path)
            return qsTr("Not selected");
        const parts = path.split("/");
        return parts[parts.length - 1];
    }
    readonly property list<MenuItem> effectItems: root.buildEffectItems()
    readonly property FileDialog videoDialog: FileDialog {
        title: qsTr("Select a screensaver video")
        filterLabel: qsTr("Video files")
        filters: Images.validVideoExtensions
        onAccepted: path => {
            GlobalConfig.general.screensaver.videoPath = path;
            GlobalConfig.general.screensaver.effect = "video";
        }
    }

    function timeoutToIndex(val: int): int {
        let best = 0;
        let bestDiff = Math.abs(root.timeoutValues[0] - val);
        for (let i = 1; i < root.timeoutValues.length; i++) {
            const diff = Math.abs(root.timeoutValues[i] - val);
            if (diff < bestDiff) {
                bestDiff = diff;
                best = i;
            }
        }
        return best;
    }

    function buildEffectItems(): list<MenuItem> {
        const out = [];
        for (const e of Screensaver.effects) {
            const item = effectItemComp.createObject(root, { text: e.label });
            item.effectId = e.id;
            out.push(item);
        }
        return out;
    }

    function effectToIndex(id: string): int {
        for (let i = 0; i < root.effectItems.length; i++) {
            if (root.effectItems[i].effectId === id)
                return i;
        }
        return 0;
    }

    title: qsTr("Screensaver")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Component {
            id: effectItemComp

            MenuItem { property string effectId }
        }

        // Screensaver
        SettingsSection {
            first: true
            expanded: true
            title: qsTr("Screensaver")

            ToggleRow {
                Layout.fillWidth: true
                first: true
                text: qsTr("Enable screensaver")
                subtext: qsTr("Show an animated overlay after inactivity")
                checked: GlobalConfig.general.screensaver.enabled
                onToggled: GlobalConfig.general.screensaver.enabled = checked
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Start after")
                subtext: qsTr("How long to wait before the screensaver appears")
                menuItems: root.timeoutItems
                active: root.timeoutItems[root.timeoutToIndex(GlobalConfig.general.screensaver.timeout)]
                onSelected: item => GlobalConfig.general.screensaver.timeout = root.timeoutValues[root.timeoutItems.indexOf(item)]
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                Item {
                    Layout.fillWidth: true
                }

                TextButton {
                    type: TextButton.Tonal
                    text: qsTr("Preview")
                    onClicked: Screensaver.preview()
                }
            }
        }

        // Effects
        SettingsSection {
            title: qsTr("Effects")

            SelectRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Effect")
                subtext: qsTr("The animation shown while idle")
                menuItems: root.effectItems
                active: root.effectItems[root.effectToIndex(GlobalConfig.general.screensaver.effect)]
                onSelected: item => GlobalConfig.general.screensaver.effect = item.effectId
            }

            NavRow {
                Layout.fillWidth: true
                icon: "movie"
                label: qsTr("Video file")
                status: root.videoName
                onClicked: root.videoDialog.open()
            }

            ToggleRow {
                Layout.fillWidth: true
                last: true
                text: qsTr("Random effect")
                subtext: qsTr("Pick a random effect each time it activates")
                checked: GlobalConfig.general.screensaver.randomEffects
                onToggled: GlobalConfig.general.screensaver.randomEffects = checked
            }
        }
    }
}
