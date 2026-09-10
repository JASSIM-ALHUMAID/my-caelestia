pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Internal
import qs.components
import qs.components.misc
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages.battery

PageBase {
    id: root

    title: qsTr("Battery")

    readonly property list<MenuItem> styleItems: [
        MenuItem { text: qsTr("Vertical tank"); property int value: 0 },
        MenuItem { text: qsTr("Horizontal fill"); property int value: 1 },
        MenuItem { text: qsTr("Circular progress"); property int value: 2 }
    ]

    readonly property list<MenuItem> chartItems: [
        MenuItem { text: qsTr("Current day"); property int value: 1 },
        MenuItem { text: qsTr("Last 24 hours"); property int value: 0 },
        MenuItem { text: qsTr("Last 7 days"); property int value: 2 }
    ]

    readonly property int batteryStyle: Config.background.desktopBattery.style
    readonly property int batteryIconWidth: root.batteryStyle === 1 ? 240 : 180
    readonly property int batteryIconHeight: root.batteryStyle === 1 ? 120 : 220
    property int activeChart: 1  // 0=24h, 1=today, 2=7d

    function itemForStyle(val: int): MenuItem {
        for (let i = 0; i < styleItems.length; i++) {
            if (styleItems[i].value === val)
                return styleItems[i];
        }
        return styleItems[0];
    }

    function itemForChart(val: int): MenuItem {
        for (let i = 0; i < chartItems.length; i++) {
            if (chartItems[i].value === val)
                return chartItems[i];
        }
        return chartItems[0];
    }

    // Labels come from the span the buffer actually covers, not a fixed guess — the
    // buffers only reach back as far as there is recorded history
    function timeLabels(start: real, end: real, count: int, format: string): var {
        if (end <= start)
            return [];

        const result = [];
        for (let i = 0; i < count; i++) {
            const t = start + (end - start) * i / (count - 1);
            result.push(Qt.formatDateTime(new Date(t * 1000), format));
        }
        return result;
    }

    function dayLabels(start: real, end: real): var {
        const daysCovered = Math.max(1, Math.round((end - start) / 86400));
        return timeLabels(start, end, Math.min(8, daysCovered + 1), "ddd\nMMM d");
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Ref {
            service: BatteryHistory
        }

        // Battery icon section
        SettingsSection {
            first: true
            expanded: true
            title: qsTr("Battery")

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.batteryIconHeight

                BatteryIcon {
                    anchors.centerIn: parent
                    width: Math.min(root.batteryIconWidth, parent.width)
                    height: root.batteryIconHeight
                    percentage: BatteryHistory.percentage
                    charging: BatteryHistory.charging
                    style: root.batteryStyle
                }
            }
        }

        // Current status
        SettingsSection {
            title: qsTr("Current status")

            SelectRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Icon style")
                subtext: qsTr("Choose battery visualization")
                menuItems: root.styleItems
                active: root.itemForStyle(root.batteryStyle)
                onSelected: item => GlobalConfig.background.desktopBattery.style = item.value
            }

            InfoRow {
                Layout.fillWidth: true
                label: qsTr("Status")
                value: BatteryHistory.charging ? qsTr("Charging") : qsTr("Discharging")
            }

            InfoRow {
                Layout.fillWidth: true
                label: qsTr("Charge cycles")
                value: BatteryHistory.chargeCycles >= 0 ? BatteryHistory.chargeCycles.toString() : qsTr("N/A")
            }

            InfoRow {
                Layout.fillWidth: true
                label: qsTr("Time remaining")
                value: {
                    if (BatteryHistory.charging) {
                        if (BatteryHistory.timeToFull === 0) {
                            if (BatteryHistory.percentage >= 99)
                                return qsTr("Full");
                            return qsTr("Estimating…");
                        }
                        const hours = Math.floor(BatteryHistory.timeToFull / 3600);
                        const minutes = Math.floor((BatteryHistory.timeToFull % 3600) / 60);
                        return qsTr("%1h %2m").arg(hours).arg(minutes);
                    } else {
                        if (BatteryHistory.timeToEmpty === 0) {
                            if (BatteryHistory.percentage <= 1)
                                return qsTr("Empty");
                            return qsTr("Estimating…");
                        }
                        const hours = Math.floor(BatteryHistory.timeToEmpty / 3600);
                        const minutes = Math.floor((BatteryHistory.timeToEmpty % 3600) / 60);
                        return qsTr("%1h %2m").arg(hours).arg(minutes);
                    }
                }
            }

            InfoRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Health")
                value: BatteryHistory.health > 0 ? Math.round(BatteryHistory.health) + "%" : qsTr("N/A")
            }
        }

        // Battery details
        SettingsSection {
            title: qsTr("Battery details")

            InfoRow {
                Layout.fillWidth: true
                first: true
                label: qsTr("Energy")
                value: BatteryHistory.energy > 0 ? BatteryHistory.energy.toFixed(1) + " Wh" : qsTr("N/A")
            }

            InfoRow {
                Layout.fillWidth: true
                label: qsTr("Full capacity")
                value: BatteryHistory.energyFull > 0 ? BatteryHistory.energyFull.toFixed(1) + " Wh" : qsTr("N/A")
            }

            InfoRow {
                Layout.fillWidth: true
                label: qsTr("Design capacity")
                value: BatteryHistory.energyFullDesign > 0 ? BatteryHistory.energyFullDesign.toFixed(1) + " Wh" : qsTr("N/A")
            }

            InfoRow {
                Layout.fillWidth: true
                label: qsTr("Wear level")
                value: {
                    if (BatteryHistory.energyFull > 0 && BatteryHistory.energyFullDesign > 0)
                        return (100 - BatteryHistory.energyFull / BatteryHistory.energyFullDesign * 100).toFixed(1) + "%";
                    return qsTr("N/A");
                }
            }

            InfoRow {
                Layout.fillWidth: true
                last: true
                label: qsTr("Technology")
                value: BatteryHistory.technology || qsTr("N/A")
            }
        }

        // History charts section
        SettingsSection {
            title: qsTr("History charts")

            // A bare StyledSwitch renders no text — it defines only an indicator, and it is

            // ToggleRow that supplies the contentItem. Three unlabelled toggles emulating a

            // radio group was the wrong control here anyway.

            SelectRow {
                Layout.fillWidth: true
                first: true
                last: true
                label: qsTr("Range")
                subtext: qsTr("Time span shown below")
                menuItems: root.chartItems
                active: root.itemForChart(root.activeChart)
                onSelected: item => root.activeChart = item.value
            }

            // Current day history chart

            BatteryChart {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                Layout.preferredHeight: 280
                visible: root.activeChart === 1
                source: BatteryHistory.historyToday
                chargingSource: BatteryHistory.historyChargingToday
                lineColor: Colours.palette.m3primary
                maxValue: 100
                xLabels: root.timeLabels(BatteryHistory.rangeTodayStart, BatteryHistory.rangeTodayEnd, 5, "hh:mm")
            }

            // 24-hour history chart

            BatteryChart {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                Layout.preferredHeight: 280
                visible: root.activeChart === 0
                source: BatteryHistory.history24h
                chargingSource: BatteryHistory.historyCharging24h
                lineColor: Colours.palette.m3primary
                maxValue: 100
                xLabels: root.timeLabels(BatteryHistory.range24hStart, BatteryHistory.range24hEnd, 5, "hh:mm")
            }

            // 7-day history chart

            BatteryChart {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                Layout.preferredHeight: 280
                visible: root.activeChart === 2
                source: BatteryHistory.history7d
                chargingSource: BatteryHistory.historyCharging7d
                lineColor: Colours.palette.m3tertiary
                maxValue: 100
                xLabels: root.dayLabels(BatteryHistory.range7dStart, BatteryHistory.range7dEnd)
            }
        }
    }
}
