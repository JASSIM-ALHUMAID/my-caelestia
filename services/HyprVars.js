.pragma library
.import "HyprSchema.js" as Schema

// `type` is the rendered Lua type, while `from` and `value` keep derived output names out of
// ServiceConfig. Runtime hooks live beside their persisted key so applying and saving a setting
// cannot drift into separate code paths again. String hooks use Lua config paths because the Lua
// parser rejects legacy `keyword` calls while still returning success, making failures silent.
//
// The config stores desktop entry ids while Hyprland executes these values as shell commands.
// Resolve through app2unit once the entry index exists, and preserve stale or hand-written ids
// as raw commands so older configs keep working.
function entryFor(id, applications) {
    if (!id)
        return null;
    return applications.find(a => a.id === id || a.id.endsWith(`.${id}`) || a.execString === id) ?? null;
}

function commandFor(id, applications) {
    if (!id)
        return "";
    const entry = entryFor(id, applications);
    if (!entry)
        return id;
    return `app2unit -- ${entry.id.endsWith(".desktop") ? entry.id : `${entry.id}.desktop`}`;
}

function appCommand(value, applications) {
    return applications.length > 0 ? commandFor(value, applications) : undefined;
}

function cursorCommand(theme, services) {
    if (services.cursorSize === undefined)
        return undefined;
    return ["hyprctl", "setcursor", theme, String(services.cursorSize)];
}

var gaps = [
    { key: "workspaceGaps", type: "int" },
    { key: "windowGapsIn", type: "int" },
    { key: "windowGapsOut", type: "int" },
    { key: "singleWindowGapsOut", type: "int" }
];

var blur = [
    { key: "blurEnabled", type: "bool" },
    { key: "blurSize", type: "int" },
    { key: "blurPasses", type: "int" }
];

var shadow = [
    { key: "shadowEnabled", type: "bool" },
    { key: "shadowRange", type: "int" },
    { key: "shadowRenderPower", type: "int" }
];

var window = [
    { key: "windowOpacity", type: "real" },
    { key: "windowRounding", type: "int" },
    { key: "windowBorderSize", type: "int" }
];

var touchpad = [
    { key: "touchpadDisableTyping", type: "bool" },
    { key: "touchpadScrollFactor", type: "real" },
    { key: "gestureFingers", type: "int" },
    { key: "workspaceSwipeFingers", type: "int" },
    { key: "gestureFingersMore", type: "int" }
];

var cursor = [
    { key: "cursorTheme", type: "string", runtime: cursorCommand },
    { key: "cursorSize", type: "int" }
];

var volume = [
    { key: "volumeStep", type: "int", from: "audioIncrement", value: v => Math.round(v * 100) },
    { key: "volumeMax", type: "int", from: "maxVolume", value: v => Math.round(v * 100) }
];

var apps = [
    { key: "terminal", type: "string", from: "appTerminal", value: appCommand },
    { key: "browser", type: "string", from: "appBrowser", value: appCommand },
    { key: "editor", type: "string", from: "appEditor", value: appCommand },
    { key: "fileExplorer", type: "string", from: "appFileExplorer", value: appCommand },
    { key: "audioSettings", type: "string", from: "appAudioSettings", value: appCommand }
];

var extra = [
    { key: "blurSpecialWs", type: "bool" },
    { key: "blurPopups", type: "bool" },
    { key: "blurInputMethods", type: "bool" },
    { key: "blurXray", type: "bool" },
    { key: "sleepGestureCmd", type: "string" },
    { key: "cfgLayout", type: "string", runtime: "general.layout" },
    { key: "cfgColumnWidth", type: "real" },
    { key: "cfgExplicitColumnWidths", type: "string" },
    { key: "cfgKbLayout", type: "string" },
    { key: "cfgKbVariant", type: "string" },
    { key: "cfgKbOptions", type: "string" },
    { key: "cfgSensitivity", type: "real" },
    { key: "cfgAccelProfile", type: "string" },
    { key: "cfgAnimationsEnabled", type: "bool" },
    { key: "cfgSwipeDistance", type: "int" },
    { key: "cfgSwipeCancelRatio", type: "real" },
    { key: "cfgSwipeMinSpeed", type: "int" },
    { key: "cfgSwipeDirectionLock", type: "bool" },
    { key: "cfgSwipeCreateNew", type: "bool" }
];

// The keybinds are derived from the schema rather than restated, so the Binds page and the
// values persisted to hypr-vars.lua cannot drift apart. Every `kb*` value is a combo string.
var keybinds = Schema.allKeys(Schema.BIND_SECTIONS).map(key => ({ key: key, type: "string" }));

var sections = [
    { name: "gaps", keys: gaps },
    { name: "blur", keys: blur },
    { name: "shadow", keys: shadow },
    { name: "window", keys: window },
    { name: "touchpad", keys: touchpad },
    { name: "cursor", keys: cursor },
    { name: "volume", keys: volume },
    { name: "apps", keys: apps },
    { name: "extra", keys: extra },
    { name: "keybinds", keys: keybinds }
];

var keys = sections.reduce((all, section) => all.concat(section.keys), []);
