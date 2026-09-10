import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils
import "HyprVars.js" as HyprVars

Item {
    id: root

    // xdg-terminal-exec can only follow the chosen terminal once the desktop entry index is
    // populated. HyprVarsWriter uses the same transition to resolve the app command variables.
    readonly property bool entriesReady: DesktopEntries.applications.values.length > 0
    readonly property string xdgTerminalsPath: `${Quickshell.env("XDG_CONFIG_HOME") || `${Paths.home}/.config`}/xdg-terminals.list`

    function syncTerminal(): void {
        if (!root.entriesReady)
            return;

        const entry = HyprVars.entryFor(GlobalConfig.services.appTerminal, DesktopEntries.applications.values);
        if (!entry)
            return;

        const desktop = entry.id.endsWith(".desktop") ? entry.id : `${entry.id}.desktop`;
        terminalsFile.setText(`${desktop}\n`);
    }

    onEntriesReadyChanged: root.syncTerminal()
    Component.onCompleted: root.syncTerminal()

    Connections {
        target: GlobalConfig.services

        function onAppTerminalChanged(): void {
            root.syncTerminal();
        }
    }

    FileView {
        id: terminalsFile

        path: root.xdgTerminalsPath
        printErrors: false
        atomicWrites: true
    }
}
