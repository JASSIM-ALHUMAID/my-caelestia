pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services

QtObject {
    id: root

    property var history: []
    property bool loaded: false

    function load(): void {
        loadProc.running = true;
    }

    readonly property Process loadProc: Process {
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const parsed = [];
                for (const line of lines) {
                    const parts = line.split(/\t/);
                    if (parts.length >= 2) {
                        parsed.push({
                            id: parts[0],
                            content: parts[1]
                        });
                    } else {
                        const match = line.match(/^(\d+)\s+(.*)$/);
                        if (match) {
                            parsed.push({
                                id: match[1],
                                content: match[2]
                            });
                        }
                    }
                }
                root.history = parsed;
                root.loaded = true;
            }
        }
    }

    function query(search: string): var {
        const prefix = `${GlobalConfig.launcher.actionPrefix}clip `;
        if (search.startsWith(prefix))
            search = search.slice(prefix.length);

        if (!search) return history;
        const words = search.toLowerCase().split(" ").filter(w => w.length > 0);

        return history.filter(h => {
            const content = h.content.toLowerCase();
            return words.every(word => content.includes(word));
        });
    }

    function select(item: var, list: Item): void {
        Quickshell.execDetached(["sh", "-c", `cliphist decode ${item.id} | wl-copy`]);
        list.visibilities.launcher = false;
    }

    // Checked rather than detached because the empty list is a privacy claim: if the wipe
    // failed, the launcher looked cleared while the history was still on disk and returned on
    // the next load. On failure the list is restored so what is shown matches what is stored.
    function clear(): void {
        const previous = history;
        history = [];

        Cmd.run(["cliphist", "wipe"], {
            title: qsTr("Clipboard not cleared"),
            icon: "content_paste_off",
            onExit: exitCode => {
                if (exitCode !== 0)
                    root.history = previous;
            }
        });
    }
}
