pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Visualiser")
    isSubPage: true

    readonly property string edge: root.nState.selectedEdge

    readonly property list<MenuItem> clickActionItems: [
        MenuItem { text: qsTr("None"); property string value: "none" },
        MenuItem { text: qsTr("Open nexus"); property string value: "nexus" },
    ]

    readonly property list<MenuItem> silenceBehaviorItems: [
        MenuItem { text: qsTr("Flat"); property string value: "flat" },
        MenuItem { text: qsTr("Hide"); property string value: "hide" },
    ]

    readonly property MenuItem activeClickAction: {
        const val = Config.bar[root.edge].visualiser.clickAction;
        for (const item of root.clickActionItems)
            if (item.value === val) return item;
        return root.clickActionItems[0];
    }

    readonly property MenuItem activeSilenceBehavior: {
        const val = Config.bar[root.edge].visualiser.silenceBehavior;
        for (const item of root.silenceBehaviorItems)
            if (item.value === val) return item;
        return root.silenceBehaviorItems[0];
    }

    readonly property list<MenuItem> fillModeItems: [
        MenuItem { text: qsTr("Outward"); property string value: "outward" },
        MenuItem { text: qsTr("Inward"); property string value: "inward" },
        MenuItem { text: qsTr("Center"); property string value: "center" },
        MenuItem { text: qsTr("Mirror"); property string value: "mirror" },
    ]

    readonly property MenuItem activeFillMode: {
        const val = Config.bar[root.edge].visualiser.fillMode;
        for (const item of root.fillModeItems)
            if (item.value === val) return item;
        return root.fillModeItems[0];
    }

    readonly property list<MenuItem> colorModeItems: [
        MenuItem { text: qsTr("Solid"); property string value: "solid" },
        MenuItem { text: qsTr("Gradient"); property string value: "gradient" },
        MenuItem { text: qsTr("Bar gradient"); property string value: "bar_gradient" },
    ]

    readonly property MenuItem activeColorMode: {
        const val = Config.bar[root.edge].visualiser.barColorMode;
        for (const item of root.colorModeItems)
            if (item.value === val) return item;
        return root.colorModeItems[0];
    }

    readonly property bool isGradientMode: {
        const mode = Config.bar[root.edge].visualiser.barColorMode;
        return mode === "gradient" || mode === "bar_gradient";
    }

    readonly property bool isCustomColorSource: {
        return Config.bar[root.edge].visualiser.barColorSource === "custom";
    }

    readonly property list<MenuItem> colourSourceItems: [
        MenuItem { text: qsTr("Dynamic"); property string value: "dynamic" },
        MenuItem { text: qsTr("Custom"); property string value: "custom" },
    ]

    readonly property MenuItem activeColourSource: {
        const val = Config.bar[root.edge].visualiser.barColorSource;
        for (const item of root.colourSourceItems)
            if (item.value === val) return item;
        return root.colourSourceItems[0];
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SettingsSection {
            first: true
            expanded: true
            title: qsTr("Appearance")

            StepperRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Bar count")
                subtext: qsTr("Number of frequency bars (2–10)")
                value: Config.bar[root.edge].visualiser.bars
                from: 2
                to: 20
                stepSize: 1
                onMoved: v => GlobalConfig.bar[root.edge].visualiser.bars = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Bar width")
                subtext: qsTr("Thickness of each bar along the bar's edge (px)")
                value: Config.bar[root.edge].visualiser.barWidth
                from: 4
                to: 20
                stepSize: 2
                onMoved: v => GlobalConfig.bar[root.edge].visualiser.barWidth = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Bar length")
                subtext: qsTr("Container depth — maximum length bars can extend (px)")
                value: Config.bar[root.edge].visualiser.barLength
                from: 20
                to: 100
                stepSize: 5
                onMoved: v => GlobalConfig.bar[root.edge].visualiser.barLength = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Bar rounding")
                subtext: qsTr("Corner radius of each bar in pixels")
                value: Config.bar[root.edge].visualiser.barRounding
                from: 0
                to: 20
                stepSize: 2
                onMoved: v => GlobalConfig.bar[root.edge].visualiser.barRounding = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Bar spacing")
                subtext: qsTr("Gap between bars in pixels")
                value: Config.bar[root.edge].visualiser.barSpacing
                from: 0
                to: 20
                stepSize: 1
                onMoved: v => GlobalConfig.bar[root.edge].visualiser.barSpacing = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Bar height")
                subtext: qsTr("Amplitude multiplier (50%–200%)")
                value: Config.bar[root.edge].visualiser.barAmplitude
                from: 50
                to: 200
                stepSize: 10
                onMoved: v => GlobalConfig.bar[root.edge].visualiser.barAmplitude = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Frequency tilt")
                subtext: qsTr("Boost highs (>0) or lows (<0)")
                value: Config.bar[root.edge].visualiser.tilt
                from: -1.0
                to: 1.0
                stepSize: 0.1
                onMoved: v => GlobalConfig.bar[root.edge].visualiser.tilt = v
            }

            StepperRow {
                Layout.fillWidth: true
                label: qsTr("Smoothing")
                subtext: qsTr("Bar rise/fall response time (ms)")
                value: Config.bar[root.edge].visualiser.smoothing
                from: 10
                to: 300
                stepSize: 10
                onMoved: v => GlobalConfig.bar[root.edge].visualiser.smoothing = v
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Fill mode")
                subtext: qsTr("Direction bars grow from")
                menuItems: root.fillModeItems
                active: root.activeFillMode
                onSelected: item => GlobalConfig.bar[root.edge].visualiser.fillMode = item.value
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Colour mode")
                subtext: qsTr("How bar colours are selected")
                menuItems: root.colorModeItems
                active: root.activeColorMode
                onSelected: item => GlobalConfig.bar[root.edge].visualiser.barColorMode = item.value
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Colour source")
                subtext: qsTr("Dynamic uses theme colours, custom uses hex values")
                menuItems: root.colourSourceItems
                active: root.activeColourSource
                onSelected: item => GlobalConfig.bar[root.edge].visualiser.barColorSource = item.value
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.isCustomColorSource
                spacing: Tokens.spacing.small

                TextFieldRow {
                    Layout.fillWidth: true
                    label: qsTr("Colour 1")
                    placeholder: "#RRGGBB"
                    text: Config.bar[root.edge].visualiser.barCustomColor
                    onTextModified: t => GlobalConfig.bar[root.edge].visualiser.barCustomColor = t
                }

                TextFieldRow {
                    Layout.fillWidth: true
                    label: qsTr("Colour 2")
                    placeholder: "#RRGGBB"
                    text: Config.bar[root.edge].visualiser.barCustomColor2
                    onTextModified: t => GlobalConfig.bar[root.edge].visualiser.barCustomColor2 = t
                }
            }

            SelectRow {
                Layout.fillWidth: true
                label: qsTr("Silence behaviour")
                subtext: qsTr("What to show when no audio is playing")
                menuItems: root.silenceBehaviorItems
                active: root.activeSilenceBehavior
                onSelected: item => GlobalConfig.bar[root.edge].visualiser.silenceBehavior = item.value
            }

            ToggleRow {
                Layout.fillWidth: true
                text: qsTr("Beat pulse")
                subtext: qsTr("Amplitude boost on each musical beat")
                checked: Config.bar[root.edge].visualiser.beatPulse
                onToggled: GlobalConfig.bar[root.edge].visualiser.beatPulse = checked
            }

            StepperRow {
                Layout.fillWidth: true
                visible: Config.bar[root.edge].visualiser.beatPulse
                label: qsTr("Pulse amount")
                subtext: qsTr("Amplitude boost applied on each beat (%)")
                value: Math.round(Config.bar[root.edge].visualiser.beatPulseAmount * 100)
                from: 10
                to: 200
                stepSize: 10
                onMoved: v => GlobalConfig.bar[root.edge].visualiser.beatPulseAmount = v / 100
            }

            StepperRow {
                Layout.fillWidth: true
                visible: Config.bar[root.edge].visualiser.beatPulse
                label: qsTr("Beat decay")
                subtext: qsTr("How fast the beat-pulse fades (ms)")
                value: Config.bar[root.edge].visualiser.beatDecay
                from: 50
                to: 500
                stepSize: 25
                onMoved: v => GlobalConfig.bar[root.edge].visualiser.beatDecay = v
            }
        }

        SettingsSection {
            title: qsTr("Interaction")

            SelectRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Click action")
                subtext: qsTr("What happens when clicking the visualiser")
                menuItems: root.clickActionItems
                active: root.activeClickAction
                onSelected: item => GlobalConfig.bar[root.edge].visualiser.clickAction = item.value
            }

            TextButton {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: Tokens.spacing.small
                type: TextButton.Tonal
                text: qsTr("Reset to defaults")
                onClicked: {
                    GlobalConfig.bar[root.edge].visualiser.resetToDefaults({
                        bars: 5,
                        barWidth: 8,
                        barLength: 40,
                        barRounding: 8,
                        barAmplitude: 100,
                        barSpacing: 2,
                        barColorMode: "solid",
                        barColorSource: "dynamic",
                        barCustomColor: "",
                        barCustomColor2: "",
                        fillMode: "outward",
                        beatPulse: false,
                        beatPulseAmount: 0.5,
                        tilt: 0.0,
                        smoothing: 50,
                        beatDecay: 100,
                        clickAction: "none",
                        silenceBehavior: "flat",
                    });
                }
            }
        }
    }
}
