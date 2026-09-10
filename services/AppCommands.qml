pragma Singleton

import Quickshell
import Caelestia.Config

// Resolves the argv fragment that follows `app2unit --` for the shell's own launches.
//
// general.apps.* predates the Hyprland page's app pickers, so on a stock config the launcher would
// open foot/thunar/pavucontrol no matter what was picked there. An explicitly configured
// general.apps entry still wins -- isModified() tells a user-set value apart from the built-in
// default -- otherwise the pick is used.
Singleton {
    id: root

    // The launcher appends wrap_term_launch.sh <cmd...>, so this has to be an argv prefix that
    // takes a command. A .desktop id can't be one; xdg-terminal-exec is the freedesktop-standard
    // way to run a command in the user's terminal, and SyncApps keeps xdg-terminals.list pointing
    // at the picked terminal.
    readonly property list<string> terminal: GlobalConfig.general.apps.isModified("terminal") ? GlobalConfig.general.apps.terminal : (root.entryFor(GlobalConfig.services.appTerminal) ? ["xdg-terminal-exec"] : GlobalConfig.general.apps.terminal)

    readonly property list<string> explorer: root.argvFor("explorer", GlobalConfig.services.appFileExplorer)

    // No picker for a media player yet
    readonly property list<string> playback: GlobalConfig.general.apps.playback

    // Tolerates an id suffix or an exec name as well as an exact id, matching the picker in
    // HyprlandPage and HyprVars.commandFor.
    function entryFor(id: string): var {
        if (!id)
            return null;
        return DesktopEntries.applications.values.find(a => a.id === id || a.id.endsWith(`.${id}`) || a.execString === id) ?? null;
    }

    function argvFor(generalKey: string, id: string): list<string> {
        const explicit = GlobalConfig.general.apps[generalKey];
        if (GlobalConfig.general.apps.isModified(generalKey))
            return explicit;
        const entry = root.entryFor(id);
        // app2unit -- <id>.desktop <path> forwards the argument through the entry's %f/%U field code
        return entry ? [entry.id.endsWith(".desktop") ? entry.id : `${entry.id}.desktop`] : explicit;
    }
}
