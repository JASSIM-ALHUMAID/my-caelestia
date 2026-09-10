pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.curves
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages.animation

PageBase {
    id: root

    title: qsTr("Animation")

    readonly property var tokenConfig: TokenConfig

    property int durationVersion: 0

    // Bumped when a curve changes so the list's thumbnails and "Modified" tags re-read
    property int curveVersion: 0

    // Duration definitions: [tokenName, label, min, max, default]
    readonly property list<var> durationDefs: [
        ["small", qsTr("Small"), 50, 500, 200],
        ["normal", qsTr("Normal"), 100, 1000, 400],
        ["large", qsTr("Large"), 200, 2000, 600],
        ["extraLarge", qsTr("Extra Large"), 500, 3000, 1000],
        ["expressiveFastSpatial", qsTr("Expressive Fast Spatial"), 100, 800, 350],
        ["expressiveDefaultSpatial", qsTr("Expressive Default Spatial"), 200, 1200, 500],
        ["expressiveSlowSpatial", qsTr("Expressive Slow Spatial"), 300, 1500, 650],
        ["expressiveFastEffects", qsTr("Expressive Fast Effects"), 50, 400, 150],
        ["expressiveDefaultEffects", qsTr("Expressive Default Effects"), 100, 500, 200],
        ["expressiveSlowEffects", qsTr("Expressive Slow Effects"), 150, 700, 300]
    ]

    // Curve definitions: [curveName, label]
    readonly property list<var> curveDefs: [
        ["standard", qsTr("Standard")],
        ["standardAccel", qsTr("Standard Accel")],
        ["standardDecel", qsTr("Standard Decel")],
        ["emphasized", qsTr("Emphasized")],
        ["emphasizedAccel", qsTr("Emphasized Accel")],
        ["emphasizedDecel", qsTr("Emphasized Decel")],
        ["expressiveFastSpatial", qsTr("Expressive Fast Spatial")],
        ["expressiveDefaultSpatial", qsTr("Expressive Default Spatial")],
        ["expressiveSlowSpatial", qsTr("Expressive Slow Spatial")],
        ["expressiveFastEffects", qsTr("Expressive Fast Effects")],
        ["expressiveDefaultEffects", qsTr("Expressive Default Effects")],
        ["expressiveSlowEffects", qsTr("Expressive Slow Effects")]
    ]

    // Animation type definitions: [typeName, label, curveToken, durationToken]
    readonly property list<var> typeDefs: [
        ["standard", qsTr("Standard"), "standard", "normal"],
        ["standardSmall", qsTr("Standard Small"), "standard", "small"],
        ["standardLarge", qsTr("Standard Large"), "standard", "large"],
        ["standardExtraLarge", qsTr("Standard Extra Large"), "standard", "extraLarge"],
        ["emphasized", qsTr("Emphasized"), "emphasized", "normal"],
        ["emphasizedSmall", qsTr("Emphasized Small"), "emphasized", "small"],
        ["emphasizedLarge", qsTr("Emphasized Large"), "emphasized", "large"],
        ["emphasizedExtraLarge", qsTr("Emphasized Extra Large"), "emphasized", "extraLarge"],
        ["fastSpatial", qsTr("Fast Spatial"), "expressiveFastSpatial", "expressiveFastSpatial"],
        ["defaultSpatial", qsTr("Default Spatial"), "expressiveDefaultSpatial", "expressiveDefaultSpatial"],
        ["slowSpatial", qsTr("Slow Spatial"), "expressiveSlowSpatial", "expressiveSlowSpatial"],
        ["fastEffects", qsTr("Fast Effects"), "expressiveFastEffects", "expressiveFastEffects"],
        ["defaultEffects", qsTr("Default Effects"), "expressiveDefaultEffects", "expressiveDefaultEffects"],
        ["slowEffects", qsTr("Slow Effects"), "expressiveSlowEffects", "expressiveSlowEffects"]
    ]

    // Reading the property registers it with the caller's binding; isModified alone is a
    // method call and would never re-evaluate.
    function isCurveModified(name: string): bool {
        root.tokenConfig.appearance.curves[name];
        return root.tokenConfig.appearance.curves.isModified(name);
    }

    function getDuration(name: string): real {
        const d = root.tokenConfig.appearance.animDurations;
        switch (name) {
        case "small": return d.small;
        case "normal": return d.normal;
        case "large": return d.large;
        case "extraLarge": return d.extraLarge;
        case "expressiveFastSpatial": return d.expressiveFastSpatial;
        case "expressiveDefaultSpatial": return d.expressiveDefaultSpatial;
        case "expressiveSlowSpatial": return d.expressiveSlowSpatial;
        case "expressiveFastEffects": return d.expressiveFastEffects;
        case "expressiveDefaultEffects": return d.expressiveDefaultEffects;
        case "expressiveSlowEffects": return d.expressiveSlowEffects;
        }
        return 0;
    }

    function setDuration(name: string, value: real): void {
        const d = root.tokenConfig.appearance.animDurations;
        switch (name) {
        case "small": d.small = value; break;
        case "normal": d.normal = value; break;
        case "large": d.large = value; break;
        case "extraLarge": d.extraLarge = value; break;
        case "expressiveFastSpatial": d.expressiveFastSpatial = value; break;
        case "expressiveDefaultSpatial": d.expressiveDefaultSpatial = value; break;
        case "expressiveSlowSpatial": d.expressiveSlowSpatial = value; break;
        case "expressiveFastEffects": d.expressiveFastEffects = value; break;
        case "expressiveDefaultEffects": d.expressiveDefaultEffects = value; break;
        case "expressiveSlowEffects": d.expressiveSlowEffects = value; break;
        }
        root.durationVersion++;
    }

    // Defaults come from the plugin (ConfigObject::captureDefaults), so this can't drift
    // from the values the shell actually ships with.
    function resetAll(): void {
        root.tokenConfig.appearance.animDurations.resetAllOptions();
        root.tokenConfig.appearance.curves.resetAllOptions();
        GlobalConfig.appearance.anim.durations.resetOption("scale");
        root.durationVersion++;
        root.curveVersion++;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // === Reset & Scale ===
        CollapsibleSection {
            Layout.fillWidth: true
            title: qsTr("Global Scale")
            expanded: true
            showBackground: true

            SliderRow {
                Layout.fillWidth: true
                first: true
                icon: "speed"
                label: qsTr("Duration scale")
                valueLabel: value.toFixed(2) + "x"
                value: GlobalConfig.appearance.anim.durations.scale
                to: 4.0
                onMoved: v => GlobalConfig.appearance.anim.durations.scale = v
            }

            ConnectedRect {
                Layout.fillWidth: true
                first: false
                last: true
                implicitHeight: resetRow.implicitHeight + resetRow.anchors.margins * 2

                RowLayout {
                    id: resetRow

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.largeIncreased
                    anchors.topMargin: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "restart_alt"
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Reset all animation settings to defaults")
                        font: Tokens.font.body.small
                    }

                    IconTextButton {
                        icon: "restart_alt"
                        text: qsTr("Reset")
                        type: IconTextButton.Tonal
                        onClicked: root.resetAll()
                    }
                }
            }
        }

        // === Duration Tokens ===
        CollapsibleSection {
            Layout.fillWidth: true
            title: qsTr("Duration Tokens")
            showBackground: true

            Repeater {
                model: root.durationDefs

                delegate: SliderRow {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    first: index === 0
                    last: index === root.durationDefs.length - 1
                    icon: "timer"
                    label: modelData[1]
                    valueLabel: Math.round(root.getDuration(modelData[0]) * (root.durationVersion >= 0 ? 1 : 1)) + "ms"
                    value: root.getDuration(modelData[0]) * (root.durationVersion >= 0 ? 1 : 1)
                    to: modelData[3]
                    onMoved: v => root.setDuration(modelData[0], Math.round(v))
                }
            }
        }

        // === Animation Types ===
        CollapsibleSection {
            Layout.fillWidth: true
            title: qsTr("Animation Types")
            showBackground: true

            Repeater {
                model: root.typeDefs

                delegate: ConnectedRect {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    first: index === 0
                    last: index === root.typeDefs.length - 1

                    implicitHeight: typeRow.implicitHeight + typeRow.anchors.margins * 2

                    RowLayout {
                        id: typeRow

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.largeIncreased
                        anchors.topMargin: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "animation"
                            font: Tokens.font.icon.medium
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: modelData[1]
                                font: Tokens.font.body.small
                            }

                            StyledText {
                                text: qsTr("Curve: %1 | Duration: %2").arg(modelData[2]).arg(modelData[3])
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                            }
                        }

                        IconButton {
                            icon: "edit"
                            type: IconButton.Tonal
                            onClicked: {
                                root.nState.selectedCurve = modelData[2];
                                root.nState.openSubPage(1);
                            }
                        }
                    }
                }
            }
        }

        // === Easing Curves ===
        CollapsibleSection {
            Layout.fillWidth: true
            title: qsTr("Easing Curves")
            showBackground: true

            Repeater {
                model: root.curveDefs

                delegate: ConnectedRect {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    first: index === 0
                    last: index === root.curveDefs.length - 1

                    implicitHeight: curveRow.implicitHeight + curveRow.anchors.margins * 2

                    RowLayout {
                        id: curveRow

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.largeIncreased
                        anchors.topMargin: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        // The curve's own shape reads faster than any label
                        BezierCanvas {
                            controlPoints: root.tokenConfig.appearance.curves[modelData[0]] ?? []
                            canvasSize: 30
                            padding: Tokens.padding.small
                            interactive: false
                            showGrid: false
                            showDiagonal: false
                            showHandles: false
                            color: "transparent"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData[1]
                                font: Tokens.font.body.small
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: root.isCurveModified(modelData[0])
                                text: qsTr("Modified")
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                            }
                        }

                        IconButton {
                            icon: "edit"
                            type: IconButton.Text
                            onClicked: {
                                root.nState.selectedCurve = modelData[0];
                                root.nState.openSubPage(1);
                            }
                        }
                    }
                }
            }
        }
    }
}
