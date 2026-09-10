pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import "./KeybindActions.js" as KBActions
import "./HyprSchema.js" as Schema

// Every shortcut the shell knows about, from both keybind systems, keyed by canonical combo.
//
// The two systems are otherwise unaware of each other: keybinds.json binds are applied
// dynamically via KeybindApplier, while the Hyprland `kb*` variables are compositor config. A
// combo claimed by both is a real collision -- whichever loses is simply dead -- but until this
// existed each page could only see its own half, so that collision was invisible on both.
Singleton {
    id: root

    readonly property string jsonSource: "json"
    readonly property string hyprSource: "hypr"

    function sourceName(source: string): string {
        return source === root.hyprSource ? qsTr("Hyprland binds") : qsTr("Keybindings");
    }

    // Canonical combo -> [{ source, id, label }]. `id` is "catIdx:bindIdx" for keybinds.json
    // entries and the schema key for Hyprland ones, so a page can look up its own rows.
    readonly property var claims: {
        const out = ({});
        const add = (combo, entry) => {
            // A bind with neither modifiers nor a key isn't a claim on anything; letting the
            // empty combo through would make every incomplete row collide with every other.
            if (combo === ",")
                return;
            if (!out[combo])
                out[combo] = [];
            out[combo].push(entry);
        };

        const cats = KeybindsConfig.categories;
        for (let ci = 0; ci < cats.length; ci++) {
            const binds = cats[ci].bindings ?? [];
            for (let bi = 0; bi < binds.length; bi++) {
                const b = binds[bi];
                add(KBActions.normalizeCombo(b.modifiers, b.key), {
                    source: root.jsonSource,
                    id: `${ci}:${bi}`,
                    label: b.desc
                });
            }
        }

        // Prefix rows claim ten combos each -- bindCombos expands them the same way
        // keybinds.lua does, so kbGoToWs = "SUPER" is seen to own SUPER + 1 through SUPER + 0.
        for (const section of Schema.BIND_SECTIONS)
            for (const v of section.vars)
                for (const combo of Schema.bindCombos(GlobalConfig.services[v.key], v))
                    add(KBActions.normalizeHyprCombo(combo), {
                        source: root.hyprSource,
                        id: v.key,
                        label: v.label
                    });

        return out;
    }

    // id -> warning, for rows belonging to `source`. Accumulated across combos rather than per
    // combo, since one prefix row can collide with different binds on different digits.
    function conflictsFor(source: string): var {
        const acc = ({});

        for (const combo in root.claims) {
            const entries = root.claims[combo];
            if (entries.length < 2)
                continue;

            for (const entry of entries) {
                if (entry.source !== source)
                    continue;

                if (!acc[entry.id])
                    acc[entry.id] = [];
                for (const other of entries) {
                    if (other === entry)
                        continue;
                    // Name the other system only when it is one, so same-page collisions stay
                    // terse and cross-system ones say where to go looking.
                    const label = other.source === source ? other.label : qsTr("%1 (%2)").arg(other.label).arg(root.sourceName(other.source));
                    if (!acc[entry.id].includes(label))
                        acc[entry.id].push(label);
                }
            }
        }

        const out = ({});
        for (const id in acc)
            if (acc[id].length > 0)
                out[id] = qsTr("Also bound to %1").arg(acc[id].join(", "));
        return out;
    }

    readonly property var jsonConflicts: root.conflictsFor(root.jsonSource)
    readonly property var hyprConflicts: root.conflictsFor(root.hyprSource)

    // For a combo being edited but not yet saved, which the maps above can't cover. `exceptId`
    // is the row doing the asking, so an unchanged shortcut doesn't report colliding with itself.
    function describeClaims(mods: var, key: string, exceptId: string): string {
        const entries = root.claims[KBActions.normalizeCombo(mods, key)] ?? [];
        const labels = [];
        for (const e of entries) {
            if (e.id === exceptId)
                continue;
            const label = e.source === root.jsonSource ? e.label : qsTr("%1 (%2)").arg(e.label).arg(root.sourceName(e.source));
            if (!labels.includes(label))
                labels.push(label);
        }
        return labels.length > 0 ? qsTr("Already used by %1").arg(labels.join(", ")) : "";
    }
}
