import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import qs.services

Scope {
    id: root

    // Forces the BatteryHistory singleton alive at startup. It samples on its own timer,
    // but a singleton is created lazily on first use — without this the only reference is
    // the Nexus battery page, so history would again only accrue while that page is open.
    readonly property var historyService: BatteryHistory

    readonly property list<var> warnLevels: [...GlobalConfig.general.battery.warnLevels].sort((a, b) => a.level - b.level)
    property real lastPercentage: 100

    function handleBatteryWarnings(): void {
        const p = UPower.displayDevice.percentage * 100;

        if (!UPower.onBattery) {
            root.lastPercentage = p;
            return;
        }

        for (const level of root.warnLevels) {
            if (p <= level.level && root.lastPercentage > level.level) {
                Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                break;
            }
        }

        if (!hibernateTimer.running && p <= GlobalConfig.general.battery.criticalLevel) {
            Toaster.toast(qsTr("Hibernating in 5 seconds"), qsTr("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
            hibernateTimer.start();
        }

        root.lastPercentage = p;
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (!UPower.displayDevice.ready)
                return;

            if (UPower.onBattery) {
                Sounds.play(GlobalConfig.utilities.sounds.chargerUnplugged);
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger unplugged"), qsTr("Battery is discharging"), "power_off");
                root.handleBatteryWarnings();
            } else {
                Sounds.play(GlobalConfig.utilities.sounds.chargerPlugged);
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger plugged in"), qsTr("Battery is charging"), "power");
                // Plugging in inside the 5s grace window cancels the pending hibernate
                hibernateTimer.stop();
                root.lastPercentage = 100;
            }
        }

        target: UPower
    }

    Connections {
        function onReadyChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Connections {
        function onPercentageChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: Quickshell.execDetached(["systemctl", "hibernate"])
    }
}
