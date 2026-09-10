pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property var barConfig
    required property bool vertical
    required property int activeWsId
    required property Repeater workspaces
    required property Item mask
    required property bool fullscreen

    // Cross-axis thickness of the pill (the bar's inner width minus the cell padding).
    readonly property real crossSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

    readonly property int currentWsIdx: {
        let i = activeWsId - 1;
        while (i < 0)
            i += root.barConfig.workspaces.shown;
        return i % root.barConfig.workspaces.shown;
    }

    property real leading: workspaces.count > 0 ? (workspaces.itemAt(currentWsIdx) as Workspace)?.mainPos ?? 0 : 0
    property real trailing: workspaces.count > 0 ? (workspaces.itemAt(currentWsIdx) as Workspace)?.mainPos ?? 0 : 0
    property real currentSize: workspaces.count > 0 ? (workspaces.itemAt(currentWsIdx) as Workspace)?.mainSize ?? 0 : 0
    property real offset: Math.min(leading, trailing)
    property real size: {
        const s = Math.abs(leading - trailing) + currentSize;
        if (root.barConfig.workspaces.activeTrail && lastWs > currentWsIdx) {
            const ws = workspaces.itemAt(lastWs) as Workspace;
            return ws ? Math.min(ws.mainPos + ws.mainSize - offset, s) : 0;
        }
        return s;
    }

    property int cWs
    property int lastWs

    onCurrentWsIdxChanged: {
        lastWs = cWs;
        cWs = currentWsIdx;
    }

    clip: true
    x: root.vertical ? 0 : offset + root.mask.x
    y: root.vertical ? offset + root.mask.y : 0
    implicitWidth: root.vertical ? crossSize : size
    implicitHeight: root.vertical ? size : crossSize
    radius: Tokens.rounding.full
    color: Colours.palette.m3primary

    Colouriser {
        source: root.mask
        sourceColor: Colours.palette.m3onSurface
        colorizationColor: Colours.palette.m3onPrimary

        // Shift the recoloured copy of the cells back by the pill offset so it lines up with
        // the real cells; centre it on the cross axis.
        x: root.vertical ? 0 : -parent.offset
        y: root.vertical ? -parent.offset : 0
        implicitWidth: root.mask.implicitWidth
        implicitHeight: root.mask.implicitHeight

        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
    }

    Behavior on leading {
        enabled: root.barConfig.workspaces.activeTrail

        EAnim {}
    }

    Behavior on trailing {
        enabled: root.barConfig.workspaces.activeTrail

        EAnim {
            duration: Tokens.anim.durations.normal * 2
        }
    }

    Behavior on currentSize {
        enabled: root.barConfig.workspaces.activeTrail

        EAnim {}
    }

    Behavior on offset {
        enabled: !root.barConfig.workspaces.activeTrail

        EAnim {}
    }

    Behavior on size {
        enabled: !root.barConfig.workspaces.activeTrail

        EAnim {}
    }

    component EAnim: Anim {
        type: Anim.Emphasized
    }
}
