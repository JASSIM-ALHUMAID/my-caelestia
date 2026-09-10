pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var all: []
    property bool loaded: false

    function load(): void {
        if (loaded) return;
        loadProc.running = true;
    }

    readonly property Process loadProc: Process {
        command: ["cat", "/usr/lib/python3.14/site-packages/caelestia/data/emojis.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const parsed = [];
                for (const line of lines) {
                    const spaceIndex = line.indexOf(" ");
                    if (spaceIndex !== -1) {
                        parsed.push({
                            glyph: line.slice(0, spaceIndex),
                            keywords: line.slice(spaceIndex + 1).toLowerCase()
                        });
                    }
                }
                root.all = parsed;
                root.loaded = true;
            }
        }
    }

    function search(query: string): var {
        if (!query) return all;
        const words = query.toLowerCase().split(" ").filter(w => w.length > 0);
        if (words.length === 0) return all;

        return all.filter(e => {
            return words.every(word => e.keywords.includes(word));
        });
    }
}
