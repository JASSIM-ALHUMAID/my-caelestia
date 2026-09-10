pragma ComponentBehavior: Bound

import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import "components/dock"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

GridLayout {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    // The per-edge BarEdgeConfig for this bar (var: subobjects are QML_ANONYMOUS).
    required property var barConfig
    required property string edge
    readonly property int vPadding: Tokens.padding.large

    // Default to vertical for any unknown/empty edge so the bar can never collapse to nothing
    readonly property bool vertical: edge !== "top" && edge !== "bottom"
    readonly property bool inverted: edge === "top" || edge === "right"

    readonly property var targetMonitor: GlobalConfig.bar.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor
    readonly property string specialWorkspaceName: root.barConfig.dock.showSpecialWorkspaceApps ? (root.targetMonitor?.lastIpcObject?.specialWorkspace?.name ?? "") : ""
    readonly property var entryWorkspace: {
        if (root.specialWorkspaceName)
            return Hypr.workspaces.values.find(ws => ws.name === root.specialWorkspaceName) ?? null;
        return GlobalConfig.bar.perMonitorWorkspaces ? (root.targetMonitor?.activeWorkspace ?? null) : Hypr.focusedWorkspace;
    }
    readonly property var entryToplevel: {
        if (!root.specialWorkspaceName)
            return Hypr.activeToplevel;
        const active = Hypr.activeToplevel;
        if (active?.workspace?.name === root.specialWorkspaceName)
            return active;
        return root.entryWorkspace?.toplevels.values[0] ?? null;
    }

    function closeTray(): void {
        if (!root.barConfig.tray.compact)
            return;

        for (let i = 0; i < repeater.count; i++) {
            const loader = repeater.itemAt(i) as WrappedLoader;
            if (loader?.entryEnabled && loader.entryId === "tray") {
                (loader.item as Tray).expanded = false;
            }
        }
    }

    // `pos` is the cursor position along the bar's main axis (y when vertical, x when
    // horizontal). Entry loaders and the overflow button both carry an `id`.
    function childAtMain(pos: real): Item {
        return vertical ? childAt(width / 2, pos) : childAt(pos, height / 2);
    }

    // Center of `item` (mapped into root) along the main axis
    function mainCenter(item: Item): real {
        const c = item.mapToItem(root, item.implicitWidth / 2, item.implicitHeight / 2);
        return vertical ? c.y : c.x;
    }

    function checkPopout(pos: real): void {
        const ch = childAtMain(pos);

        if (ch?.entryId !== "tray")
            closeTray();

        if (!ch) {
            popouts.closeDeferred();
            return;
        }

        const id = ch.entryId;

        if (id === "statusIcons" && root.barConfig.popouts.statusIcons) {
            const items = (ch.item as StatusIcons).items;
            const mapped = mapToItem(items, vertical ? 0 : pos, vertical ? pos : 0);
            const icon = vertical ? items.childAt(items.width / 2, mapped.y) : items.childAt(mapped.x, items.height / 2);
            if (icon) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => root.mainCenter(icon));
                popouts.open();
            }
        } else if (id === "tray" && root.barConfig.popouts.tray) {
            const tray = ch.item as Tray;
            const onExpandIcon = tray.expandIcon.contains(mapToItem(tray.expandIcon, vertical ? tray.implicitWidth / 2 : pos, vertical ? pos : tray.implicitHeight / 2));
            if (!root.barConfig.tray.compact || (tray.expanded && !onExpandIcon)) {
                // Pick the tray item nearest the cursor along the main axis. Mirrors the dock
                // branch: a continuous index/childAt hit-test flickers the popout on/off (and
                // rebuilds the menu) across the gaps between icons.
                let trayItem = null;
                let bestIndex = -1;
                let bestDist = Infinity;
                for (let i = 0; i < tray.items.count; i++) {
                    const it = tray.items.itemAt(i);
                    if (!it)
                        continue;
                    const d = Math.abs(pos - mainCenter(it));
                    if (d < bestDist) {
                        bestDist = d;
                        trayItem = it;
                        bestIndex = i;
                    }
                }
                // Leave any open popout in place on a transient miss (like statusIcons) so
                // traversal never toggles hasCurrent off and back on.
                if (trayItem) {
                    popouts.currentName = `traymenu${bestIndex}`;
                    popouts.currentCenter = Qt.binding(() => root.mainCenter(trayItem));
                    popouts.open();
                }
            } else {
                popouts.hasCurrent = false;
                tray.expanded = true;
            }
        } else if (id === "activeWindow" && root.barConfig.popouts.activeWindow && root.barConfig.activeWindow.showOnHover) {
            popouts.activeWindowToplevel = Qt.binding(() => root.entryToplevel);
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = mainCenter(ch.item as Item) ?? 0;
            popouts.open();
        } else if (id === "layoutSelector") {
            popouts.currentName = "layoutpicker";
            popouts.currentCenter = mainCenter(ch.item as Item) ?? 0;
            popouts.open();
        } else if (id === "timer") {
            popouts.currentName = "timer";
            popouts.currentCenter = mainCenter(ch.item as Item) ?? 0;
            popouts.open();
        } else if (id === "overflow") {
            // Re-bind the centre: the button shifts as the bar reflows behind the popout
            popouts.overflowEntries = root.overflow.movedEntries;
            popouts.overflowBarConfig = root.barConfig;
            popouts.overflowVertical = root.vertical;
            popouts.overflowEdge = root.edge;
            popouts.overflowVisibilities = root.visibilities;
            popouts.currentName = "baroverflow";
            popouts.currentCenter = Qt.binding(() => root.mainCenter(ch));
            popouts.open();
        } else if (id === "dock") {
            const dock = ch.item as Dock;
            // Pick the icon nearest the cursor along the main axis. Using childAt would miss
            // the spacing gaps between icons and make the popout flicker on/off.
            let icon = null;
            let bestDist = Infinity;
            for (let i = 0; i < dock.items.count; i++) {
                const it = dock.items.itemAt(i) as DockApp;
                if (!it?.toplevel)
                    continue;
                const c = mainCenter(it);
                const d = Math.abs(pos - c);
                if (d < bestDist) {
                    bestDist = d;
                    icon = it;
                }
            }
            if (icon) {
                popouts.currentName = "dock";
                popouts.dockToplevel = icon.toplevel;
                popouts.currentCenter = Qt.binding(() => root.mainCenter(icon));
                popouts.open();
            } else {
                popouts.closeDeferred();
            }
        }
    }

    function handleWheel(pos: real, angleDelta: point): void {
        const ch = childAtMain(pos);
        if (ch?.entryId === "workspaces" && root.barConfig.scrollActions.workspaces) {
            // Workspace scroll
            const mon = (GlobalConfig.bar.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.toggleSpecialWorkspace(specialWs.slice(8));
            else if (angleDelta.y < 0 || (GlobalConfig.bar.perMonitorWorkspaces ? mon.activeWorkspace?.id : Hypr.activeWsId) > 1)
                Hypr.switchWorkspace(`r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if (pos < (vertical ? screen.height : screen.width) / 2 && root.barConfig.scrollActions.volume) {
            // Volume scroll on leading half (top when vertical, left when horizontal)
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (root.barConfig.scrollActions.brightness) {
            // Brightness scroll on trailing half (bottom when vertical, right when horizontal)
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
        }
    }

    readonly property int spacing: Tokens.spacing.medium

    readonly property alias entryRepeater: repeater
    // Main-axis slot the overflow button occupies, for the budget's own bookkeeping
    readonly property real overflowButtonSize: overflowButton.implicitHeight

    readonly property BarOverflowState overflow: BarOverflowState {
        bar: root
        barConfig: root.barConfig
    }

    flow: vertical ? GridLayout.LeftToRight : GridLayout.TopToBottom
    columns: 1
    rows: 1
    rowSpacing: spacing
    columnSpacing: spacing

    Repeater {
        id: repeater

        model: root.barConfig.entries

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: WrappedLoader {
                    Layout.fillHeight: entryEnabled && root.vertical
                    Layout.fillWidth: entryEnabled && !root.vertical
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: WrappedLoader {
                    id: logoEntry

                    sourceComponent: OsIcon {
                        variant: root.barConfig.entries[logoEntry.index]?.variant ?? "auto"
                    }
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: WrappedLoader {
                    sourceComponent: Workspaces {
                        screen: root.screen
                        fullscreen: root.fullscreen
                        vertical: root.vertical
                        barConfig: root.barConfig
                        iconLimit: root.overflow.wsIconLimit
                    }
                }
            }
            DelegateChoice {
                roleValue: "dock"
                delegate: WrappedLoader {
                    shown: !root.fullscreen
                    sourceComponent: Dock {
                        screen: root.screen
                        vertical: root.vertical
                        barConfig: root.barConfig
                        workspaceId: root.entryWorkspace?.id ?? -1
                        activeToplevel: Hypr.activeToplevel
                        itemLimit: root.overflow.dockLimit
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: WrappedLoader {
                    Layout.fillWidth: root.vertical
                    Layout.fillHeight: !root.vertical
                    shown: !root.fullscreen
                    sourceComponent: ActiveWindow {
                        bar: root
                        barConfig: root.barConfig
                        toplevel: root.entryToplevel
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: WrappedLoader {
                    shown: !root.fullscreen
                    sourceComponent: Tray {
                        vertical: root.vertical
                        barConfig: root.barConfig
                        itemLimit: root.overflow.trayLimit
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: WrappedLoader {
                    shown: !root.fullscreen
                    sourceComponent: Clock {
                        barConfig: root.barConfig
                        vertical: root.vertical
                    }
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: WrappedLoader {
                    shown: !root.fullscreen
                    sourceComponent: StatusIcons {
                        barConfig: root.barConfig
                        vertical: root.vertical
                    }
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: WrappedLoader {
                    sourceComponent: Power {
                        visibilities: root.visibilities
                    }
                }
            }
            DelegateChoice {
                roleValue: "wallpaperAdvance"
                delegate: WrappedLoader {
                    sourceComponent: WallpaperAdvance {}
                }
            }
            DelegateChoice {
                roleValue: "layoutSelector"
                delegate: WrappedLoader {
                    sourceComponent: LayoutSelector {}
                }
            }
            DelegateChoice {
                roleValue: "timer"
                delegate: WrappedLoader {
                    shown: !root.fullscreen
                    sourceComponent: TimerEntry {
                        vertical: root.vertical
                    }
                }
            }
            DelegateChoice {
                roleValue: "barPin"
                delegate: WrappedLoader {
                    sourceComponent: BarPin {
                        barConfig: root.barConfig
                        edge: root.edge
                    }
                }
            }
            DelegateChoice {
                roleValue: "visualiser"
                delegate: WrappedLoader {
                    Layout.fillWidth: root.vertical
                    Layout.fillHeight: !root.vertical
                    // Drop out of the layout once the silence fade has finished, so a
                    // hidden visualiser doesn't reserve its length (and spacing) in the bar
                    shown: !((item as BarVisualiser)?.collapsed ?? false)
                    sourceComponent: BarVisualiser {
                        barConfig: root.barConfig
                        vertical: root.vertical
                        inverted: root.inverted
                        popouts: root.popouts
                    }
                }
            }
        }
    }

    // Opens the popout holding the entries that didn't fit. Always last in the layout, so it
    // takes the trailing edge padding while it's around.
    MaterialIcon {
        id: overflowButton

        // Matches the `id` convention of the entry loaders, for checkPopout's dispatch
        readonly property string entryId: "overflow"

        Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
        Layout.topMargin: root.vertical && root.findFirstVisible() === this ? root.vPadding + root.barConfig.startCornerPadding : 0
        Layout.bottomMargin: root.vertical && root.findLastVisible() === this ? root.vPadding + root.barConfig.endCornerPadding : 0
        Layout.leftMargin: !root.vertical && root.findFirstVisible() === this ? root.vPadding + root.barConfig.startCornerPadding : 0
        Layout.rightMargin: !root.vertical && root.findLastVisible() === this ? root.vPadding + root.barConfig.endCornerPadding : 0

        visible: root.overflow.movedIndices.length > 0
        text: root.barConfig.overflow.icon || "more_horiz"
        color: Colours.palette.m3onSurface
        fill: 1
    }

    // First/last item actually drawn in the bar, so the edge padding follows what the user
    // sees rather than what is merely configured (entries hide on fullscreen, the visualiser
    // collapses on silence, and entries move into the overflow popout).
    function findFirstVisible(): Item {
        const count = repeater.count;
        for (let i = 0; i < count; i++) {
            const item = repeater.itemAt(i);
            if (item?.visible)
                return item;
        }
        return overflowButton.visible ? overflowButton : null;
    }

    function findLastVisible(): Item {
        if (overflowButton.visible)
            return overflowButton;
        for (let i = repeater.count - 1; i >= 0; i--) {
            const item = repeater.itemAt(i);
            if (item?.visible)
                return item;
        }
        return null;
    }

    component WrappedLoader: Loader {
        id: wrapped

        required property var modelData
        required property int index

        readonly property string entryId: modelData.id
        readonly property bool entryEnabled: modelData.enabled ?? true

        // Hidden for a reason unrelated to overflow (fullscreen, visualiser silence).
        // Delegates override this rather than `visible`.
        property bool shown: true
        // Whether this entry counts toward the overflow budget. Deliberately excludes
        // `inOverflow`, which is that budget's own output.
        readonly property bool counted: entryEnabled && shown
        readonly property bool inOverflow: root.overflow.movedIndices.includes(index)

        asynchronous: true
        Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter

        Layout.topMargin: root.vertical && root.findFirstVisible() === this ? root.vPadding + root.barConfig.startCornerPadding : 0
        Layout.bottomMargin: root.vertical && root.findLastVisible() === this ? root.vPadding + root.barConfig.endCornerPadding : 0
        Layout.leftMargin: !root.vertical && root.findFirstVisible() === this ? root.vPadding + root.barConfig.startCornerPadding : 0
        Layout.rightMargin: !root.vertical && root.findLastVisible() === this ? root.vPadding + root.barConfig.endCornerPadding : 0

        visible: counted && !inOverflow
        active: entryEnabled
    }
}
