pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property bool editMode

    readonly property int padding: Tokens.padding.medium
    readonly property string activeAddress: Hypr.activeToplevel?.address ?? ""

    readonly property string position: Config.dock.position
    readonly property bool isVertical: position === "left" || position === "right"

    // Cell count for the Grid's constrained axis. Undershooting wraps the dock onto a
    // second line, so this always reserves a cell for all three trailing buttons rather
    // than counting the visible ones — overshooting only leaves empty trailing cells.
    // Deliberately independent of both child visibility and config load order: the Grid is
    // measured while the dock is still hidden (to size the exclusive zone), and anything
    // that reads zero at that point would bake in a too-small dock.
    readonly property int buttonSlots: 3
    readonly property int stripCount: root.dockModel.length + root.buttonSlots

    // Everything the model derives from, kept as a binding so QML's own dependency
    // tracking finds it all. The rebuild it triggers is debounced, because a single app
    // launch can fire several toplevel events and each rebuild walks every desktop entry.
    readonly property string toplevelState: JSON.stringify(Hypr.toplevels.values.map(w => [w.address, w.lastIpcObject?.class ?? "", w.workspace?.name ?? ""]))
    readonly property var modelInputs: [root.toplevelState, DesktopEntries.applications.values.length, GlobalConfig.launcher.favouriteApps, GlobalConfig.launcher.hiddenApps, Config.dock.ignoredAppRegexes, Config.dock.showSeparator, Config.dock.showSpecialWorkspaceApps]

    property var dockModel: []

    onModelInputsChanged: rebuildTimer.restart()
    Component.onCompleted: root.rebuildModel()

    // Popout state, bubbled up to Panels which renders the popout as a sibling of the dock.
    // popoutCenter is the x of the target icon's centre, in this item's coordinates.
    property string popoutMode: ""
    property var popoutTarget: null
    property real popoutCenter: 0

    // Generation counter incremented on every new preview open. The exit handler captures
    // the current generation and only requests close if it still matches, preventing a stale
    // exit signal from closing a freshly-opened preview.
    property int _hoverGeneration: 0

    signal editModeRequested(bool active)
    signal closeGraceRequested
    signal popoutOpened

    function popoutRequested(mode: string, target: var, centerX: real): void {
        root.popoutMode = mode;
        root.popoutTarget = target;
        if (mode.length > 0) {
            root.popoutCenter = centerX;
            root.popoutOpened();
        }
    }

    function closePopout(): void {
        root.popoutRequested("", null, 0);
    }

    // Every rebuild produces fresh entry objects, and an open popout is still holding the one
    // it was opened with — including that entry's `toplevels` array, snapshotted at build
    // time. Closing a window from the menu would otherwise leave its row on screen until the
    // popout was reopened. Re-resolve the target by id, and give up on it once its app has
    // left the dock entirely.
    function rebuildModel(): void {
        root.dockModel = root.buildModel();

        if (!root.popoutTarget)
            return;

        const id = root.popoutTarget.id;
        const next = root.dockModel.find(d => !d.isSeparator && d.id === id) ?? null;
        // A preview with nothing left to preview has no reason to stay up; the menu still
        // offers New Instance and Pin, so closing the last window keeps it open.
        if (!next || (root.popoutMode === "preview" && next.toplevels.length === 0))
            root.closePopout();
        else
            root.popoutTarget = next;
    }

    // Classes the user never wants in the dock (shell surfaces, portals). Matched against
    // the lowercased class, since testRegexList is case sensitive.
    function isIgnoredClass(cls: string): bool {
        return Strings.testRegexList(Config.dock.ignoredAppRegexes, cls.toLowerCase());
    }

    function buildModel(): var {
        const byClass = ({});
        const runningOrder = [];
        for (const w of Hypr.toplevels.values) {
            if (!Config.dock.showSpecialWorkspaceApps && (w.workspace?.name ?? "").startsWith("special:"))
                continue;

            const cls = w.lastIpcObject?.class ?? "";
            if (!cls || root.isIgnoredClass(cls))
                continue;
            if (!byClass[cls]) {
                byClass[cls] = [];
                runningOrder.push(cls);
            }
            byClass[cls].push(w);
        }

        const allApps = DesktopEntries.applications.values;
        const favourites = GlobalConfig.launcher.favouriteApps;

        const result = [];
        const seenClasses = new Set();

        for (let i = 0; i < favourites.length; i++) {
            const entry = allApps.find(a => !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id) && Strings.testRegexList([favourites[i]], a.id));
            if (!entry)
                continue;

            const cls = entry.startupClass || entry.id;
            if (seenClasses.has(cls))
                continue;

            result.push({
                appClass: cls,
                entry: entry,
                toplevels: byClass[cls] ?? [],
                isPinned: true,
                // Index into favouriteApps, so a reorder can splice the stored patterns
                // themselves rather than regenerating the list and dropping entries that
                // currently resolve to no desktop file.
                patternIndex: i,
                id: entry.id
            });
            seenClasses.add(cls);
        }

        const pinnedCount = result.length;

        for (const cls of runningOrder) {
            if (!seenClasses.has(cls)) {
                // Resolve the desktop entry for running-only apps too. Without it their
                // `entry` is null, which silently disables Pin to Dock and New Instance —
                // and with no favourites configured, that is every icon in the dock.
                const entry = root.entryForClass(allApps, cls);
                result.push({
                    appClass: cls,
                    entry: entry,
                    toplevels: byClass[cls],
                    isPinned: false,
                    patternIndex: -1,
                    id: entry?.id ?? cls
                });
            }
        }

        // Divide pinned favourites from apps that merely happen to be running. Only worth
        // drawing when there is something on both sides of it.
        if (Config.dock.showSeparator && pinnedCount > 0 && result.length > pinnedCount)
            result.splice(pinnedCount, 0, root.separatorEntry());

        return result;
    }

    // Shaped like a real entry so delegates and the reorder maths can read it without
    // special-casing every field access.
    function separatorEntry(): var {
        return {
            appClass: "",
            entry: null,
            toplevels: [],
            isPinned: false,
            patternIndex: -1,
            id: "__separator__",
            isSeparator: true
        };
    }

    function entryForClass(allApps: var, cls: string): var {
        if (!cls)
            return null;

        const target = cls.toLowerCase();
        const visible = allApps.filter(a => !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id));
        return visible.find(a => (a.startupClass ?? "").toLowerCase() === target) ?? visible.find(a => a.id.toLowerCase() === target) ?? null;
    }

    // Reorders pinned apps. Dragging a running-but-unpinned app pins it at the drop position
    // instead — otherwise, with no favourites configured, every drop would be a silent no-op.
    function reorderPinned(from: int, to: int): void {
        const model = root.dockModel;
        const fromItem = model[from];
        const toItem = model[to];
        if (!fromItem || !toItem)
            return;
        // The separator itself is a layout artefact — it cannot be moved. Dropping onto it,
        // though, is a valid boundary: toItem.isPinned is false for it, same as an unpinned
        // running app, so the branches below already land the drop at apps.length — the end
        // of the pinned section — with no separator-specific casing needed.
        if (fromItem.isSeparator)
            return;

        const apps = [...GlobalConfig.launcher.favouriteApps];

        if (fromItem.isPinned) {
            const pattern = apps.splice(fromItem.patternIndex, 1)[0];
            // Removing shifts everything above `from` down one
            const target = toItem.isPinned ? toItem.patternIndex : apps.length;
            apps.splice(fromItem.patternIndex < target ? target - 1 : target, 0, pattern);
        } else {
            if (!fromItem.entry)
                return;
            apps.splice(toItem.isPinned ? toItem.patternIndex : apps.length, 0, Strings.exactPattern(fromItem.id));
        }

        GlobalConfig.launcher.favouriteApps = apps;
        // Rebuild synchronously rather than waiting out rebuildTimer's 100ms debounce — the
        // dragged DockItem has already reset its position, so a stale dockModel for that long
        // reads as the drop snapping back before the reorder catches up.
        root.rebuildModel();
    }

    function removeFromDock(appData: var): void {
        if (!appData.isPinned)
            return;

        const apps = [...GlobalConfig.launcher.favouriteApps];
        apps.splice(appData.patternIndex, 1);
        GlobalConfig.launcher.favouriteApps = apps;
    }

    function openLauncher(pin: bool): void {
        if (pin)
            LauncherIpc.pinMode = true;
        root.visibilities.launcher = true;
        root.visibilities.dock = false;
    }

    implicitWidth: contentRow.implicitWidth + padding * 2
    implicitHeight: contentRow.implicitHeight + padding * 2

    Timer {
        id: rebuildTimer

        interval: 100
        onTriggered: root.rebuildModel()
    }

    // A Grid rather than a Row/Column pair: it flows either way from one declaration, so
    // the delegate and its signal wiring are written once. Inline components would have
    // been the alternative, but they cannot reach ids declared outside themselves.
    Grid {
        id: contentRow

        anchors.centerIn: parent
        spacing: Config.dock.spacing

        // Only one of these constrains the flow; the other is left free to grow. Both are
        // computed rather than left at Grid's default of 4 columns.
        rows: root.isVertical ? root.stripCount : 1
        columns: root.isVertical ? 1 : root.stripCount

        // Replaces the per-item anchors a Row/Column would need — a positioner forbids
        // anchoring children to it.
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Repeater {
            model: root.dockModel

            DockItem {
                iconSize: Config.dock.iconSize
                isRunning: modelData.toplevels?.length > 0
                isActive: modelData.toplevels?.some(w => w.address === root.activeAddress) ?? false
                editMode: root.editMode
                isVertical: root.isVertical
                dockPosition: root.position

                // `center` is along the dock's main axis, so it maps onto whichever screen
                // coordinate the popout needs to line up with.
                onRightClicked: (data, center) => root.popoutRequested("menu", data, (root.isVertical ? contentRow.y : contentRow.x) + center)
                onHoverChanged: (data, center, hovered) => {
                    if (!Config.dock.showHoverPopout)
                        return;
                    if (hovered && (data.toplevels?.length ?? 0) > 0) {
                        root._hoverGeneration++;
                        root.popoutRequested("preview", data, (root.isVertical ? contentRow.y : contentRow.x) + center);
                    } else if (root.popoutMode === "preview" && root.popoutTarget?.id === data.id) {
                        const gen = root._hoverGeneration;
                        Qt.callLater(() => {
                            if (root._hoverGeneration === gen)
                                root.closeGraceRequested();
                        });
                    }
                }
                onRemoveRequested: data => root.removeFromDock(data)
                onDndReordered: (from, to) => root.reorderPinned(from, to)
                onActivated: {
                    if (Config.dock.hideOnActivate)
                        root.visibilities.dock = false;
                }
            }
        }

        MaterialIcon {
            visible: Config.dock.showPinButton
            text: "keep"
            color: Config.dock.pinned ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.large

            // Tilted when unpinned, upright when pinned — the same affordance ambxst uses.
            rotation: Config.dock.pinned ? 0 : 45

            Behavior on rotation {
                Anim {}
            }

            Behavior on color {
                CAnim {}
            }

            StateLayer {
                anchors.fill: parent
                radius: Tokens.rounding.full
                // Written on GlobalConfig, not the per-monitor attached Config, so the
                // pin persists globally rather than landing on a monitor overlay.
                onClicked: GlobalConfig.dock.pinned = !Config.dock.pinned
            }
        }

        MaterialIcon {
            visible: Config.dock.showAddButton
            text: "add"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.large

            StateLayer {
                anchors.fill: parent
                radius: Tokens.rounding.full
                onClicked: root.openLauncher(true)
            }
        }

        MaterialIcon {
            visible: Config.dock.showEditButton
            text: root.editMode ? "check" : "edit"
            color: root.editMode ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.large

            StateLayer {
                anchors.fill: parent
                radius: Tokens.rounding.full
                onClicked: root.editModeRequested(!root.editMode)
            }
        }
    }
}
