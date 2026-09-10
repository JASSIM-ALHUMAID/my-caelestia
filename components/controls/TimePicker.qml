pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: root

    // "HH:mm", 24 hour. Invalid input falls back to 00:00.
    property string time: "00:00"
    property int minuteStep: 5
    // Two digits never need the 100px CustomSpinBox default
    property real fieldWidth: 48

    readonly property int hour: root.parseComponent(0, 23)
    readonly property int minute: root.parseComponent(1, 59)

    signal timeModified(time: string)

    function parseComponent(index: int, max: int): int {
        const value = Number((root.time ?? "").split(":")[index]);
        if (!Number.isFinite(value))
            return 0;
        return Math.max(0, Math.min(max, Math.floor(value)));
    }

    function formatTime(hour: int, minute: int): string {
        return `${root.pad(hour)}:${root.pad(minute)}`;
    }

    function pad(value: real): string {
        return Math.round(value).toString().padStart(2, "0");
    }

    spacing: Tokens.spacing.small

    CustomSpinBox {
        min: 0
        max: 23
        step: 1
        fieldWidth: root.fieldWidth
        value: root.hour
        textFormatter: root.pad
        onValueModified: v => root.timeModified(root.formatTime(v, root.minute))
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: ":"
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.medium
    }

    CustomSpinBox {
        min: 0
        max: 59
        step: root.minuteStep
        fieldWidth: root.fieldWidth
        value: root.minute
        textFormatter: root.pad
        onValueModified: v => root.timeModified(root.formatTime(root.hour, v))
    }
}
