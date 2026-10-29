pragma Singleton

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils
import "../utils/scripts/wallpaper-selection.js" as Selection

Searcher {
    id: root

    readonly property string dirsConfigPath: `${Paths.config}/wallpaper-dirs.json`
    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property string videoFramesPath: `${Paths.cache}/wallpapers/frames`
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")
    property list<string> wallpaperDirs: []
    property var wallpaperDirEntries: []
    readonly property list<string> effectiveDirs: {
        const env = Quickshell.env("CAELESTIA_WALLPAPERS_DIR");
        if (env)
            return [env];
        return wallpaperDirEntries.filter(e => e.enabled !== false).map(e => e.path);
    }
    readonly property list<string> effectiveAbsDirs: effectiveDirs.map(d => Paths.absolutePath(d))
    readonly property string previewSmartArg: (GlobalConfig.services.modeOverride || !GlobalConfig.services.smartScheme) ? " --no-smart" : ""
    readonly property int imageFillMode: {
        switch (Config.background.fillMode) {
        case "fit": return Image.PreserveAspectFit;
        case "stretch": return Image.Stretch;
        case "center": return Image.Pad;
        case "tile": return Image.Tile;
        default: return Image.PreserveAspectCrop; // cover
        }
    }

    // Extracts a representative frame from the video "$1" into "$2" unless a current thumbnail exists.
    // Tries 1s in first (to skip fade-from-black intros), falls back to the first frame.
    readonly property string extractFrameScript: `mkdir -p "$(dirname "$2")"
if ! [ -f "$2" ] || [ "$(stat -c "%Y" "$1" 2>/dev/null || echo 0)" -gt "$(stat -c "%Y" "$2" 2>/dev/null || echo 0)" ] 2>/dev/null; then
    t="$2.$$.tmp"
    ffmpeg -y -loglevel error -ss 1 -i "$1" -frames:v 1 -c:v mjpeg -q:v 2 -f image2 "$t" 2> /dev/null
    [ -s "$t" ] || ffmpeg -y -loglevel error -i "$1" -frames:v 1 -c:v mjpeg -q:v 2 -f image2 "$t" || exit 1
    [ -s "$t" ] || exit 1
    mv -f "$t" "$2" || exit 1
fi`

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    readonly property string currentAnalysable: Images.isValidVideoByName(current) ? (videoFrames[current] ?? "") : current
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property var videoFrames: ({})
    property var frameQueue: []
    property bool _programmaticPending: false
    property bool pendingVideoAdvance: false
    property var _selectionCache: null

    signal wallpaperApplied(string oldPath, string newPath)
    signal seekRequested(int targetMs)

    function applyCommand(pathRef: string): string {
        const mode = GlobalConfig.services.modeOverride;
        if (!mode)
            return `caelestia wallpaper -f ${pathRef}${GlobalConfig.services.smartScheme ? "" : " --no-smart"}`;
        if (GlobalConfig.services.smartScheme && Colours.scheme === "dynamic")
            return `caelestia wallpaper -f ${pathRef} --no-smart && v=$(caelestia wallpaper -p ${pathRef} | python3 -c 'import json,sys;print(json.load(sys.stdin)["variant"])' || true) && caelestia scheme set -m "${mode}" $` + `{v:+-v "$v"}`;
        return `caelestia wallpaper -f ${pathRef} --no-smart && caelestia scheme set -m "${mode}"`;
    }

    // Buckets every wallpaper by the directory it sits in, relative to the wallpaper dir that
    // owns it. Files directly in a wallpaper dir land in `roots`; everything else becomes one
    // folder keyed by the full relative path, so `imgs/Wallpapers` stays distinct from
    // `imgs/Videos` and directories holding no wallpapers never appear at all.
    // Only the Nexus picker reads this, so keep it lazy: building it eagerly made the
    // singleton pay the cost on every entries change even while the page was closed.
    property bool groupsNeeded: false
    readonly property var groups: {
        if (!groupsNeeded)
            return {
                roots: [],
                folders: []
            };
        return Selection.buildGroups(allEntries, effectiveAbsDirs);
    }

    // FileSystemModel follows symlinks but reports the link path, while the wallpaper state
    // file records the canonical one, so a wallpaper reached through a symlinked directory
    // never compares equal by string. Canonicalising the handful of distinct parent dirs is
    // enough to bridge the two namespaces.
    readonly property list<string> entryDirs: Selection.parentDirs(allEntries)
    property var canonicalDirs: ({})
    // The entryDirs snapshot the in-flight realpath run was started for, so its output lines
    // pair with the right directories even if entryDirs changes again mid-run.
    property var realpathDirs: []

    // True when `entry` is the wallpaper currently applied, comparing through the canonical
    // path when the entry was reached via a symlink.
    function isCurrent(entry: FileSystemEntry): bool {
        if (!entry || !actualCurrent)
            return false;
        if (entry.path === actualCurrent)
            return true;
        const real = canonicalDirs[entry.parentDir];
        return !!real && `${real}/${entry.name}` === actualCurrent;
    }

    function _selection(): var {
        if (_selectionCache === null)
            _selectionCache = {
                pools: Object.create(null),
                nextOrders: Object.create(null)
            };
        return _selectionCache;
    }

    // Pools and next orders are rebuilt only when allEntries changes, not on every
    // rotation. The index maps make both selection paths O(1) after the first use.
    function _poolEntries(pool: string): var {
        const cache = _selection();
        let cached = cache.pools[pool];
        if (!cached) {
            const entries = Selection.filterPool(allEntries, pool, path => Images.isValidVideoByName(path));
            cached = {
                entries,
                indexByPath: Selection.indexByPath(entries)
            };
            cache.pools[pool] = cached;
        }
        return cached;
    }

    function _nextOrder(pool: string): var {
        const cache = _selection();
        let cached = cache.nextOrders[pool];
        if (!cached) {
            const entries = Selection.buildNextOrder(_poolEntries(pool).entries);
            cached = {
                entries,
                indexByPath: Selection.indexByPath(entries)
            };
            cache.nextOrders[pool] = cached;
        }
        return cached;
    }

    function setRandom(): void {
        const entries = allEntries;
        if (entries.length === 0)
            return;
        const pick = entries[Math.floor(Math.random() * entries.length)];
        setWallpaper(pick.path);
    }

    function advance(filterOverride = -1): bool {
        const pool = filterOverride === 0 ? "all" : filterOverride === 1 ? "images" : filterOverride === 2 ? "videos" : Config.background.advancePool;
        let pick;
        if (Config.background.advanceOrder === "next") {
            const order = _nextOrder(pool);
            pick = Selection.pickNext(order.entries, order.indexByPath, actualCurrent);
        } else {
            const candidates = _poolEntries(pool);
            pick = Selection.pickRandom(candidates.entries, candidates.indexByPath, actualCurrent);
        }
        if (!pick || pick.path === actualCurrent)
            return false;
        setWallpaper(pick.path);
        return true;
    }

    // Seeks the currently focused monitor's video wallpaper (and the shared audio
    // track) by `seconds`. No-op unless the current wallpaper is a video.
    function seekVideo(seconds: int): void {
        if (!Images.isValidVideoByName(actualCurrent))
            return;
        const dur = audioPlayer.duration;
        let target = audioPlayer.position + seconds * 1000;
        target = target < 0 ? 0 : (dur > 0 && target > dur ? dur : target);
        audioPlayer.position = target;
        seekRequested(target);
    }

    // Flips the same persisted setting as the Nexus toggle, so the keybind, the
    // settings page and `shell.json` never disagree about whether audio is on.
    function toggleAudio(): void {
        GlobalConfig.background.videoAudio = !GlobalConfig.background.videoAudio;
    }

    function _findArgs(dir: string, filter: int): list<string> {
        const exts = filter === 2 ? Images.validVideoExtensions : filter === 1 ? Images.validImageExtensions : Images.validImageExtensions.concat(Images.validVideoExtensions);
        const nameArgs = [];
        for (let i = 0; i < exts.length; i++) {
            if (i > 0)
                nameArgs.push("-o");
            nameArgs.push("-name", `*.${exts[i]}`);
        }
        return ["find", "-L", dir, "-type", "f", "("].concat(nameArgs).concat([")"]);
    }

    // `find` writes nothing to stdout whether the directory is empty, missing, or unreadable,
    // so empty output on its own cannot mean "no wallpapers here" -- reporting it that way told
    // the user their folder was empty when the real cause was a bad path or a permission error.
    // The exit code is what separates the two.
    function setRandomFrom(dir: string, filter): void {
        Cmd.run(root._findArgs(dir, filter), {
            title: qsTr("Couldn't search for wallpapers"),
            detail: qsTr("Could not read %1").arg(dir),
            icon: "folder_off",
            onExit: (exitCode, out) => {
                if (exitCode !== 0)
                    return;

                const files = out.split("\n").filter(f => f.length > 0);
                if (files.length === 0)
                    Toaster.toast(qsTr("No wallpapers found"), qsTr("Nothing matching in %1").arg(dir), "wallpaper");
                else
                    root.setWallpaper(files[Math.floor(Math.random() * files.length)]);
            }
        });
    }

    function setWallpaperDirs(dirs): void {
        const entries = dirs.map(d => typeof d === "string" ? { path: d, enabled: true } : d);
        wallpaperDirEntries = entries;
        wallpaperDirs = entries.map(e => e.path);
        const data = JSON.stringify({ dirs: entries }, null, 2);
        dirsConfigFile.setText(data);
    }

    function toggleDir(index: int): void {
        const entries = [...wallpaperDirEntries];
        entries[index] = { path: entries[index].path, enabled: !entries[index].enabled };
        setWallpaperDirs(entries);
    }

    // Commits the new wallpaper to shell state and asks the backend to apply it. The state
    // change leads deliberately -- the UI should react to the click, not to the round trip --
    // but the apply is checked, so a missing CLI or unreadable file now says so instead of
    // leaving the shell reporting a wallpaper the desktop never took.
    function _applyWallpaper(oldPath: string, path: string): void {
        actualCurrent = path;
        wallpaperApplied(oldPath, path);

        // Videos need a still extracted first, and the extract/apply/record chain has to stay
        // one script so a failure anywhere in it aborts the rest.
        const argv = Images.isValidVideoByName(path) ? ["sh", "-c", `${extractFrameScript}
${applyCommand('"$2"')} && printf %s "$1" > "$3"`, "sh", path, videoFramePath(path), currentNamePath] : ["sh", "-c", applyCommand(`"${path}"`)];

        Cmd.run(argv, {
            title: qsTr("Couldn't set wallpaper"),
            icon: "wallpaper_slideshow"
        });
    }

    function setWallpaper(path: string): void {
        const oldPath = actualCurrent;
        audioPlayer.stop();
        _programmaticPending = true;
        programmaticClearTimer.restart();

        // Leaving preview mode has to settle before the apply, or the preview teardown races
        // the new wallpaper landing.
        if (showPreview) {
            showPreview = false;
            Qt.callLater(() => root._applyWallpaper(oldPath, path));
        } else {
            root._applyWallpaper(oldPath, path);
        }
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (!previewColourLock)
            Colours.showPreview = false;
    }

    function videoFramePath(path: string): string {
        return `${videoFramesPath}/${Qt.md5(path)}.jpg`;
    }

    function ensureVideoFrame(path: string, priority = false): void {
        if (!Images.isValidVideoByName(path) || videoFrames[path] !== undefined || frameProc.activePath === path)
            return;

        const queuedIndex = frameQueue.indexOf(path);
        if (queuedIndex >= 0) {
            if (priority && queuedIndex > 0) {
                frameQueue.splice(queuedIndex, 1);
                frameQueue.unshift(path);
            }
            return;
        }

        if (priority)
            frameQueue.unshift(path);
        else
            frameQueue.push(path);
        processFrameQueue();
    }

    function processFrameQueue(): void {
        if (frameProc.running || frameQueue.length === 0)
            return;
        frameProc.activePath = frameQueue.shift();
        frameProc.running = true;
    }

    function thumbnailFor(path: string): string {
        if (!Images.isValidVideoByName(path))
            return path;
        return videoFrames[path] ?? "";
    }

    function animationsActiveOnMonitor(monitor): bool {
        if (GameMode.enabled || Visibilities.sessionLocked)
            return false;

        if (!monitor)
            return true;
        if (monitor.lastIpcObject.dpmsStatus === false)
            return false;

        // Mirrors the fullscreen detection in modules/drawers/ContentWindow.qml
        const specialName = monitor.lastIpcObject.specialWorkspace?.name;
        if (specialName) {
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return !(specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false);
        }
        return !(monitor.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false);
    }

    function animationsActiveOn(screen: ShellScreen): bool {
        return animationsActiveOnMonitor(Hypr.monitorFor(screen));
    }

    // 3a: audio follows the focused monitor's animation gate (fullscreen, game mode, lock, DPMS-off)
    readonly property bool wallpaperAudioActive: animationsActiveOnMonitor(Hypr.focusedMonitor)
    // 3b: another app producing output audio (own "quickshell" streams excluded to avoid a self-feedback loop)
    readonly property bool otherAudioPlaying: Audio.streams.some(s => s.isSink && s.ready && !s.audio.muted && s.audio.volume > 0 && s.name !== "quickshell")
    // Combined decision: should the wallpaper audio track be playing right now?
    readonly property bool audioShouldPlay: Images.isValidVideoByName(actualCurrent) && wallpaperAudioActive && !(Config.background.pauseAudioWhenOtherPlaying && otherAudioPlaying)

    function syncAudioPlayback(): void {
        if (!Images.isValidVideoByName(actualCurrent))
            return;
        if (audioShouldPlay)
            audioPlayer.play();
        else
            audioPlayer.pause();
    }

    onAudioShouldPlayChanged: syncAudioPlayback()

    Timer {
        id: programmaticClearTimer

        interval: 5000
        onTriggered: root._programmaticPending = false
    }

    list: allEntries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    onCurrentChanged: ensureVideoFrame(current, true)

    onActualCurrentChanged: {
        pendingVideoAdvance = false;
        if (Images.isValidVideoByName(actualCurrent)) {
            audioPlayer.source = actualCurrent;
            syncAudioPlayback();
        } else {
            audioPlayer.stop();
            audioPlayer.source = "";
        }
        if (Config.background.rotationEnabled)
            rotationTimer.restart();
    }

    onEntryDirsChanged: realpathDebounce.restart()

    onAllEntriesChanged: _selectionCache = null

    MediaDevices {
        id: mediaDevices
    }

    MediaPlayer {
        id: audioPlayer

        loops: MediaPlayer.Infinite

        audioOutput: AudioOutput {
            muted: !Config.background.videoAudio
            device: mediaDevices.defaultAudioOutput
        }
    }

    Timer {
        id: rotationTimer

        interval: Config.background.rotationIntervalMinutes * 60000
        repeat: true
        running: Config.background.rotationEnabled
        onTriggered: {
            if (Config.background.videoPlayToEnd && Images.isValidVideoByName(root.actualCurrent))
                root.pendingVideoAdvance = true;
            else
                root.advance();
        }
    }

    Timer {
        id: realpathDebounce

        interval: 250
        onTriggered: {
            realpathProc.running = false;
            root.realpathDirs = root.entryDirs.slice();
            if (root.realpathDirs.length > 0)
                realpathProc.running = true;
        }
    }

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function random(): void {
            root.advance();
        }

        function randomFilter(filter: int): void {
            root.advance(filter);
        }

        function randomFrom(dir: string, filter: int): void {
            root.setRandomFrom(dir, filter);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        function dirs(): string {
            return root.wallpaperDirs.join("\n");
        }

        function addDir(dir: string): void {
            const entries = [...root.wallpaperDirEntries];
            if (!entries.find(e => e.path === dir))
                entries.push({ path: dir, enabled: true });
            root.setWallpaperDirs(entries);
        }

        function removeDir(dir: string): void {
            root.setWallpaperDirs(root.wallpaperDirEntries.filter(e => e.path !== dir));
        }

        function seek(seconds: int): void {
            root.seekVideo(seconds);
        }

        function seekForward(): void {
            root.seekVideo(Config.background.videoSeekStepSeconds);
        }

        function seekBackward(): void {
            root.seekVideo(-Config.background.videoSeekStepSeconds);
        }

        function toggleAudio(): void {
            root.toggleAudio();
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const path = text().trim();

            if (root._programmaticPending) {
                if (path === root.actualCurrent) {
                    root._programmaticPending = false;
                    programmaticClearTimer.stop();
                }
                return;
            }

            if (path === root.actualCurrent)
                return;

            if (Images.isValidVideoByName(root.actualCurrent) && path === root.videoFramePath(root.actualCurrent))
                return;

            root.actualCurrent = path;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["sh", "-c", root.applyCommand(`"${root.fallback}"`)]);
        }
    }

    FileView {
        id: dirsConfigFile

        path: root.dirsConfigPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                const raw = data.dirs || ["~/Pictures/Wallpapers"];
                const entries = raw.map(d => typeof d === "string" ? { path: d, enabled: true } : d);
                root.wallpaperDirEntries = entries;
                root.wallpaperDirs = entries.map(e => e.path);
            } catch (e) {
                const entries = [{ path: "~/Pictures/Wallpapers", enabled: true }];
                root.wallpaperDirEntries = entries;
                root.wallpaperDirs = entries.map(e => e.path);
            }
        }
        onLoadFailed: {
            const entries = [{ path: "~/Pictures/Wallpapers", enabled: true }];
            root.wallpaperDirEntries = entries;
            root.wallpaperDirs = entries.map(e => e.path);
        }
    }

    Instantiator {
        id: modelRepeater

        model: effectiveDirs

        FileSystemModel {
            id: fileModel

            recursive: true
            path: Paths.absolutePath(modelData)
            nameFilters: Images.validWallpaperExtensions.map(e => `*.${e}`)
        }
    }

    property list<var> allEntries: {
        const entries = [];
        for (let i = 0; i < modelRepeater.count; i++) {
            const model = modelRepeater.objectAt(i);
            if (model)
                entries.push(...model.entries);
        }
        return entries;
    }

    Process {
        id: getPreviewColoursProc

        command: {
            if (Images.isValidVideoByName(root.previewPath))
                return ["sh", "-c", `${root.extractFrameScript}
exec caelestia wallpaper -p "$2"${root.previewSmartArg}`, "sh", root.previewPath, root.videoFramePath(root.previewPath)];
            return ["sh", "-c", `caelestia wallpaper -p "${root.previewPath}"${root.previewSmartArg}`];
        }
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    Process {
        id: frameProc

        property string activePath

        command: ["sh", "-c", root.extractFrameScript, "sh", activePath, root.videoFramePath(activePath)]
        onExited: code => {
            const updated = Object.assign({}, root.videoFrames);
            updated[activePath] = code === 0 ? root.videoFramePath(activePath) : "";
            root.videoFrames = updated;
            activePath = "";
            root.processFrameQueue();
        }
    }

    Process {
        id: realpathProc

        command: ["realpath", "--"].concat(root.realpathDirs)
        stdout: StdioCollector {
            onStreamFinished: {
                const dirs = root.realpathDirs;
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                // A short read means the run was cut off by a restart -- keep the old map
                if (lines.length !== dirs.length)
                    return;
                const map = {};
                for (let i = 0; i < dirs.length; i++)
                    map[dirs[i]] = lines[i];
                root.canonicalDirs = map;
            }
        }
    }

}
