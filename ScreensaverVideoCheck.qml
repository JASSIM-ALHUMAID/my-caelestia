import QtQuick
import Quickshell
import qs.modules.screensaver.effects

ShellRoot {
    id: root

    readonly property string videoPath: Quickshell.env("SCREENSAVER_TEST_VIDEO")

    function fail(message: string): void {
        console.log(`SCREENSAVER_VIDEO_CHECK: FAIL ${message}`);
        Qt.quit();
    }

    Component.onCompleted: {
        if (!root.videoPath)
            root.fail("missing-path");
    }

    FloatingWindow {
        visible: true
        color: "black"
        implicitWidth: 960
        implicitHeight: 540

        EffectVideo {
            id: video

            anchors.fill: parent
            source: root.videoPath
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: true

        onTriggered: {
            if (video.failed) {
                stop();
                root.fail(`media-error ${video.errorMessage}`);
                return;
            }
            if (!video.frameSeen)
                return;

            stop();
            if (!video.grabToImage(function(result) {
                const saved = result.saveToFile("/tmp/caelestia-screensaver-video.png");
                console.log(`SCREENSAVER_VIDEO_CHECK: ${saved ? "PASS" : "FAIL"} size=${Math.round(video.width)}x${Math.round(video.height)}`);
                Qt.quit();
            }))
                root.fail("grab");
        }
    }

    Timer {
        interval: 8000
        running: true

        onTriggered: root.fail("decode-timeout")
    }
}
