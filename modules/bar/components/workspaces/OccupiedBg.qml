pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var barConfig
    required property bool vertical
    required property Repeater workspaces
    required property var occupied
    required property int groupOffset

    // Cross-axis thickness of the occupied pills.
    readonly property real crossSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2 + 2

    property list<var> pills: []

    onOccupiedChanged: {
        if (!occupied)
            return;
        let count = 0;
        const start = groupOffset;
        const end = start + barConfig.workspaces.shown;
        for (const [ws, occ] of Object.entries(occupied)) {
            if (ws > start && ws <= end && occ) {
                const isFirstInGroup = Number(ws) === start + 1;
                const isLastInGroup = Number(ws) === end;
                if (isFirstInGroup || !occupied[ws - 1]) {
                    if (pills[count])
                        pills[count].start = ws;
                    else
                        pills.push(pillComp.createObject(root, {
                            start: ws
                        }));
                    count++;
                }
                if ((isLastInGroup || !occupied[ws + 1]) && pills[count - 1])
                    pills[count - 1].end = ws;
            }
        }
        if (pills.length > count)
            pills.splice(count, pills.length - count).forEach(p => p.destroy());
    }

    Repeater {
        model: ScriptModel {
            values: root.pills.filter(p => p)
        }

        StyledRect {
            id: rect

            required property var modelData

            readonly property Workspace start: root.workspaces.count > 0 ? root.workspaces.itemAt(getWsIdx(modelData.start)) ?? null : null // qmllint disable incompatible-type
            readonly property Workspace end: root.workspaces.count > 0 ? root.workspaces.itemAt(getWsIdx(modelData.end)) ?? null : null // qmllint disable incompatible-type
            readonly property real span: start && end ? end.mainPos + end.mainSize - start.mainPos + 2 : 0

            function getWsIdx(ws: int): int {
                let i = ws - 1;
                while (i < 0)
                    i += root.barConfig.workspaces.shown;
                return i % root.barConfig.workspaces.shown;
            }

            x: root.vertical ? (root.width - width) / 2 : (start?.mainPos ?? 0) - 1
            y: root.vertical ? (start?.mainPos ?? 0) - 1 : (root.height - height) / 2
            implicitWidth: root.vertical ? root.crossSize : span
            implicitHeight: root.vertical ? span : root.crossSize

            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            radius: Tokens.rounding.full

            scale: 0
            Component.onCompleted: scale = 1

            Behavior on scale {
                Anim {
                    easing: Tokens.anim.standardDecel
                }
            }

            Behavior on x {
                Anim {}
            }

            Behavior on y {
                Anim {}
            }

            Behavior on implicitWidth {
                Anim {}
            }

            Behavior on implicitHeight {
                Anim {}
            }
        }
    }

    Component {
        id: pillComp

        Pill {}
    }

    component Pill: QtObject {
        property int start
        property int end
    }
}
