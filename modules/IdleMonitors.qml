pragma ComponentBehavior: Bound

import "lock"
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.Internal
import qs.services

Scope {
    id: root

    required property Lock lock
    // Screen-off and suspend are conveniences, so audio silences them. The lock is a security
    // boundary and gets its own flag, or leaving music on would mean the session never locks.
    readonly property bool enabled: !GlobalConfig.general.idle.inhibitWhenAudio || !Audio.hasActiveAudio
    readonly property bool lockEnabled: !GlobalConfig.general.idle.inhibitLockWhenAudio || !Audio.hasActiveAudio

    LogindManager {
        onAboutToSleep: {
            if (GlobalConfig.general.idle.lockBeforeSleep)
                root.lock.lock.locked = true;
        }
        onResumed: root.lock.lock.resumed()
        onLockRequested: root.lock.lock.locked = true
        onUnlockRequested: root.lock.lock.unlock()
    }

    IdleMonitor {
        enabled: root.lockEnabled && GlobalConfig.general.idle.lockTimeout > 0
        timeout: GlobalConfig.general.idle.lockTimeout
        onIsIdleChanged: {
            if (isIdle)
                root.lock.lock.locked = true;
        }
    }

    IdleMonitor {
        enabled: root.enabled && GlobalConfig.general.idle.screenOffTimeout > 0
        timeout: GlobalConfig.general.idle.screenOffTimeout
        onIsIdleChanged: Hypr.setDpms(isIdle ? "off" : "on")
    }

    IdleMonitor {
        enabled: root.enabled && GlobalConfig.general.idle.suspendTimeout > 0
        timeout: GlobalConfig.general.idle.suspendTimeout
        onIsIdleChanged: {
            if (isIdle)
                Quickshell.execDetached(["systemctl", "suspend-then-hibernate"]);
        }
    }
}
