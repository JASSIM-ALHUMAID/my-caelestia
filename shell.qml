//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import Quickshell
import qs.services
import qs.modules.screensaver

ShellRoot {
    // Forces the HyprSunset singleton alive at startup. Singletons are created lazily, and
    // its only other references are the utilities toggle and the Nexus page - without this
    // the schedule wouldn't run (and IPC wouldn't register) until one of those was opened.
    readonly property var hyprSunsetService: HyprSunset
    // Forces the CountdownTimer singleton alive so its timer ticks and toasts with no UI open.
    readonly property var countdownTimerService: CountdownTimer
    // Forces Sounds alive so the startup chime fires at all.
    readonly property var soundsService: Sounds
    // Forces the Screensaver singleton alive so its idle monitor and overlay windows exist even
    // with no UI open.
    readonly property var screensaverService: Screensaver

    settings.watchFiles: true

    GSFLoader {}
    ServiceLoader {}

    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    ConfigToasts {}
    Shortcuts {}
    BatteryMonitor {}
    HyprVarsWriter {}
    SyncApps {}
    IdleMonitors {
        lock: lock
    }
}
