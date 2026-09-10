pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Internal
import qs.components
import qs.services

StyledRect {
    id: root

    required property CircularBuffer source
    required property color lineColor
    property CircularBuffer chargingSource
    property color chargingColor: Colours.palette.m3tertiary
    property color dischargingColor: Colours.palette.m3primary
    property real fillAlpha: 0.2
    property real maxValue: 100
    property real minValue: 0
    property bool showGrid: true
    property bool showYAxis: true
    property int gridLines: 4
    property list<string> xLabels: []

    // Gutter the plot is inset by, sized to the widest tick label
    readonly property real yAxisWidth: showYAxis ? yLabelMetrics.width + Tokens.spacing.small : 0
    readonly property bool multilineXAxis: {
        for (const label of xLabels) {
            if (label.includes("\n"))
                return true;
        }
        return false;
    }
    readonly property real xAxisHeight: xLabelMetrics.height * (multilineXAxis ? 2 : 1) + Tokens.spacing.extraSmall

    color: Colours.tPalette.m3surfaceContainerHigh
    radius: Tokens.rounding.extraLarge

    TextMetrics {
        id: yLabelMetrics

        font: Tokens.font.label.medium
        text: "100%"
    }

    TextMetrics {
        id: xLabelMetrics

        font: Tokens.font.label.medium
        text: "00:00"
    }

    RowLayout {
        id: legend

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium
        visible: root.chargingSource !== null

        Repeater {
            model: [
                { "label": qsTr("On battery"), "colour": root.dischargingColor },
                { "label": qsTr("Charging"), "colour": root.chargingColor }
            ]

            delegate: RowLayout {
                id: legendItem

                required property var modelData

                spacing: Tokens.spacing.extraSmall

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: width / 2
                    color: legendItem.modelData.colour
                }

                StyledText {
                    text: legendItem.modelData.label
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    // Percentage ticks, one per grid line, sharing the Canvas's own line positions so the
    // labels stay glued to the rules as the chart resizes
    Repeater {
        // The canvas bails before drawing the grid when there is nothing to plot, so the
        // ticks would otherwise float against an empty card. The gutter stays reserved
        // either way, so no reflow when the first sample lands.
        model: root.showYAxis && root.source.count >= 2 ? root.gridLines + 1 : 0

        StyledText {
            required property int index

            readonly property real fraction: index / root.gridLines

            x: Tokens.padding.medium
            y: chartCanvas.y + fraction * chartCanvas.height - height / 2
            width: yLabelMetrics.width
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.maxValue - fraction * (root.maxValue - root.minValue)) + "%"
            font: Tokens.font.label.medium
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    Canvas {
        id: chartCanvas

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.medium + root.yAxisWidth
        anchors.bottomMargin: Tokens.padding.medium + root.xAxisHeight + Tokens.spacing.small
        // The topmost tick is centred on the first grid line, so half of it hangs above
        // the plot — without this it collides with the card edge
        anchors.topMargin: Tokens.padding.medium + legend.implicitHeight + Tokens.spacing.small + (root.showYAxis ? yLabelMetrics.height / 2 : 0)

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width;
            const h = height;
            const count = root.source.count;
            const range = Math.max(1e-6, root.maxValue - root.minValue);

            if (count < 2)
                return;

            if (root.showGrid) {
                ctx.strokeStyle = Qt.alpha(Colours.tPalette.m3outline, 0.3);
                ctx.lineWidth = 1;

                for (let i = 0; i <= root.gridLines; i++) {
                    const y = (i / root.gridLines) * h;
                    ctx.beginPath();
                    ctx.moveTo(0, y);
                    ctx.lineTo(w, y);
                    ctx.stroke();
                }
            }

            const step = root.source.count > 1 ? w / (root.source.count - 1) : 0;
            const hasChargingData = root.chargingSource && root.chargingSource.count >= count;

            if (hasChargingData) {
                // Draw color-coded segments
                let segStart = 0;
                let segCharging = root.chargingSource.at(0) === 1;

                for (let i = 1; i <= count; i++) {
                    const isCharging = i < count ? root.chargingSource.at(i) === 1 : !segCharging;
                    const segEnd = i;

                    if (isCharging !== segCharging || i === count) {
                        // Draw filled segment
                        ctx.beginPath();
                        for (let j = segStart; j < segEnd && j < count; j++) {
                            const x = j * step;
                            const val = root.source.at(j);
                            const y = h - ((val - root.minValue) / range) * h;

                            if (j === segStart)
                                ctx.moveTo(x, y);
                            else
                                ctx.lineTo(x, y);
                        }

                        const lastX = Math.min(segEnd - 1, count - 1) * step;
                        ctx.lineTo(lastX, h);
                        ctx.lineTo(segStart * step, h);
                        ctx.closePath();

                        const segColor = segCharging ? root.chargingColor : root.dischargingColor;
                        ctx.fillStyle = Qt.rgba(segColor.r, segColor.g, segColor.b, root.fillAlpha);
                        ctx.fill();

                        // Draw line segment
                        ctx.beginPath();
                        for (let j = segStart; j < segEnd && j < count; j++) {
                            const x = j * step;
                            const val = root.source.at(j);
                            const y = h - ((val - root.minValue) / range) * h;

                            if (j === segStart)
                                ctx.moveTo(x, y);
                            else
                                ctx.lineTo(x, y);
                        }

                        ctx.strokeStyle = segCharging ? root.chargingColor : root.dischargingColor;
                        ctx.lineWidth = 2;
                        ctx.stroke();

                        // Back up one so consecutive segments share their boundary point,
                        // otherwise the stroked line breaks at every charge/discharge flip
                        segStart = i - 1;
                        segCharging = isCharging;
                    }
                }
            } else {
                // Draw single color (fallback)
                ctx.beginPath();
                for (let i = 0; i < count; i++) {
                    const x = i * step;
                    const val = root.source.at(i);
                    const y = h - ((val - root.minValue) / range) * h;

                    if (i === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }

                const lastX = (count - 1) * step;
                ctx.lineTo(lastX, h);
                ctx.lineTo(0, h);
                ctx.closePath();

                ctx.fillStyle = Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, root.fillAlpha);
                ctx.fill();

                ctx.beginPath();
                for (let i = 0; i < count; i++) {
                    const x = i * step;
                    const val = root.source.at(i);
                    const y = h - ((val - root.minValue) / range) * h;

                    if (i === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }

                ctx.strokeStyle = root.lineColor;
                ctx.lineWidth = 2;
                ctx.stroke();
            }
        }

        Connections {
            target: root.source

            function onValuesChanged(): void {
                chartCanvas.requestPaint();
            }
        }

        Connections {
            target: root.chargingSource

            function onValuesChanged(): void {
                chartCanvas.requestPaint();
            }
        }

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: {
            if (visible)
                requestPaint()
        }
    }

    Connections {
        target: root

        function onLineColorChanged(): void { chartCanvas.requestPaint(); }
        function onChargingColorChanged(): void { chartCanvas.requestPaint(); }
        function onDischargingColorChanged(): void { chartCanvas.requestPaint(); }
        function onFillAlphaChanged(): void { chartCanvas.requestPaint(); }
        function onMinValueChanged(): void { chartCanvas.requestPaint(); }
        function onMaxValueChanged(): void { chartCanvas.requestPaint(); }
        function onShowGridChanged(): void { chartCanvas.requestPaint(); }
    }

    // "Collecting data" placeholder
    StyledText {
        anchors.centerIn: parent
        text: qsTr("Collecting data...")
        font: Tokens.font.body.small
        color: Colours.palette.m3outline
        visible: root.source.count < 2
    }

    Item {
        id: xAxis

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.padding.medium + root.yAxisWidth
        anchors.rightMargin: Tokens.padding.medium
        anchors.bottomMargin: Tokens.padding.medium
        height: root.xAxisHeight
        // Kept flush with the plot area, not the card, so the end labels still mark the
        // first and last plotted point

        Repeater {
            id: labelRepeater

            model: root.xLabels

            StyledText {
                required property int index
                required property var modelData

                readonly property real tickSpacing: root.xLabels.length > 1 ? xAxis.width / (root.xLabels.length - 1) : xAxis.width

                x: index === 0 ? 0 : index === root.xLabels.length - 1 ? xAxis.width - width : index * tickSpacing - width / 2
                width: Math.min(xAxis.width, tickSpacing)
                height: xAxis.height
                text: modelData
                font: Tokens.font.label.medium
                color: Colours.palette.m3onSurfaceVariant
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.HorizontalFit
                minimumPointSize: Tokens.font.label.small.pointSize
                maximumLineCount: root.multilineXAxis ? 2 : 1
                elide: Text.ElideRight
                clip: true
                // The end labels mark the first and last plotted point, which sit on the
                // chart edges — centring them in their own slot puts them half a slot off
                horizontalAlignment: index === 0 ? Text.AlignLeft : index === root.xLabels.length - 1 ? Text.AlignRight : Text.AlignHCenter
            }
        }
    }
}
