pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config

// Decides what the bar gives up when its entries no longer fit along the screen edge.
//
// Qt Quick Layouts fix a non-filling item to its preferred size, so without this the rigid
// entries just run past the end of the bar and get clipped by BarWrapper. Only `spacer` and
// `activeWindow` yield their main-axis length, and they do so before anything is capped.
//
// LOOP SAFETY, the central constraint here: a limit must never be derived from the laid-out
// geometry of the entry it caps, or capping frees budget, which lifts the cap, which eats it
// again. So the capped entries (workspaces/tray/dock) are measured through their own
// `intrinsicMain` — computed from model counts and tokens, independent of any limit — while
// every other entry may be measured off its loader's implicit size, which no limit touches.
QtObject {
    id: root

    // The Bar (GridLayout) root
    required property var bar
    required property var barConfig

    readonly property string mode: root.barConfig.overflow.mode || "none"
    readonly property bool enabled: mode === "cap" || mode === "popout"

    // Entries that can move into the overflow popout: self-contained, no hover-routed popout
    // of their own, and rigid enough that moving them actually frees space. Everything else
    // (tray, statusIcons, dock, workspaces, activeWindow) stays put and is capped instead.
    readonly property var movableIds: ["logo", "clock", "power", "barPin", "layoutSelector", "wallpaperAdvance", "timer"]
    // Entries that give up their main-axis length on demand, so they contribute nothing to the
    // minimum the bar must fit. `spacer` fills the main axis; `activeWindow` elides its title to
    // whatever is left over, and must stay here for loop safety besides — its implicit size is
    // derived from the other entries' laid-out sizes, so measuring it would feed caps back into
    // the budget that produced them.
    //
    // `visualiser` is deliberately NOT here. It fills only the cross axis in both orientations
    // (Bar.qml: `Layout.fillWidth: root.vertical`), so its main-axis length is the rigid
    // implicit size of its bar stack — 182px for a 14-bar visualiser. Counting it as elastic
    // hid that from the budget entirely and no cap ever fired.
    readonly property var elasticIds: ["spacer", "activeWindow"]
    readonly property var cappedIds: ["workspaces", "tray", "dock"]

    // Main-axis length the entries have to fit into
    readonly property real available: {
        const main = root.bar.vertical ? root.bar.height : root.bar.width;
        return main - root.bar.vPadding * 2 - root.barConfig.startCornerPadding - root.barConfig.endCornerPadding;
    }

    // Single pass, so the four outputs below can't disagree with each other.
    readonly property var plan: {
        const empty = {
            wsIconLimit: -1,
            dockLimit: -1,
            trayLimit: -1,
            moved: []
        };

        const repeater = root.bar.entryRepeater;
        if (!root.enabled || !repeater || root.available <= 0)
            return empty;

        // Gather the entries that are in the bar and what each one costs along the main axis.
        // `counted` deliberately ignores whether an entry moved into the overflow popout —
        // reading `visible` here would make this binding depend on its own result.
        const items = [];
        let required = 0;
        for (let i = 0; i < repeater.count; i++) {
            const loader = repeater.itemAt(i);
            if (!loader?.counted)
                continue;
            const id = loader.id;
            let size = 0;
            if (root.elasticIds.includes(id)) {
                size = 0;
            } else if (root.cappedIds.includes(id)) {
                size = loader.item?.intrinsicMain ?? 0;
            } else {
                size = root.bar.vertical ? loader.implicitHeight : loader.implicitWidth;
            }
            items.push({
                index: i,
                id: id,
                size: size,
                item: loader.item
            });
            required += size;
        }
        if (items.length === 0)
            return empty;

        required += root.bar.spacing * (items.length - 1);

        let deficit = required - root.available;
        if (deficit <= 0)
            return empty;

        const result = {
            wsIconLimit: -1,
            dockLimit: -1,
            trayLimit: -1,
            moved: []
        };

        // 1. Move self-contained entries into the popout, from the end backwards
        if (root.mode === "popout") {
            for (let i = items.length - 1; i >= 0 && deficit > 0; i--) {
                const entry = items[i];
                if (!root.movableIds.includes(entry.id))
                    continue;
                result.moved.push(entry.index);
                deficit -= entry.size + root.bar.spacing;
            }
            // The overflow button itself takes a slot back
            if (result.moved.length > 0)
                deficit += root.bar.overflowButtonSize + root.bar.spacing;
        }

        // 2..4. Cap the greedy entries, in escalating order of how much it costs the user
        const overflow = root.barConfig.overflow;
        deficit = root.applyCap(items, "workspaces", deficit, Math.max(1, overflow.minWindowIcons), (item, limit) => item.mainSavedBy(limit), item => {
            const counts = item.windowCounts;
            let most = 0;
            for (let i = 0; i < counts.length; i++)
                most = Math.max(most, counts[i]);
            const configured = item.barConfig.workspaces.maxWindowIcons;
            return configured > 0 ? Math.min(most, configured) : most;
        }, limit => result.wsIconLimit = limit);

        deficit = root.applyCap(items, "dock", deficit, Math.max(1, overflow.minDockIcons), (item, limit) => Math.max(0, item.allGroups.length - limit) * item.itemUnit, item => item.allGroups.length, limit => result.dockLimit = limit);

        deficit = root.applyCap(items, "tray", deficit, Math.max(1, overflow.minTrayIcons), (item, limit) => Math.max(0, item.trayItems.length - limit) * item.itemUnit, item => item.trayItems.length, limit => result.trayLimit = limit);

        return result;
    }

    // Largest limit for `id` that still covers `deficit`; returns what's left of the deficit.
    // `saved(item, limit)` is the main axis freed by that limit, `full(item)` the uncapped
    // item count, `assign(limit)` records the winner.
    function applyCap(items: var, id: string, deficit: real, floor: int, saved: var, full: var, assign: var): real {
        if (deficit <= 0)
            return deficit;
        const entry = items.find(e => e.id === id);
        if (!entry?.item)
            return deficit;

        const count = full(entry.item);
        for (let limit = count - 1; limit >= floor; limit--) {
            const freed = saved(entry.item, limit);
            if (freed >= deficit) {
                assign(limit);
                return 0;
            }
            if (limit === floor) {
                assign(limit);
                return deficit - freed;
            }
        }
        return deficit;
    }

    readonly property int wsIconLimit: plan.wsIconLimit
    readonly property int dockLimit: plan.dockLimit
    readonly property int trayLimit: plan.trayLimit
    // Indices into barConfig.entries of the entries that moved into the overflow popout
    readonly property var movedIndices: plan.moved
    readonly property var movedEntries: {
        const entries = root.barConfig.entries;
        return root.movedIndices.map(i => entries[i]).filter(e => e);
    }
}
