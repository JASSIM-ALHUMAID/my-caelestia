pragma ComponentBehavior: Bound

import QtQml
import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.utils
import "HyprVars.js" as HyprVars

// Owns the one output path for every Hyprland variable exposed by the shell. The older writers
// used substitutions that silently did nothing when a key was absent; the awk pass upserts so a
// newly exposed setting works with an existing hypr-vars.lua too.
Item {
    id: root

    readonly property string hyprVarsLuaPath: `${Paths.config}/hypr-vars.lua`
    readonly property var keys: HyprVars.keys
    readonly property var applications: DesktopEntries.applications.values
    readonly property bool entriesReady: applications.length > 0

    // The last payload known to be on disk. An unrelated config change should not cost a
    // Hyprland reload.
    property string lastWritten: ""

    // The payload currently being written. Without it a change arriving mid-write would start
    // a second, racing writer against the same file.
    property string inFlight: ""

    function luaValue(entry: var, value: var): string {
        if (entry.type === "bool")
            return value ? "true" : "false";
        if (entry.type === "string")
            return `"${String(value).replace(/(["\\])/g, "\\$1")}"`;
        return String(value);
    }

    // Keys the loaded plugin does not know are skipped before transforms run. QML reads a
    // missing property as undefined, which would otherwise land in the user's config as the
    // literal string "undefined" -- and a Quickshell generation reload picks up new QML while
    // keeping the native plugin the process started with, so this state is reachable whenever
    // an update adds config properties without a full restart. A transform may also return
    // undefined when its own input is not ready, as the desktop-entry transforms do at startup.
    function resolvedValues(): var {
        return root.keys.map(entry => {
            const source = GlobalConfig.services[entry.from ?? entry.key];
            if (source === undefined)
                return null;
            const value = entry.value ? entry.value(source, root.applications) : source;
            return value === undefined ? null : ({ entry: entry, value: value });
        }).filter(value => value !== null);
    }

    // key\x02value pairs joined by \x01 -- neither can appear in a Lua identifier or in a value
    // that survived luaValue's escaping, so no separator collides with the payload.
    function payload(values: var): string {
        return values.map(value => `${value.entry.key}\x02${root.luaValue(value.entry, value.value)}`).join("\x01");
    }

    function shQuote(value: var): string {
        return `'${String(value).replace(/'/g, "'\\''")}'`;
    }

    // The Lua parser requires eval rather than the legacy keyword command, which misleadingly
    // exits successfully even when rejected. Dotted paths keep that Lua rendering declarative.
    function luaConfigCall(path: string, entry: var, value: var): string {
        const parts = path.split(".");
        let table = `${parts[parts.length - 1]} = ${root.luaValue(entry, value)}`;
        for (let i = parts.length - 2; i >= 0; i--)
            table = `${parts[i]} = { ${table} }`;
        return `hl.config({ ${table} })`;
    }

    function runtimeCommands(values: var): string {
        return values.filter(value => value.entry.runtime !== undefined).map(value => {
            const hook = value.entry.runtime;
            const argv = typeof hook === "string"
                ? ["hyprctl", "eval", root.luaConfigCall(hook, value.entry, value.value)]
                : hook(value.value, GlobalConfig.services);
            const command = argv?.length ? argv.map(arg => root.shQuote(arg)).join(" ") : "";
            // Instant application is optional; a missing or failed runtime command must not stop
            // the authoritative file write and reload that follow it.
            return command.length ? `${command} || true` : "";
        }).filter(command => command.length > 0).join("\n");
    }

    // `lastWritten` is only advanced once the write has actually landed. Committing it up front
    // meant a failed write -- a full disk, a bad mktemp, an unwritable config dir -- was
    // remembered as done, so the identical payload was suppressed from then on and the settings
    // could never be re-applied without changing them to something else first.
    function apply(): void {
        const values = root.resolvedValues();
        const pairs = root.payload(values);
        if (pairs === root.lastWritten || pairs === root.inFlight)
            return;
        root.inFlight = pairs;

        const script = `
set -e
${root.runtimeCommands(values)}
f="$1"
[ -f "$f" ] || printf 'return {\\n}\\n' > "$f"
tmp=$(mktemp)
PAIRS="$2" awk '
BEGIN {
    n = split(ENVIRON["PAIRS"], pairs, "\\001")
    for (i = 1; i <= n; i++) {
        eq = index(pairs[i], "\\002")
        k[i] = substr(pairs[i], 1, eq - 1)
        v[i] = substr(pairs[i], eq + 1)
    }
}
{
    lines[NR] = $0
    for (i = 1; i <= n; i++)
        if ($0 ~ "^[[:space:]]*" k[i] "[[:space:]]*=") {
            lines[NR] = "\\t" k[i] " = " v[i] ","
            seen[i] = 1
        }
    if ($0 ~ /^[[:space:]]*}/) close_line = NR
}
END {
    if (close_line == 0) close_line = NR + 1
    for (i = 1; i <= NR + 1; i++) {
        if (i == close_line) {
            missing = 0
            for (j = 1; j <= n; j++)
                if (!seen[j]) { if (!missing) { print "" ; print "\\t-- Managed by Nexus" ; missing = 1 } print "\\t" k[j] " = " v[j] "," }
        }
        if (i <= NR) print lines[i]
    }
}
' "$f" > "$tmp"
mv "$tmp" "$f"
hyprctl reload
`;
        Cmd.run(["sh", "-c", script, "sh", root.hyprVarsLuaPath, pairs], {
            title: qsTr("Couldn't save Hyprland settings"),
            icon: "settings_alert",
            // No automatic retry: a persistent cause (unwritable config dir, full disk) would
            // spin, and the toast has already told the user. Clearing inFlight without setting
            // lastWritten is enough -- the next config change tries again from scratch.
            onExit: exitCode => {
                root.inFlight = "";
                if (exitCode === 0)
                    root.lastWritten = pairs;
            }
        });
    }

    function scheduleApply(): void {
        applyTimer.restart();
    }

    // Desktop entries arrive asynchronously; resolving all app keys after that one transition
    // lets their transforms defer cleanly without making SyncApps coordinate this writer.
    onEntriesReadyChanged: root.scheduleApply()
    Component.onCompleted: root.scheduleApply()

    // A config page can reset several properties together. Debouncing that fan-out keeps the
    // resulting persistence to one write and one reload with the latest values.
    Timer {
        id: applyTimer

        interval: 50
        onTriggered: root.apply()
    }

    // One watcher per source property is derived from the table rather than maintained as a
    // block of on<Key>Changed handlers. With roughly seventy keys, a forgotten handler would
    // fail silently; the debounce and lastWritten guard absorb the intentional fan-in here.
    Instantiator {
        model: root.keys

        delegate: QtObject {
            required property var modelData

            readonly property var value: GlobalConfig.services[modelData.from ?? modelData.key]

            onValueChanged: root.scheduleApply()
        }
    }
}
