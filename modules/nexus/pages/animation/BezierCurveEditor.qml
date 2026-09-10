pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import qs.components.curves

PageBase {
    id: root

    property string curveName: nState.selectedCurve ?? "standard"
    property int curveVersion: 0

    readonly property var curves: TokenConfig.appearance.curves

    title: qsTr("Edit Curve: %1").arg(root.curveName)
    isSubPage: true

    // curveVersion forces a re-read after a write; the Connections below covers changes
    // made elsewhere, such as Reset all on the Animation page.
    readonly property list<real> points: {
        const _v = root.curveVersion;
        return root.curves[root.curveName] ?? [0.2, 0, 0, 1, 1, 1];
    }

    readonly property list<real> defaultPoints: root.curves.defaultOf(root.curveName) ?? []
    readonly property bool modified: root.curves.isModified(root.curveName) && (root.curveVersion >= 0)

    function setPoints(points: list<real>): void {
        root.curves[root.curveName] = points;
        root.curveVersion++;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        // Picks up changes made elsewhere, e.g. Reset all on the Animation page.
        // Lives inside the layout because PageBase's default property takes one Item.
        Connections {
            target: root.curves

            function onPropertiesChanged(): void {
                root.curveVersion++;
            }
        }

        BezierCanvas {
            id: canvas

            Layout.alignment: Qt.AlignHCenter
            canvasSize: Math.min(root.cappedWidth - Tokens.padding.large * 4, 340)
            controlPoints: root.points
            curveColor: Colours.palette.m3primary
            progress: preview.progress

            onPointsEdited: points => root.setPoints(points)
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Drag the handles to reshape the curve")
            font: Tokens.font.label.small
            color: Colours.palette.m3outline
        }

        SectionHeader {
            text: qsTr("Preview")
        }

        EasingPreview {
            id: preview

            Layout.fillWidth: true
            controlPoints: root.points
        }

        SectionHeader {
            text: qsTr("Control points")
        }

        Repeater {
            model: Math.floor(root.points.length / 2)

            delegate: ConnectedRect {
                id: pointRow

                required property int index

                // The last point is the curve's endpoint, which QEasingCurve requires to
                // stay at (1, 1) — shown for completeness but not editable.
                readonly property bool locked: index === Math.floor(root.points.length / 2) - 1

                Layout.fillWidth: true
                first: index === 0
                last: index === Math.floor(root.points.length / 2) - 1
                implicitHeight: pointLayout.implicitHeight + pointLayout.anchors.margins * 2

                RowLayout {
                    id: pointLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    StyledText {
                        Layout.minimumWidth: 88
                        text: pointRow.locked ? qsTr("End") : qsTr("Point %1").arg(pointRow.index + 1)
                        font: Tokens.font.body.small
                        color: pointRow.locked ? Colours.palette.m3outline : Colours.palette.m3onSurface
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: qsTr("X")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                    }

                    CustomSpinBox {
                        enabled: !pointRow.locked
                        min: 0
                        max: 1
                        step: 0.01
                        fieldWidth: 78
                        value: root.points[pointRow.index * 2]
                        textFormatter: v => v.toFixed(2)
                        onValueModified: v => {
                            const next = [...root.points];
                            next[pointRow.index * 2] = v;
                            root.setPoints(next);
                        }
                    }

                    StyledText {
                        text: qsTr("Y")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                    }

                    CustomSpinBox {
                        enabled: !pointRow.locked
                        // Y is deliberately unbounded past 0..1: the expressive curves
                        // overshoot (cp y up to 1.67) and that has to stay editable.
                        min: -2
                        max: 3
                        step: 0.01
                        fieldWidth: 78
                        value: root.points[pointRow.index * 2 + 1]
                        textFormatter: v => v.toFixed(2)
                        onValueModified: v => {
                            const next = [...root.points];
                            next[pointRow.index * 2 + 1] = v;
                            root.setPoints(next);
                        }
                    }
                }
            }
        }

        IconTextButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.medium
            icon: "restart_alt"
            text: qsTr("Reset to default")
            type: IconTextButton.Tonal
            enabled: root.modified
            onClicked: {
                root.curves.resetOption(root.curveName);
                root.curveVersion++;
            }
        }
    }
}
