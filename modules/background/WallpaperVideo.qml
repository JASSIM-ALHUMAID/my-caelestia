import QtQuick
import QtMultimedia
import Quickshell
import Caelestia.Config
import qs.services

VideoOutput {
    id: root

    required property string path
    readonly property bool ready: player.mediaStatus === MediaPlayer.LoadedMedia || player.mediaStatus === MediaPlayer.BufferingMedia || player.mediaStatus === MediaPlayer.BufferedMedia
    readonly property bool progressAvailable: ready && player.duration > 0
    readonly property real playbackProgress: progressAvailable ? Math.max(0, Math.min(1, player.position / player.duration)) : 0
    readonly property bool shouldPlay: Wallpapers.animationsActiveOn((QsWindow.window as QsWindow)?.screen ?? null)
    property bool frameSeen: false

    signal decodeFailed()

    function syncPlayback(): void {
        if (!ready)
            return;

        if (shouldPlay)
            player.play();
        else
            player.pause();
    }

    fillMode: {
        switch (Config.background.fillMode) {
        case "stretch": return VideoOutput.Stretch;
        case "fit": case "center": case "tile": return VideoOutput.PreserveAspectFit;
        default: return VideoOutput.PreserveAspectCrop;
        }
    }
    endOfStreamPolicy: VideoOutput.KeepLastFrame

    Component.onDestruction: player.stop()

    onReadyChanged: syncPlayback()
    onShouldPlayChanged: syncPlayback()

    MediaPlayer {
        id: player

        source: root.path
        videoOutput: root
        loops: (Config.background.videoPlayToEnd && Config.background.rotationEnabled) ? 1 : (Config.background.videoLoops === 0 ? MediaPlayer.Infinite : Config.background.videoLoops)

        audioOutput: AudioOutput {
            muted: true
        }

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) {
                const deferToEnd = Config.background.videoPlayToEnd && Config.background.rotationEnabled;
                if (deferToEnd && !Wallpapers.pendingVideoAdvance) {
                    player.position = 0;
                    player.play();
                } else if (!Wallpapers.advance()) {
                    player.position = 0;
                    player.play();
                }
            }
        }
    }

    Connections {
        target: root.videoSink
        enabled: !root.frameSeen

        function onVideoFrameChanged(): void {
            root.frameSeen = true;
        }
    }

    Connections {
        target: Wallpapers

        function onSeekRequested(targetMs: int): void {
            const screen = (QsWindow.window as QsWindow)?.screen ?? null;
            if (!screen || Hypr.monitorFor(screen) !== Hypr.focusedMonitor)
                return;
            if (player.seekable)
                player.position = targetMs < 0 ? 0 : (player.duration > 0 && targetMs > player.duration ? player.duration : targetMs);
        }
    }

    Timer {
        interval: 3000
        running: !root.frameSeen && player.playbackState === MediaPlayer.PlayingState

        onTriggered: {
            if (!root.frameSeen)
                root.decodeFailed();
        }
    }
}
