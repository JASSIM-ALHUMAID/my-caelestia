import QtQml
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.utils

// Duck-typed stand-in for an MprisPlayer, backed by a raw PipeWire stream.
// Used for apps that play audio without publishing an MPRIS interface (eg Harbor).
// A stream can only tell us who is making noise and how loud - there is no
// metadata, no position and no transport, so everything else reports unsupported.
QtObject {
    id: root

    required property PwNode node

    readonly property bool isStreamPlayer: true

    readonly property string identity: Audio.getStreamName(node)
    readonly property string iconSource: {
        DesktopEntries.applications.values; // Re-resolve once the entry index is populated
        return Icons.getAppIcon(identity, "audio-x-generic");
    }

    // Some apps (browsers especially) put something useful in media.name, but most
    // just repeat their own name or a generic label - only show it if it adds info
    readonly property string trackTitle: {
        const name = node?.properties["media.name"] ?? "";
        if (!name || name === identity || name === "Playback Stream")
            return identity;
        return name;
    }
    readonly property string trackArtist: ""
    readonly property string trackAlbum: ""
    readonly property string trackArtUrl: ""
    readonly property var metadata: ({})

    // There is no way to distinguish "paused" from "open but silent"
    readonly property bool isPlaying: (node?.ready ?? false) && !muted

    readonly property real position: 0
    readonly property real length: 0
    readonly property bool positionSupported: false
    readonly property bool canSeek: false
    readonly property bool canPlay: false
    readonly property bool canPause: false
    readonly property bool canTogglePlaying: false
    readonly property bool canGoNext: false
    readonly property bool canGoPrevious: false
    readonly property bool shuffleSupported: false
    readonly property bool shuffle: false
    readonly property bool loopSupported: false
    readonly property int loopState: MprisLoopState.None

    readonly property real volume: node?.audio?.volume ?? 0
    readonly property bool muted: node?.audio?.muted ?? false

    function setVolume(newVolume: real): void {
        Audio.setStreamVolume(node, newVolume);
    }

    function toggleMuted(): void {
        Audio.setStreamMuted(node, !muted);
    }

    // No-ops so existing `Players.active?.next()` style call sites stay inert
    function play(): void {}
    function pause(): void {}
    function togglePlaying(): void {}
    function next(): void {}
    function previous(): void {}
    function stop(): void {}
}
