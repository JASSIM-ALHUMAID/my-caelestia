pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia.Internal
import qs.utils

Singleton {
    id: root

    // Gates the upower CLI polling only. Sampling runs unconditionally — it used to be
    // gated on this too, which meant history was recorded only while the Nexus battery
    // page happened to be open, so the charts could never fill.
    property int refCount: 0

    readonly property real percentage: UPower.displayDevice.percentage * 100
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)
    readonly property int timeToEmpty: UPower.displayDevice.timeToEmpty
    readonly property int timeToFull: UPower.displayDevice.timeToFull

    // Properties read from upower CLI (not available via QML API). -1 means "unknown" —
    // never let a failed parse collapse to 0, or the UI reports a confident wrong number.
    property int chargeCycles: -1
    property real energy: -1
    property real energyFull: -1
    property real energyFullDesign: -1
    property real capacity: -1
    property string technology: ""

    readonly property real health: energyFull > 0 && energyFullDesign > 0 ? (energyFull / energyFullDesign * 100) : -1

    // UPower.displayDevice reads back 0% for the first moments after startup. Sampling that
    // puts a spike down to zero at the left edge of every chart, so hold off until it
    // resolves — _lastSampleTime doesn't advance, so the first real sample lands promptly.
    readonly property bool sampleReady: UPower.displayDevice.isLaptopBattery && percentage > 0

    // The timer only ticks every 5 min, so without this the first sample of a session would
    // wait up to that long for the battery to become readable
    onSampleReadyChanged: {
        if (sampleReady)
            root._tick();
    }

    readonly property alias history24h: buffer24h
    readonly property alias history7d: buffer7d
    readonly property alias historyToday: bufferToday
    readonly property alias historyCharging24h: chargingBuffer24h
    readonly property alias historyCharging7d: chargingBuffer7d
    readonly property alias historyChargingToday: chargingBufferToday

    // Bucket geometry. The buffers hold one value per time bucket, not one per sample —
    // 24h/today at 5 min, 7d at 30 min. Pushing raw samples into the 7d buffer meant it
    // only ever held the most recent 337 of ~2016 samples, i.e. about 28 hours.
    readonly property int bucketShort: 300
    readonly property int bucketLong: 1800
    readonly property int historyLength24h: 288
    readonly property int historyLength7d: 336

    // Wall-clock span each buffer actually covers, in unix seconds, so the charts can
    // label a real axis instead of a fixed guess. start === end means "no data".
    property real range24hStart: 0
    property real range24hEnd: 0
    property real rangeTodayStart: 0
    property real rangeTodayEnd: 0
    property real range7dStart: 0
    property real range7dEnd: 0

    property var _historyData: []
    property bool _initialized: false
    property bool _loaded: false
    property bool _deviceResolved: false
    property real _lastSampleTime: 0
    property real _lastUpowerRefreshTime: 0
    property string _devicePath: "/org/freedesktop/UPower/devices/battery_BAT0"

    // State, not config: this file is rewritten continuously, and the config dir is a
    // symlink into the repo checkout. Paths.state is the convention the rest of the shell
    // uses (see Notifs.qml).
    readonly property string _historyPath: `${Paths.state}/battery-history.json`

    CircularBuffer {
        id: buffer24h

        capacity: root.historyLength24h + 1
    }

    CircularBuffer {
        id: buffer7d

        capacity: root.historyLength7d + 1
    }

    CircularBuffer {
        id: chargingBuffer24h

        capacity: root.historyLength24h + 1
    }

    CircularBuffer {
        id: chargingBuffer7d

        capacity: root.historyLength7d + 1
    }

    CircularBuffer {
        id: bufferToday

        capacity: root.historyLength24h + 1
    }

    CircularBuffer {
        id: chargingBufferToday

        capacity: root.historyLength24h + 1
    }

    FileView {
        id: historyFile

        path: root._historyPath
        printErrors: false
        atomicWrites: true

        onLoaded: {
            root._loaded = true;

            const content = historyFile.text();
            if (!content)
                return;

            try {
                const data = JSON.parse(content);
                if (!data || !Array.isArray(data.samples))
                    return;

                // Merge rather than replace — the reload is async, so the first sample of
                // this session may already have been pushed by the time it completes
                const merged = data.samples.concat(root._historyData);
                merged.sort((a, b) => a.t - b.t);
                root._historyData = merged;

                root._compactHistory();
                root._rebuildBuffers();
            } catch (e) {
                console.warn("BatteryHistory: Failed to parse history file:", e);
            }
        }

        onLoadFailed: root._loaded = true
    }

    Process {
        id: deviceProc

        // Hardcoding BAT0 leaves every detail row at N/A on machines whose battery is
        // BAT1, macsmc-battery, etc
        command: ["upower", "-e"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const path = line.trim();
                    if (path.includes("/devices/battery_")) {
                        root._devicePath = path;
                        break;
                    }
                }
                root._deviceResolved = true;
                upowerProc.running = true;
            }
        }
    }

    Process {
        id: upowerProc

        command: ["upower", "-i", root._devicePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                for (const line of lines) {
                    const trimmed = line.trim();
                    if (trimmed.startsWith("charge-cycles:"))
                        root.chargeCycles = root._parseField(trimmed, true);
                    else if (trimmed.startsWith("energy:"))
                        root.energy = root._parseField(trimmed, false);
                    else if (trimmed.startsWith("energy-full:"))
                        root.energyFull = root._parseField(trimmed, false);
                    else if (trimmed.startsWith("energy-full-design:"))
                        root.energyFullDesign = root._parseField(trimmed, false);
                    else if (trimmed.startsWith("capacity:"))
                        root.capacity = root._parseField(trimmed, false);
                    else if (trimmed.startsWith("technology:"))
                        root.technology = trimmed.split(":").slice(1).join(":").trim();
                }
            }
        }
    }

    // Every gate inside _tick() is on a 300s multiple, so a faster timer only bought extra
    // wakeups. triggeredOnStart still runs init immediately.
    Timer {
        interval: 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick()
    }

    function _tick(): void {
        const now = Date.now() / 1000;

        if (!root._initialized) {
            root._initialized = true;
            Quickshell.execDetached(["mkdir", "-p", Paths.state]);
            historyFile.reload();
            root._refreshUpower();
            root._lastUpowerRefreshTime = now;
        }

        if (root.sampleReady && now - root._lastSampleTime >= root.bucketShort) {
            root._lastSampleTime = now;
            root._historyData.push({
                "t": Math.floor(now),
                "p": root.percentage,
                "c": root.chargeCycles,
                "s": root.charging ? 1 : 0
            });
            root._compactHistory();
            root._rebuildBuffers();

            // Held off until the file has had its chance to load, so the first save
            // can't clobber the history it is about to be merged with
            if (root._loaded)
                root._saveHistory();
        }

        // The CLI poll is the expensive half — every 5 min while something is watching,
        // otherwise a slow trickle so the detail rows aren't stale on open and samples
        // still carry a real cycle count
        if (now - root._lastUpowerRefreshTime >= (root.refCount > 0 ? 300 : 1800)) {
            root._refreshUpower();
            root._lastUpowerRefreshTime = now;
        }
    }

    function _parseField(line: string, isInt: bool): real {
        const raw = line.split(":").slice(1).join(":").trim();
        const value = isInt ? parseInt(raw) : parseFloat(raw);
        return isNaN(value) ? -1 : value;
    }

    function _refreshUpower(): void {
        if (root._deviceResolved)
            upowerProc.running = true;
        else
            deviceProc.running = true;
    }

    // Derives one buffer pair from _historyData by wall-clock bucket. Returns the span
    // actually covered so the caller can label the axis.
    function _fillBuckets(buf: CircularBuffer, chargingBuf: CircularBuffer, cutoff: real, bucketSeconds: int, slots: int): var {
        const percs = new Array(slots).fill(null);
        const charges = new Array(slots).fill(0);

        for (let i = 0; i < root._historyData.length; i++) {
            const sample = root._historyData[i];
            const slot = Math.floor((sample.t - cutoff) / bucketSeconds);
            if (slot < 0 || slot >= slots)
                continue;

            // Last sample in a bucket wins
            percs[slot] = sample.p;
            charges[slot] = sample.s || 0;
        }

        let first = -1;
        let last = -1;
        for (let i = 0; i < slots; i++) {
            if (percs[i] === null)
                continue;
            if (first < 0)
                first = i;
            last = i;
        }

        if (first < 0) {
            buf.setValues([]);
            chargingBuf.setValues([]);
            return {
                "start": 0,
                "end": 0
            };
        }

        // Carry the last known value across interior gaps — percentage is continuous, and
        // holding it keeps buffer index proportional to elapsed time, which is what makes
        // the x-axis labels mean anything. Trailing slots past the newest sample are left
        // off rather than flat-lined to now.
        let lastPerc = percs[first];
        let lastCharge = charges[first];
        for (let i = first; i <= last; i++) {
            if (percs[i] === null) {
                percs[i] = lastPerc;
                charges[i] = lastCharge;
            } else {
                lastPerc = percs[i];
                lastCharge = charges[i];
            }
        }

        // One signal per buffer instead of one per value — push() is built for streaming,
        // and a rebuild of all six buffers used to fire ~1600 of them
        buf.setValues(percs.slice(first, last + 1));
        chargingBuf.setValues(charges.slice(first, last + 1));

        return {
            "start": cutoff + first * bucketSeconds,
            "end": cutoff + (last + 1) * bucketSeconds
        };
    }

    function _rebuildBuffers(): void {
        const now = Date.now() / 1000;

        const midnightDate = new Date();
        midnightDate.setHours(0, 0, 0, 0);
        const midnight = midnightDate.getTime() / 1000;

        const r24 = root._fillBuckets(buffer24h, chargingBuffer24h, now - 86400, root.bucketShort, root.historyLength24h);
        root.range24hStart = r24.start;
        root.range24hEnd = r24.end;

        // Recomputed every rebuild, so the day rolls over on its own at midnight instead
        // of carrying yesterday's tail forward forever
        const todaySlots = Math.max(1, Math.min(root.historyLength24h, Math.ceil((now - midnight) / root.bucketShort)));
        const rToday = root._fillBuckets(bufferToday, chargingBufferToday, midnight, root.bucketShort, todaySlots);
        root.rangeTodayStart = rToday.start;
        root.rangeTodayEnd = rToday.end;

        const r7 = root._fillBuckets(buffer7d, chargingBuffer7d, now - 604800, root.bucketLong, root.historyLength7d);
        root.range7dStart = r7.start;
        root.range7dEnd = r7.end;
    }

    // Drops anything past 7 days, and thins what is left to the finest resolution any chart
    // can actually render: 5 min inside the last 24h, 30 min before that. Samples are stored
    // ascending, so "last in bucket" is just overwrite-previous, and the pass is idempotent.
    function _compactHistory(): void {
        const now = Date.now() / 1000;
        const cutoff7d = now - 604800;
        const cutoff24h = now - 86400;

        let writeIndex = 0;
        let lastBucket = -1;

        for (let i = 0; i < root._historyData.length; i++) {
            const sample = root._historyData[i];
            if (sample.t < cutoff7d)
                continue;

            if (sample.t >= cutoff24h) {
                root._historyData[writeIndex++] = sample;
                continue;
            }

            const bucket = Math.floor(sample.t / root.bucketLong);
            if (bucket === lastBucket) {
                root._historyData[writeIndex - 1] = sample;
            } else {
                root._historyData[writeIndex++] = sample;
                lastBucket = bucket;
            }
        }

        root._historyData.length = writeIndex;
    }

    function _saveHistory(): void {
        historyFile.setText(JSON.stringify({
            "samples": root._historyData
        }));
    }
}
