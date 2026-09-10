pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config

Singleton {
    id: root

    readonly property bool running: props.endsAt > 0
    readonly property bool paused: props.endsAt === 0 && props.remaining > 0
    readonly property bool active: running || paused
    // Last-set duration in seconds. Exposed so the popout can mark the matching preset active.
    readonly property alias duration: props.duration
    readonly property int remaining: {
        if (running) {
            // Reading Time.date is what re-evaluates this binding every second, but its value
            // is the clock's last tick and lags real time by up to that second — using it for
            // the arithmetic rounds a fresh 90s timer up to 1:31. Take the later of the two.
            const tick = Time.date.getTime();
            return Math.max(0, Math.ceil((props.endsAt - Math.max(tick, Date.now())) / 1000));
        }
        if (paused)
            return Math.ceil(props.remaining);
        return props.duration || GlobalConfig.services.timerDefaultDuration;
    }

    function start(seconds: int): void {
        if (seconds <= 0)
            return;
        props.duration = seconds;
        props.remaining = 0;
        props.endsAt = Date.now() + seconds * 1000;
    }

    function pause(): void {
        if (!running)
            return;
        props.remaining = remaining;
        props.endsAt = 0;
    }

    function resume(): void {
        if (!paused)
            return;
        props.endsAt = Date.now() + props.remaining * 1000;
        props.remaining = 0;
    }

    function toggle(): void {
        if (running)
            pause();
        else if (paused)
            resume();
        else
            start(props.duration || GlobalConfig.services.timerDefaultDuration);
    }

    function reset(): void {
        props.endsAt = 0;
        props.remaining = 0;
    }

    function addTime(seconds: int): void {
        if (running) {
            props.endsAt = Math.max(Date.now(), props.endsAt + seconds * 1000);
        } else if (paused) {
            props.remaining = Math.max(0, props.remaining + seconds);
        } else {
            // Seed from `remaining`, not `props.duration` — an untouched timer displays the
            // configured default while `props.duration` is still 0, and scrolling has to move
            // the number the user can actually see.
            props.duration = Math.max(0, remaining + seconds);
        }
    }

    function fire(): void {
        // Report the duration that just elapsed: `remaining` is 0 by definition at this point.
        const elapsed = props.duration;
        props.endsAt = 0;
        props.remaining = 0;

        const mins = Math.round(elapsed / 60);
        Toaster.toast(qsTr("Timer finished"), mins >= 1 ? qsTr("%1 min elapsed").arg(mins) : qsTr("%1 s elapsed").arg(Math.round(elapsed)), "timer", Toast.Info);

        // Past the ambient-sound master switch: this alarm was explicitly asked for and has its
        // own toggle.
        if (GlobalConfig.services.timerSoundEnabled)
            Sounds.playForced(GlobalConfig.services.timerSound);
    }

    function formatted(): string {
        const secs = remaining;
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        const s = secs % 60;
        if (h > 0)
            return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
        return `${m}:${String(s).padStart(2, "0")}`;
    }

    function parseDuration(str: string): int {
        const trimmed = str.trim().toLowerCase();
        if (trimmed.length === 0)
            return 0;

        const match = trimmed.match(/^(\d+(?:\.\d+)?)\s*([smh]?)$/);
        if (!match)
            return 0;

        const value = parseFloat(match[1]);
        switch (match[2]) {
        case "s":
            return Math.round(value);
        case "m":
            return Math.round(value * 60);
        case "h":
            return Math.round(value * 3600);
        default:
            return Math.round(value * 60);
        }
    }

    PersistentProperties {
        id: props

        property real endsAt: 0
        property real remaining: 0
        property real duration: 0

        reloadableId: "countdownTimer"
    }

    Connections {
        function onDateChanged(): void {
            if (props.endsAt > 0 && Date.now() >= props.endsAt)
                root.fire();
        }

        target: Time // qmllint disable incompatible-type
    }

    IpcHandler {
        function start(duration: string): string {
            const seconds = root.parseDuration(duration);
            if (seconds <= 0)
                return "invalid duration";
            root.start(seconds);
            return root.formatted();
        }

        function pause(): void {
            root.pause();
        }

        function resume(): void {
            root.resume();
        }

        function toggle(): void {
            root.toggle();
        }

        function reset(): void {
            root.reset();
        }

        function status(): string {
            if (root.running)
                return `running ${root.formatted()}`;
            if (root.paused)
                return `paused ${root.formatted()}`;
            return "idle";
        }

        target: "timer"
    }
}
