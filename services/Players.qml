pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Caelestia
import Caelestia.Config
import qs.components.misc
import qs.services

Singleton {
    id: root

    // Streams we never want to surface as players - system noise and audio plumbing
    readonly property list<string> ignoredStreams: ["easyeffects", "speech-dispatcher", "libcanberra", "quickshell", "cava"]

    readonly property list<MprisPlayer> mprisList: Mpris.players.values
    readonly property list<QtObject> streamList: streamPlayers.instances

    // Real MPRIS players always win the auto pick; a stream is only ever chosen when
    // there is no MPRIS player at all (otherwise the media tab would show "nothing
    // playing" and hide the very switcher needed to select the stream)
    readonly property list<QtObject> list: [...mprisList, ...streamList]
    readonly property QtObject active: props.manualActive ?? mprisList.find(p => getIdentity(p) === GlobalConfig.services.defaultPlayer) ?? mprisList[0] ?? streamList[0] ?? null
    property alias manualActive: props.manualActive

    // PipeWire streams belonging to apps that have no MPRIS player of their own
    readonly property list<PwNode> orphanStreams: {
        const claimed = [];
        for (const p of mprisList) {
            if (p.identity)
                claimed.push(p.identity.toLowerCase());
            if (p.desktopEntry)
                claimed.push(p.desktopEntry.toLowerCase());
        }

        const byApp = new Map();
        for (const node of Audio.streams) {
            // isSink excludes capture streams (our own cava recorder lands there)
            if (!node?.audio || !node.isSink)
                continue;

            const props = node.properties ?? {};
            const role = props["media.role"] ?? "";
            if (role === "event" || role === "notification")
                continue;

            const app = (props["application.name"] || node.description || node.name || "").toLowerCase();
            const binary = (props["application.process.binary"] || "").toLowerCase();
            if (!app && !binary)
                continue;

            if (ignoredStreams.some(i => app.includes(i) || binary.includes(i)))
                continue;
            if (claimed.some(id => id === app || id === binary || app.includes(id) || id.includes(app)))
                continue;

            const key = app || binary;
            // An app can spawn several streams (Harbor has one per helper process);
            // prefer the one whose binary matches the app over a helper like WebKitWebProcess
            if (byApp.has(key) && !(!binary || binary === app))
                continue;
            byApp.set(key, node);
        }
        return [...byApp.values()];
    }

    function getIdentity(player: QtObject): string {
        if (!player)
            return "";
        const alias = GlobalConfig.services.playerAliases.find(a => a.from === player.identity);
        return alias?.to ?? player.identity;
    }

    function getArtUrl(player: QtObject): string {
        if (!player)
            return "";
        if (player.isStreamPlayer)
            return "";
        if (player.trackArtUrl)
            return player.trackArtUrl;

        const url = player.metadata["xesam:url"] ?? "";
        if (url.startsWith("https://www.youtube.com/watch")) {
            // Fallback for youtube
            const id = url.match(/[?&]v=([\w-]{11})/)?.[1];
            return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : "";
        }
        return "";
    }

    Connections {
        function onPostTrackChanged() {
            if (!GlobalConfig.utilities.toasts.nowPlaying) {
                return;
            }
            if (root.active.trackArtist != "" && root.active.trackTitle != "") {
                Toaster.toast(qsTr("Now Playing"), qsTr("%1 - %2").arg(root.active.trackArtist).arg(root.active.trackTitle), "music_note");
            }
        }

        // Stream players have no track signals to connect to
        target: root.active?.isStreamPlayer ? null : root.active
    }

    Variants {
        id: streamPlayers

        model: root.orphanStreams

        StreamPlayer {
            required property PwNode modelData

            node: modelData
        }
    }

    // A manually picked stream dies with its app - don't strand the UI on a dead adapter
    Connections {
        function onListChanged(): void {
            const manual = props.manualActive;
            if (manual && !root.list.includes(manual))
                props.manualActive = null;
        }

        target: root
    }

    PersistentProperties {
        id: props

        property QtObject manualActive

        reloadableId: "players"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaToggle"
        description: "Toggle media playback"
        onPressed: {
            const active = root.active;
            if (active && active.canTogglePlaying)
                active.togglePlaying();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaPrev"
        description: "Previous track"
        onPressed: {
            const active = root.active;
            if (active && active.canGoPrevious)
                active.previous();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaNext"
        description: "Next track"
        onPressed: {
            const active = root.active;
            if (active && active.canGoNext)
                active.next();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaStop"
        description: "Stop media playback"
        onPressed: root.active?.stop()
    }

    IpcHandler {
        function getActive(prop: string): string {
            const active = root.active;
            return active ? active[prop] ?? "Invalid property" : "No active player";
        }

        function list(): string {
            return root.list.map(p => root.getIdentity(p)).join("\n");
        }

        function play(): void {
            const active = root.active;
            if (active?.canPlay)
                active.play();
        }

        function pause(): void {
            const active = root.active;
            if (active?.canPause)
                active.pause();
        }

        function playPause(): void {
            const active = root.active;
            if (active?.canTogglePlaying)
                active.togglePlaying();
        }

        function previous(): void {
            const active = root.active;
            if (active?.canGoPrevious)
                active.previous();
        }

        function next(): void {
            const active = root.active;
            if (active?.canGoNext)
                active.next();
        }

        function stop(): void {
            root.active?.stop();
        }

        target: "mpris"
    }
}
