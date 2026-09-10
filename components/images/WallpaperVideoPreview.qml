pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Caelestia.Config

VideoOutput {
    id: root

    required property string path
    property bool active: true
    property bool frameSeen: false
    property bool failed: false

    readonly property bool ready: frameSeen && !failed
    readonly property bool playerReady: player.mediaStatus === MediaPlayer.LoadedMedia || player.mediaStatus === MediaPlayer.BufferingMedia || player.mediaStatus === MediaPlayer.BufferedMedia

    function syncPlayback(): void {
        if (!active || failed || !playerReady) {
            player.pause();
            return;
        }
        player.play();
    }

    opacity: ready ? 1 : 0
    fillMode: {
        switch (Config.background.fillMode) {
        case "stretch": return VideoOutput.Stretch;
        case "fit": case "center": case "tile": return VideoOutput.PreserveAspectFit;
        default: return VideoOutput.PreserveAspectCrop;
        }
    }

    onActiveChanged: syncPlayback()
    onFailedChanged: syncPlayback()
    onPlayerReadyChanged: syncPlayback()
    onPathChanged: {
        player.stop();
        frameSeen = false;
        failed = false;
        Qt.callLater(syncPlayback);
    }

    Component.onCompleted: syncPlayback()
    Component.onDestruction: player.stop()

    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    MediaPlayer {
        id: player

        source: root.path
        videoOutput: root
        loops: MediaPlayer.Infinite

        audioOutput: AudioOutput {
            muted: true
        }

        onErrorOccurred: root.failed = true
    }

    Connections {
        target: root.videoSink
        enabled: !root.frameSeen && !root.failed

        function onVideoFrameChanged(): void {
            root.frameSeen = true;
            decodeTimeout.stop();
        }
    }

    Timer {
        id: decodeTimeout

        interval: 3000
        running: root.active && root.playerReady && !root.frameSeen && !root.failed

        onTriggered: root.failed = true
    }
}
