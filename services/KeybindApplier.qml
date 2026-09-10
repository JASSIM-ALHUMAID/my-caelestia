pragma Singleton

import QtQuick
import Quickshell
import qs.services
import "./KeybindActions.js" as KBActions

Singleton {
    id: root

    property var previousBinds: []
    property bool suspended: false

    // "catIdx:bindIdx" -> reason, for bindings applyAll couldn't turn into a Hyprland bind. Both
    // paths below used to `continue` in silence, so such a binding simply never fired and the UI
    // showed nothing wrong. Every action currently in KeybindActions.ACTIONS maps cleanly, so
    // this stays empty today -- it exists to catch an action added to that table without a
    // matching luaDispatcher case.
    property var unsupported: ({})

    // Lazy singleton: nothing reads properties off this service, so something
    // loaded at startup (Shortcuts.qml) must call this to instantiate it,
    // otherwise the JSON keybinds are never applied.
    function init(): void {
    }

    function suspend(): void {
        if (suspended) return;
        const commands = [];
        for (const b of previousBinds) {
            commands.push(`eval hl.unbind(${KBActions.luaString(b.combo)})`);
        }
        if (commands.length > 0) Hypr.extras.batchMessage(commands);
        previousBinds = [];
        suspended = true;
    }

    function resume(): void {
        if (!suspended) return;
        suspended = false;
        applyAll();
    }

    Connections {
        target: KeybindsConfig
        function onConfigChanged() {
            root.applyAll();
        }
    }

    // A `hyprctl reload` re-parses the config and drops every dynamically
    // applied bind, so these have to go back on afterwards.
    Connections {
        target: Hypr
        function onConfigReloaded() {
            root.previousBinds = [];
            root.applyAll();
        }
    }

    Component.onCompleted: {
        if (KeybindsConfig.loaded)
            applyAll();
        else
            KeybindsConfig.loadedChanged.connect(() => applyAll());
    }

    function applyAll() {
        if (suspended) return;

        const commands = [];

        // Build the full set of keybinds from the JSON config, then unbind
        // ALL of them first. This prevents duplicates when the shell restarts
        // without hyprctl reload (e.g. via the install script), because the
        // old dynamic binds from the previous session are still registered in
        // Hyprland and previousBinds is empty in a fresh QML process.
        const newBinds = [];
        const skipped = ({});
        const categories = KeybindsConfig.categories;
        for (let ci = 0; ci < categories.length; ci++) {
            const binds = categories[ci].bindings;
            for (let bi = 0; bi < binds.length; bi++) {
                const binding = binds[bi];
                const resolved = KBActions.resolveToHyprland({ id: binding.actionId, argument: binding.argument });
                if (!resolved) {
                    skipped[`${ci}:${bi}`] = qsTr("Unknown action");
                    continue;
                }

                // The lua config takes binds as `hl.bind("SUPER + SHIFT + O", <dispatcher>)`,
                // which is exactly the combo format formatKeyCombo already produces.
                const dispatcher = KBActions.luaDispatcher(resolved.dispatcher, resolved.argument);
                if (!dispatcher) {
                    skipped[`${ci}:${bi}`] = qsTr("Action not supported by Hyprland");
                    continue;
                }

                const combo = KBActions.formatKeyCombo(binding.modifiers, binding.key);
                newBinds.push({ combo: combo, dispatcher: dispatcher });
            }
        }
        root.unsupported = skipped;

        // Unbind every combo we previously applied AND every combo we're about
        // to apply. Covering previousBinds removes combos that were changed or
        // removed in the new config (otherwise the old combo stays registered
        // in Hyprland and keeps firing); covering newBinds dedups stale binds
        // left from a prior shell session.
        const toUnbind = new Set();
        for (const b of previousBinds)
            toUnbind.add(b.combo);
        for (const b of newBinds)
            toUnbind.add(b.combo);
        for (const combo of toUnbind) {
            commands.push(`eval hl.unbind(${KBActions.luaString(combo)})`);
        }

        // Rebind them
        for (const b of newBinds) {
            commands.push(`eval hl.bind(${KBActions.luaString(b.combo)}, ${b.dispatcher})`);
        }

        previousBinds = newBinds.map(b => ({ combo: b.combo }));

        if (commands.length > 0) {
            Hypr.extras.batchMessage(commands);
        }
    }
}
