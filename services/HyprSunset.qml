pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.services

Singleton {
    id: root

    readonly property int minTemperature: 1000
    readonly property int maxTemperature: 6500
    readonly property int minGamma: 25
    readonly property int maxGamma: 100

    readonly property var cfg: GlobalConfig.utilities.hyprsunset

    // Suppresses startup toasts while the initial state is being applied
    property bool started: false

    readonly property bool enabled: cfg.enabled
    readonly property bool automatic: cfg.automatic
    readonly property int temperature: cfg.temperature
    readonly property int gamma: cfg.gamma

    readonly property int nowMinutes: Time.hours * 60 + Time.minutes
    readonly property int fromMinutes: parseTime(cfg.from)
    readonly property int toMinutes: parseTime(cfg.to)

    // Whether the schedule says night light should be on right now. Handles windows
    // that wrap past midnight (from > to).
    readonly property bool shouldBeOn: {
        if (fromMinutes === toMinutes)
            return false;
        if (fromMinutes < toMinutes)
            return nowMinutes >= fromMinutes && nowMinutes < toMinutes;
        return nowMinutes >= fromMinutes || nowMinutes < toMinutes;
    }

    function parseTime(time: string): int {
        const parts = (time ?? "").split(":");
        const hours = Number(parts[0]);
        const minutes = Number(parts[1]);
        if (!Number.isFinite(hours) || !Number.isFinite(minutes))
            return 0;
        return Math.max(0, Math.min(23, Math.floor(hours))) * 60 + Math.max(0, Math.min(59, Math.floor(minutes)));
    }

    function toggle(): void {
        cfg.enabled = !cfg.enabled;
    }

    function enable(): void {
        cfg.enabled = true;
    }

    function disable(): void {
        cfg.enabled = false;
    }

    function setTemperature(kelvin: int): void {
        cfg.temperature = Math.max(minTemperature, Math.min(maxTemperature, Math.round(kelvin)));
    }

    function setGamma(percent: int): void {
        cfg.gamma = Math.max(minGamma, Math.min(maxGamma, Math.round(percent)));
    }

    // hyprsunset does not unlink its IPC socket when it exits, so a daemon that dies
    // uncleanly leaves a dead .hyprsunset.sock behind at the same path. The next daemon
    // can then be running - pidof succeeds - while every `hyprctl hyprsunset` call fails
    // with ECONNREFUSED. That failure is invisible here: the output is discarded and the
    // retry loop below simply gives up, so the toggle flips cfg.enabled and never reaches
    // the display. Probe the IPC instead of trusting pidof, and clear the stale socket.
    //
    // Killing an unreachable daemon is also the only way to turn night light off, since
    // that path is IPC-only too; releasing gamma control restores the default ramp.
    readonly property string reapStaleDaemon: `sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.hyprsunset.sock"
if pidof hyprsunset >/dev/null 2>&1 && ! hyprctl hyprsunset temperature >/dev/null 2>&1; then
    pkill -x hyprsunset
    rm -f "$sock"
fi
`

    // Runs hyprsunset, starting the daemon on demand. Never kills a healthy daemon -
    // turning night light off resets the matrix instead, so it stays warm for the next
    // toggle; only an unreachable one is reaped by reapStaleDaemon above.
    function apply(): void {
        if (cfg.enabled)
            Quickshell.execDetached(["sh", "-c", `${reapStaleDaemon}pidof hyprsunset >/dev/null 2>&1 || { rm -f "$sock"; setsid -f hyprsunset --identity >/dev/null 2>&1; }
for i in $(seq 20); do
    hyprctl hyprsunset temperature ${temperature} >/dev/null 2>&1 && break
    sleep 0.1
done
hyprctl hyprsunset gamma ${gamma} >/dev/null 2>&1`]);
        else
            Quickshell.execDetached(["sh", "-c", `${reapStaleDaemon}pidof hyprsunset >/dev/null 2>&1 || exit 0
hyprctl hyprsunset identity true >/dev/null 2>&1
hyprctl hyprsunset gamma ${maxGamma} >/dev/null 2>&1`]);
    }

    // Coalesce rapid changes (slider drags) into a single invocation
    function queueApply(): void {
        applyTimer.restart();
    }

    Component.onCompleted: {
        // Bring the schedule up to date before toasts are armed, so a boot inside the
        // window doesn't announce itself
        if (automatic)
            cfg.enabled = shouldBeOn;
        started = true;
        apply();
    }

    onEnabledChanged: {
        apply();

        if (started) {
            Sounds.play(enabled ? GlobalConfig.utilities.sounds.serviceOn : GlobalConfig.utilities.sounds.serviceOff);
            if (GlobalConfig.utilities.toasts.hyprsunsetChanged) {
                if (enabled)
                    Toaster.toast(qsTr("Night light enabled"), qsTr("Colour temperature set to %1K").arg(temperature), "bedtime");
                else
                    Toaster.toast(qsTr("Night light disabled"), qsTr("Colour temperature restored"), "bedtime");
            }
        }
    }

    onTemperatureChanged: {
        if (enabled)
            queueApply();
    }

    onGammaChanged: {
        if (enabled)
            queueApply();
    }

    // Only act on transitions, so a manual toggle inside the window sticks until the
    // next boundary instead of being overridden every minute.
    onShouldBeOnChanged: {
        if (automatic)
            cfg.enabled = shouldBeOn;
    }

    onAutomaticChanged: {
        if (automatic)
            cfg.enabled = shouldBeOn;
    }

    Timer {
        id: applyTimer

        interval: 150
        onTriggered: root.apply()
    }

    IpcHandler {
        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.enable();
        }

        function disable(): void {
            root.disable();
        }

        function setTemperature(kelvin: int): void {
            root.setTemperature(kelvin);
        }

        function setGamma(percent: int): void {
            root.setGamma(percent);
        }

        function setAutomatic(automatic: bool): void {
            root.cfg.automatic = automatic;
        }

        function setSchedule(from: string, to: string): void {
            root.cfg.from = from;
            root.cfg.to = to;
        }

        target: "hyprSunset"
    }
}
