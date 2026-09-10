pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

StyledClippingRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen
    required property bool vertical
    required property var barConfig

    readonly property bool onSpecial: (GlobalConfig.bar.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor)?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: GlobalConfig.bar.perMonitorWorkspaces ? (Hypr.monitorFor(screen).activeWorkspace?.id ?? 1) : Hypr.activeWsId

    readonly property var occupied: {
        const occ = {};
        for (const ws of Hypr.workspaces.values)
            occ[ws.id] = ws.lastIpcObject.windows > 0;
        return occ;
    }
    readonly property int groupOffset: Math.floor((activeWsId - 1) / root.barConfig.workspaces.shown) * root.barConfig.workspaces.shown

    // --- Overflow budget -------------------------------------------------------------
    // Everything below is derived from model counts and tokens only, never from our own
    // laid-out geometry, so the bar's overflow budget can read it without the cap it
    // computes feeding back into the size it measured. See modules/bar/BarOverflowState.qml.

    // Max window icons per cell; -1 means unlimited (no cap in effect)
    property int iconLimit: -1
    readonly property int effectiveMaxWindowIcons: {
        const configured = root.barConfig.workspaces.maxWindowIcons;
        if (root.iconLimit < 0)
            return configured;
        return configured > 0 ? Math.min(configured, root.iconLimit) : root.iconLimit;
    }

    // Uncapped window count per shown cell, mirroring Workspace.hasWindows
    readonly property var windowCounts: {
        const counts = [];
        const shown = root.barConfig.workspaces.shown;
        const ws = root.barConfig.workspaces;
        for (let i = 0; i < shown; i++) {
            const id = root.groupOffset + i + 1;
            const hasWindows = (root.occupied[id] ?? false) && ws.showWindows && (ws.showWindowsOnActive !== false || root.activeWsId !== id);
            counts.push(hasWindows ? Hypr.toplevels.values.filter(c => c.workspace?.id === id).length : 0);
        }
        return counts;
    }

    // Main-axis cost of one window icon (Workspace stacks them with spacing 0)
    readonly property real iconUnit: root.vertical ? iconMetric.implicitHeight : iconMetric.implicitWidth
    // Main-axis cost of a cell's number/shape slot
    readonly property real cellUnit: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2
    // Fixed extra a cell picks up once it shows any windows (Workspace.size + the overlap margin)
    readonly property real cellWindowExtra: Tokens.padding.small - Tokens.sizes.bar.innerWidth / 10

    // Gap between the window icons stacked in one cell; costs a gap per icon past the first
    readonly property real iconGap: root.barConfig.workspaces.windowIconSpacing

    // Main-axis size this entry would take with no icon limit applied
    readonly property real intrinsicMain: {
        const counts = root.windowCounts;
        let total = Tokens.padding.small * 2 + Math.floor(Tokens.spacing.extraSmall) * Math.max(0, counts.length - 1);
        for (let i = 0; i < counts.length; i++) {
            total += root.cellUnit;
            if (counts[i] > 0)
                total += counts[i] * root.iconUnit + (counts[i] - 1) * root.iconGap + root.cellWindowExtra;
        }
        return total;
    }

    // Main axis saved by limiting each cell to `limit` icons
    function mainSavedBy(limit: int): real {
        if (limit < 0)
            return 0;
        const counts = root.windowCounts;
        const configured = root.barConfig.workspaces.maxWindowIcons;
        const cap = configured > 0 ? Math.min(configured, limit) : limit;
        let saved = 0;
        for (let i = 0; i < counts.length; i++) {
            const shownNow = configured > 0 ? Math.min(counts[i], configured) : counts[i];
            // Each dropped icon takes its preceding gap with it
            saved += Math.max(0, shownNow - cap) * (root.iconUnit + root.iconGap);
        }
        return saved;
    }

    property real blur: onSpecial ? 1 : 0

    // Never shown; only its implicit size is read, as the per-icon budget unit
    MaterialIcon {
        id: iconMetric

        visible: false
        grade: 0
        text: "terminal"
    }

    // Cross axis is fixed to the bar thickness; main axis grows with the workspace cells.
    implicitWidth: vertical ? Tokens.sizes.bar.innerWidth : layout.implicitWidth + Tokens.padding.small * 2
    implicitHeight: vertical ? layout.implicitHeight + Tokens.padding.small * 2 : Tokens.sizes.bar.innerWidth

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: !root.fullscreen

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        Loader {
            asynchronous: true
            active: root.barConfig.workspaces.occupiedBg

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall

            sourceComponent: OccupiedBg {
                workspaces: workspaces
                occupied: root.occupied
                groupOffset: root.groupOffset
                barConfig: root.barConfig
                vertical: root.vertical
            }
        }

        GridLayout {
            id: layout

            flow: root.vertical ? GridLayout.LeftToRight : GridLayout.TopToBottom
            columns: 1
            rows: 1

            anchors.centerIn: parent
            rowSpacing: Math.floor(Tokens.spacing.extraSmall)
            columnSpacing: Math.floor(Tokens.spacing.extraSmall)

            Repeater {
                id: workspaces

                model: root.barConfig.workspaces.shown

                Workspace {
                    activeWsId: root.activeWsId
                    occupied: root.occupied
                    groupOffset: root.groupOffset
                    barConfig: root.barConfig
                    vertical: root.vertical
                    iconLimit: root.effectiveMaxWindowIcons
                }
            }
        }

        Loader {
            asynchronous: true
            // Centre on the cross axis only (no fill) so the indicator keeps its pill size;
            // it positions itself along the main axis.
            anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
            active: root.barConfig.workspaces.activeIndicator

            sourceComponent: ActiveIndicator {
                activeWsId: root.activeWsId
                workspaces: workspaces
                mask: layout
                fullscreen: root.fullscreen
                barConfig: root.barConfig
                vertical: root.vertical
            }
        }

        // Draw real app icons on top of the active indicator so the Colouriser (which
        // flattens images to a solid colour) never blackens them, including while the
        // active pill slides between workspaces.
        Loader {
            anchors.fill: layout
            z: 100
            active: root.barConfig.workspaces.appIcons && root.barConfig.workspaces.showWindows

            sourceComponent: Repeater {
                model: root.barConfig.workspaces.shown

                delegate: Item {
                    id: ovCell

                    required property int index
                    readonly property Workspace wsItem: workspaces.itemAt(index) as Workspace

                    visible: ovCell.wsItem?.hasWindows ?? false
                    x: ovCell.wsItem?.x ?? 0
                    y: ovCell.wsItem?.y ?? 0
                    width: ovCell.wsItem?.width ?? 0
                    height: ovCell.wsItem?.height ?? 0

                    // Mirror the in-cell window stack: below the number when vertical, beside it
                    // when horizontal. Offset along the main axis past the number's slot.
                    readonly property real winOffset: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2 - Tokens.sizes.bar.innerWidth / 10

                    Grid {
                        id: ovStack

                        flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
                        columns: root.vertical ? 1 : -1
                        rows: root.vertical ? -1 : 1
                        // Must track the in-cell stack in Workspace.qml, or the real icons
                        // drift out of register with the shapes underneath them.
                        spacing: root.barConfig.workspaces.windowIconSpacing

                        // Centre on the cross axis within the cell; offset past the number on the main axis.
                        x: root.vertical ? (ovCell.width - width) / 2 : ovCell.winOffset
                        y: root.vertical ? ovCell.winOffset : (ovCell.height - height) / 2

                        Repeater {
                            model: ScriptModel {
                                values: {
                                    const wsId = ovCell.wsItem?.ws ?? -1;
                                    const wins = Hypr.toplevels.values.filter(c => c.workspace?.id === wsId);
                                    const maxIcons = root.effectiveMaxWindowIcons;
                                    return maxIcons > 0 ? wins.slice(0, maxIcons) : wins;
                                }
                            }

                            WindowIcon {
                                required property var modelData

                                toplevel: modelData
                                barConfig: root.barConfig
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: layout
            onClicked: event => {
                const ws = (layout.childAt(event.x, event.y) as Workspace)?.ws;
                if (Hypr.activeWsId !== ws)
                    Hypr.switchWorkspace(`${ws}`);
                else
                    Hypr.toggleSpecialWorkspace("special");
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: specialWs

        asynchronous: true

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall

        active: opacity > 0

        scale: root.onSpecial ? 1 : 0.5
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: SpecialWorkspaces {
            screen: root.screen
            barConfig: root.barConfig
            vertical: root.vertical
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }
}
