import QtQuick
import Quickshell
import qs.modules.screensaver
import qs.modules.screensaver.effects

ShellRoot {
    id: root

    readonly property list<string> expectedIds: ["logo", "clock", "matrix", "starfield", "aurora", "terminal", "constellation", "mosaic", "video"]

    property int effectIndex: 0
    property bool capturing: false

    function fail(message: string): void {
        console.log(`SCREENSAVER_EFFECTS_CHECK: FAIL ${message}`);
        Qt.quit();
    }

    Component.onCompleted: {
        const actualIds = registry.all.map(entry => entry.id);
        if (actualIds.join(",") !== root.expectedIds.join(","))
            root.fail(`registry=${actualIds.join(",")}`);
    }

    FloatingWindow {
        visible: true
        color: "black"
        implicitWidth: 960
        implicitHeight: 540

        ScreensaverContent {
            id: content

            anchors.fill: parent
            active: true
            effectId: registry.all[root.effectIndex]?.id ?? "logo"
            captureKeyboard: false
        }
    }

    Effects {
        id: registry
    }

    Timer {
        interval: 900
        repeat: true
        running: true

        onTriggered: {
            if (root.capturing || !content.visible)
                return;

            root.capturing = true;
            const entry = registry.all[root.effectIndex];
            const accepted = content.grabToImage(function(result) {
                const saved = result.saveToFile(`/tmp/caelestia-screensaver-${entry.id}.png`);
                console.log(`SCREENSAVER_EFFECT: ${saved ? "PASS" : "FAIL"} id=${entry.id} size=${Math.round(content.width)}x${Math.round(content.height)}`);
                if (!saved) {
                    root.fail(`capture=${entry.id}`);
                    return;
                }

                root.effectIndex++;
                root.capturing = false;
                if (root.effectIndex >= registry.all.length) {
                    console.log(`SCREENSAVER_EFFECTS_CHECK: PASS total=${registry.all.length}`);
                    Qt.quit();
                }
            });
            if (!accepted)
                root.fail(`grab=${entry.id}`);
        }
    }
}
