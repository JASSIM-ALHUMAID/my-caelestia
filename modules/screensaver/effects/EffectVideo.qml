import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property string source: GlobalConfig.general?.screensaver?.videoPath ?? ""
    property bool frameSeen: false
    property bool failed: false
    property string errorMessage: ""

    readonly property bool configured: source.length > 0

    function syncPlayback(): void {
        if (!root.configured || root.failed || (player.mediaStatus !== MediaPlayer.LoadedMedia && player.mediaStatus !== MediaPlayer.BufferingMedia && player.mediaStatus !== MediaPlayer.BufferedMedia))
            return;

        player.play();
    }

    onSourceChanged: {
        player.stop();
        root.frameSeen = false;
        root.failed = false;
        root.errorMessage = "";
        Qt.callLater(root.syncPlayback);
    }
    onFailedChanged: root.syncPlayback()
    Component.onCompleted: root.syncPlayback()
    Component.onDestruction: player.stop()

    Rectangle {
        anchors.fill: parent

        color: "#020306"
    }

    VideoOutput {
        id: output

        anchors.fill: parent

        fillMode: VideoOutput.PreserveAspectCrop
        opacity: root.frameSeen && !root.failed ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.frameSeen && !root.failed
        color: "transparent"

        gradient: Gradient {
            GradientStop { position: 0; color: "#14000000" }
            GradientStop { position: 0.72; color: "#00000000" }
            GradientStop { position: 1; color: "#30000000" }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        visible: !root.configured || root.failed
        spacing: 10

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter

            text: root.failed ? "broken_image" : "movie"
            color: root.failed ? Colours.palette.m3error : Colours.palette.m3secondary
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2.4).build()
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter

            text: root.failed ? qsTr("Video could not be played") : qsTr("Choose a screensaver video in Settings")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.title.large
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            visible: root.failed

            text: qsTr("Try MP4, WebM, MKV, MOV, AVI, or M4V")
            color: Colours.palette.m3outline
            font: Tokens.font.body.medium
        }
    }

    MediaPlayer {
        id: player

        source: root.configured ? root.source : ""
        videoOutput: output
        loops: MediaPlayer.Infinite

        audioOutput: AudioOutput {
            muted: true
        }

        onMediaStatusChanged: root.syncPlayback()

        onErrorOccurred: (error, errorString) => {
            root.errorMessage = errorString;
            root.failed = true;
        }
    }

    Connections {
        function onVideoFrameChanged(): void {
            root.frameSeen = true;
            decodeTimeout.stop();
        }

        target: output.videoSink
        enabled: root.configured && !root.frameSeen && !root.failed
    }

    Timer {
        id: decodeTimeout

        interval: 5000
        running: root.configured && player.playbackState === MediaPlayer.PlayingState && !root.frameSeen && !root.failed

        onTriggered: root.failed = true
    }
}
