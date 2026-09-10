pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.utils
import "./KeybindActions.js" as KBActions
import "./KeybindDefaults.js" as Defaults

Singleton {
    id: root

    readonly property string configPath: `${Paths.config}/keybinds.json`

    property var categories: []
    property bool loaded: false

    signal configChanged

    // Every mutator deep-clones first: `categories` is a var property, so QML only emits its
    // change signal on reassignment, and mutating the live array in place would update nothing.
    function updateBinding(catIdx: int, bindIdx: int, binding: var): void {
        const cats = JSON.parse(JSON.stringify(categories));
        if (catIdx < 0 || catIdx >= cats.length) return;
        const binds = cats[catIdx].bindings;
        if (bindIdx < 0 || bindIdx >= binds.length) return;
        const act = KBActions.getActionById(binding.actionId);
        binds[bindIdx].desc = binding.desc;
        binds[bindIdx].modifiers = binding.modifiers;
        binds[bindIdx].key = binding.key;
        binds[bindIdx].actionId = binding.actionId;
        binds[bindIdx].argument = act && act.hasArg ? (binding.argument || "") : "";
        categories = cats;
        saveConfig();
    }

    // Just the shortcut, for the inline capture on the list page. Routing that through
    // updateBinding would mean rebuilding the whole record from the row, which is how the other
    // four fields would eventually get clobbered by a stale copy.
    function updateBindingKey(catIdx: int, bindIdx: int, mods: var, key: string): void {
        const cats = JSON.parse(JSON.stringify(categories));
        if (catIdx < 0 || catIdx >= cats.length) return;
        const binds = cats[catIdx].bindings;
        if (bindIdx < 0 || bindIdx >= binds.length) return;
        binds[bindIdx].modifiers = mods;
        binds[bindIdx].key = key;
        categories = cats;
        saveConfig();
    }

    function addBinding(catIdx: int, binding: var): void {
        const cats = JSON.parse(JSON.stringify(categories));
        if (catIdx < 0 || catIdx >= cats.length) return;
        const act = KBActions.getActionById(binding.actionId);
        cats[catIdx].bindings.push({
            desc: binding.desc,
            modifiers: binding.modifiers,
            key: binding.key,
            actionId: binding.actionId,
            argument: act && act.hasArg ? (binding.argument || "") : ""
        });
        categories = cats;
        saveConfig();
    }

    function removeBinding(catIdx: int, bindIdx: int): void {
        const cats = JSON.parse(JSON.stringify(categories));
        if (catIdx < 0 || catIdx >= cats.length) return;
        const binds = cats[catIdx].bindings;
        if (bindIdx < 0 || bindIdx >= binds.length) return;
        binds.splice(bindIdx, 1);
        categories = cats;
        saveConfig();
    }

    function resetToDefaults(): void {
        categories = Defaults.categories();
        saveConfig();
    }

    // configChanged still fires straight away: KeybindApplier should reflect the edit now, and
    // the write is async. What onSaveFailed below adds is the other half -- if the file never
    // lands, the binding used to work until the next restart and then quietly disappear, with
    // printErrors off hiding the reason.
    function saveConfig(): void {
        const data = { categories: categories };
        fileView.setText(JSON.stringify(data, null, 2));
        configChanged();
    }

    function ensureDefaultConfig(): void {
        if (categories.length > 0) return;
        categories = Defaults.categories();
        loaded = true;
        saveConfig();
    }

    FileView {
        id: fileView
        path: root.configPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const t = text().trim();
            if (t.length === 0) {
                root.ensureDefaultConfig();
                return;
            }
            try {
                const data = JSON.parse(t);
                root.categories = data.categories || [];
                if (root.categories.length === 0) {
                    root.ensureDefaultConfig();
                    return;
                }
                root.loaded = true;
            } catch (e) {
                console.warn("Failed to parse keybinds config:", e);
                root.ensureDefaultConfig();
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.categories = Defaults.categories();
                const json = JSON.stringify({ categories: root.categories }, null, 2);
                Qt.callLater(() => {
                    fileView.setText(json);
                    root.loaded = true;
                });
            } else {
                console.warn("Keybinds config could not be read:", err);
            }
        }
        onSaveFailed: err => {
            console.warn("Keybinds config could not be written:", err);
            Toaster.toast(qsTr("Keybind not saved"), qsTr("The shortcut works now but will be lost on restart — check permissions on %1").arg(root.configPath), "key_off");
        }
    }
}
