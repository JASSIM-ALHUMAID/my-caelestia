pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

Singleton {
    id: root

    property var lastPlayed: ({})

    // Ambient event sounds: silent unless the user opted the subsystem in.
    function play(sound: string): void {
        if (!GlobalConfig.utilities.sounds.enabled)
            return;
        root.playForced(sound);
    }

    // Bypasses the master switch, for sounds the user asked for individually and that carry their
    // own toggle (the countdown alarm). Split into its own function rather than a `force`
    // argument because QML rejects a default value on a typed parameter.
    function playForced(sound: string): void {
        if (sound === "")
            return;

        // A value with a slash is a path to a sound file; anything else is an XDG sound-theme
        // name. `canberra-gtk-play` missing entirely degrades to silence, since execDetached
        // does not surface a failed exec.
        if (sound.includes("/"))
            Quickshell.execDetached(["canberra-gtk-play", "-f", sound]);
        else
            Quickshell.execDetached(["canberra-gtk-play", "-i", sound]);
    }

    function playThrottled(sound: string): void {
        if (sound === "")
            return;
        const now = Date.now();
        if (lastPlayed[sound] !== undefined && now - lastPlayed[sound] < GlobalConfig.utilities.sounds.throttleMs)
            return;
        lastPlayed[sound] = now;
        play(sound);
    }

    property list<string> available: []
    property bool availableLoaded: false

    function loadAvailable(): void {
        if (availableLoaded)
            return;
        availableLoaded = true;
        scanProc.running = true;
    }

    function preview(sound: string): void {
        playForced(sound);
    }

    PersistentProperties {
        id: props

        // Survives a shell reload but not a process restart, which is exactly the distinction we
        // want: `settings.watchFiles` reloads the QML tree on every config save, and a login chime
        // on each of those would fire constantly while tweaking settings.
        property bool started: false

        reloadableId: "sounds"
    }

    Component.onCompleted: {
        if (!props.started) {
            props.started = true;
            root.play(GlobalConfig.utilities.sounds.startup);
        }
    }

    Process {
        id: scanProc

        // Globs rather than `find`, and the basename/extension stripping done in JS below: the
        // alternative needs `find -printf` plus sed, and that much shell quoting inside a QML string
        // literal is where this would break.
        command: ["sh", "-c", "ls /usr/share/sounds/*/*/*.oga /usr/share/sounds/*/*.oga $HOME/.local/share/sounds/*/*/*.oga 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.trim().split("\n").filter(l => l.length > 0).map(p => {
                    const base = p.slice(p.lastIndexOf("/") + 1);
                    const dot = base.lastIndexOf(".");
                    return dot > 0 ? base.slice(0, dot) : base;
                });
                root.available = [...new Set(names)].sort();
            }
        }
    }
}
