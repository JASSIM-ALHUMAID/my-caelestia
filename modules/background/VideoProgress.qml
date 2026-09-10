pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    required property string edge
    required property real progress
    required property string style
    required property int thickness

    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property real boundedProgress: Math.max(0, Math.min(1, progress))
    readonly property real effectiveThickness: Math.max(1, thickness)
    readonly property bool wavy: style === "wavy"
    readonly property real waveAmplitude: effectiveThickness * 0.75
    readonly property real visualDepth: wavy ? effectiveThickness + waveAmplitude * 2 : effectiveThickness

    Item {
        id: indicator

        x: root.edge === "right" ? root.width - width : 0
        y: root.edge === "bottom" ? root.height - height : 0
        width: root.vertical ? root.visualDepth : root.width
        height: root.vertical ? root.height : root.visualDepth

        Rectangle {
            anchors.centerIn: parent
            width: root.vertical ? root.effectiveThickness : parent.width
            height: root.vertical ? parent.height : root.effectiveThickness
            radius: root.effectiveThickness / 2
            color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.65)
            antialiasing: true
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: root.vertical ? parent.width : parent.width * root.boundedProgress
            height: root.vertical ? parent.height * root.boundedProgress : parent.height
            visible: !root.wavy
            radius: root.effectiveThickness / 2
            color: Colours.palette.m3primary
            antialiasing: true
        }

        Canvas {
            id: wave

            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: root.vertical ? parent.width : parent.width * root.boundedProgress
            height: root.vertical ? parent.height * root.boundedProgress : parent.height
            visible: root.wavy && root.boundedProgress > 0

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (width <= 0 || height <= 0)
                    return;

                const lineWidth = root.effectiveThickness;
                const amplitude = root.waveAmplitude;
                const fullLength = root.vertical ? root.height : root.width;
                const frequency = Math.max(1, Math.round(fullLength / 120));
                const phase = Date.now() / 400;

                ctx.strokeStyle = Colours.palette.m3primary;
                ctx.lineWidth = lineWidth;
                ctx.lineCap = "round";
                ctx.beginPath();

                if (root.vertical) {
                    const centerX = width / 2;
                    const start = fullLength - height;
                    for (let y = lineWidth / 2; y <= height - lineWidth / 2; y += 1) {
                        const waveX = centerX + amplitude * Math.sin(frequency * 2 * Math.PI * (start + y) / fullLength + phase);
                        if (y === lineWidth / 2)
                            ctx.moveTo(waveX, y);
                        else
                            ctx.lineTo(waveX, y);
                    }
                } else {
                    const centerY = height / 2;
                    for (let x = lineWidth / 2; x <= width - lineWidth / 2; x += 1) {
                        const waveY = centerY + amplitude * Math.sin(frequency * 2 * Math.PI * x / fullLength + phase);
                        if (x === lineWidth / 2)
                            ctx.moveTo(x, waveY);
                        else
                            ctx.lineTo(x, waveY);
                    }
                }

                ctx.stroke();
            }

            FrameAnimation {
                running: wave.visible
                onTriggered: wave.requestPaint()
            }
        }
    }
}
