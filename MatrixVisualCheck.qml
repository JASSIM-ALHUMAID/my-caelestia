import QtQuick
import Quickshell
import qs.modules.screensaver.effects

ShellRoot {
    FloatingWindow {
        visible: true
        color: "black"
        implicitWidth: 960
        implicitHeight: 540

        EffectMatrix {
            id: matrix

            anchors.fill: parent
        }
    }

    Timer {
        interval: 250
        running: true
        repeat: true

        onTriggered: {
            if (matrix.cellWidth <= 0 || matrix.cellHeight <= 0)
                return;

            running = false;
            matrix.rebuildDrops();

            const minimumGutter = Math.max(3, matrix.cellWidth * 0.2);
            const minimumPitch = matrix.cellWidth + minimumGutter;
            const maximumColumns = Math.max(1, Math.floor((matrix.width + minimumGutter) / minimumPitch));
            const hasReadableGlyphs = matrix.cellHeight >= 18;
            const hasSeparatedTracks = matrix.drops.length <= maximumColumns;
            const maximumSpeed = matrix.drops.reduce((fastest, drop) => Math.max(fastest, drop.speed), 0);
            const hasComfortableSpeed = maximumSpeed <= 0.5;
            const hasStableStrings = matrix.drops.every(drop => drop.glyphs && drop.glyphs.length >= 8);
            const passed = hasReadableGlyphs && hasSeparatedTracks && hasComfortableSpeed && hasStableStrings;

            console.log(`MATRIX_VISUAL_CHECK: ${passed ? "PASS" : "FAIL"} glyph=${matrix.cellWidth.toFixed(2)}x${matrix.cellHeight.toFixed(2)} columns=${matrix.drops.length}/${maximumColumns} maxSpeed=${maximumSpeed.toFixed(2)} stable=${hasStableStrings}`);
            Qt.quit();
        }
    }
}
