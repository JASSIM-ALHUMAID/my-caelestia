.pragma library

const MODIFIERS = {
    "SUPER": "SUPER",
    "SHIFT": "SHIFT",
    "CTRL": "CTRL",
    "ALT": "ALT"
};

const MODIFIER_KEYS = ["SUPER", "SHIFT", "CTRL", "ALT"];

const ACTIONS = [
    // Apps
    { id: "exec", category: "exec", label: "Run command", hasArg: true, argLabel: "Command", dispatcher: "exec" },
    { id: "global", category: "global", label: "Global shortcut", hasArg: true, argLabel: "Global name", dispatcher: "global" },

    // Window
    { id: "window.close", category: "window", label: "Close window", dispatcher: "killactive" },
    { id: "window.float", category: "window", label: "Toggle floating", dispatcher: "togglefloating" },
    { id: "window.fullscreen", category: "window", label: "Toggle fullscreen", dispatcher: "fullscreen" },
    { id: "window.pseudo", category: "window", label: "Toggle pseudo", dispatcher: "pseudo" },

    // Focus
    { id: "focus.left", category: "focus", label: "Focus left", dispatcher: "movefocus", arg: "l" },
    { id: "focus.right", category: "focus", label: "Focus right", dispatcher: "movefocus", arg: "r" },
    { id: "focus.up", category: "focus", label: "Focus up", dispatcher: "movefocus", arg: "u" },
    { id: "focus.down", category: "focus", label: "Focus down", dispatcher: "movefocus", arg: "d" },

    // Workspace
    { id: "workspace.next", category: "workspace", label: "Next workspace", dispatcher: "workspace", arg: "e+1" },
    { id: "workspace.prev", category: "workspace", label: "Previous workspace", dispatcher: "workspace", arg: "e-1" },
    { id: "workspace.1", category: "workspace", label: "Workspace 1", dispatcher: "workspace", arg: "1" },
    { id: "workspace.2", category: "workspace", label: "Workspace 2", dispatcher: "workspace", arg: "2" },
    { id: "workspace.3", category: "workspace", label: "Workspace 3", dispatcher: "workspace", arg: "3" },
    { id: "workspace.4", category: "workspace", label: "Workspace 4", dispatcher: "workspace", arg: "4" },
    { id: "workspace.5", category: "workspace", label: "Workspace 5", dispatcher: "workspace", arg: "5" },

    // Layout
    { id: "layout.toggle orientation", category: "layout", label: "Toggle orientation", dispatcher: "orientation" },
    { id: "layout.orientation.right", category: "layout", label: "Orientation right", dispatcher: "orientation", arg: "right" },
    { id: "layout.orientation.left", category: "layout", label: "Orientation left", dispatcher: "orientation", arg: "left" },
    { id: "layout.orientation.top", category: "layout", label: "Orientation top", dispatcher: "orientation", arg: "top" },
    { id: "layout.orientation.bottom", category: "layout", label: "Orientation bottom", dispatcher: "orientation", arg: "bottom" },
    { id: "layout.reverse", category: "layout", label: "Reverse master", dispatcher: "swapwithmaster", arg: "master" },

    // Scrolling
    { id: "scrolling.moveColRight", category: "scrolling", label: "Move column right", dispatcher: "layoutmsg", arg: "move +col" },
    { id: "scrolling.moveColLeft", category: "scrolling", label: "Move column left", dispatcher: "layoutmsg", arg: "move -col" },
    { id: "scrolling.colResizeIn", category: "scrolling", label: "Increase column width", dispatcher: "layoutmsg", arg: "colresize +conf" },
    { id: "scrolling.colResizeOut", category: "scrolling", label: "Decrease column width", dispatcher: "layoutmsg", arg: "colresize -conf" },

    // System
    { id: "system.lock", category: "system", label: "Lock screen", dispatcher: "exec", arg: "loginctl lock-session" },
    { id: "system.screenshot", category: "system", label: "Screenshot", dispatcher: "exec", arg: "grimblast copy area" },
];

function getActionById(id) {
    return ACTIONS.find(a => a.id === id) || null;
}

// Display order for the action picker's group headers. An action whose category isn't listed
// sorts to the end rather than disappearing, so adding one to ACTIONS can't silently hide it.
const CATEGORY_ORDER = ["exec", "global", "window", "focus", "workspace", "layout", "scrolling", "system"];

const CATEGORY_LABELS = {
    "exec": "Apps & commands",
    "global": "Apps & commands",
    "window": "Window",
    "focus": "Focus",
    "workspace": "Workspace",
    "layout": "Layout",
    "scrolling": "Scrolling layout",
    "system": "System"
};

function categoryLabel(category) {
    return CATEGORY_LABELS[category] || category || "";
}

// ACTIONS sorted so each category forms one contiguous run, which is what Menu's group headers
// assume. Stable within a category: entries keep their declaration order.
function actionsByCategory() {
    const rank = c => {
        const i = CATEGORY_ORDER.indexOf(c);
        return i < 0 ? CATEGORY_ORDER.length : i;
    };
    return ACTIONS.map((a, i) => ({ a, i })).sort((x, y) => rank(x.a.category) - rank(y.a.category) || x.i - y.i).map(e => e.a);
}

function formatModifiers(mods) {
    if (!mods || mods.length === 0) return "";
    const order = ["SUPER", "CTRL", "ALT", "SHIFT"];
    return order.filter(m => mods.includes(m)).join(" + ");
}

// A combo with no key is legal for the Hyprland `kb*` prefix variables (see parseKeyCombo), so
// an empty key renders as the bare modifier list rather than leaving a trailing " + ".
function formatKeyCombo(mods, key) {
    const modStr = formatModifiers(mods);
    if (!modStr) return key;
    return key ? `${modStr} + ${key}` : modStr;
}

// Inverse of formatKeyCombo, for values that arrive as a single string (the Hyprland `kb*`
// variables). A combo made only of modifiers is a valid value in its own right -- the four
// kbGoToWs/kbMoveWinToWs keys are a prefix that keybinds.lua completes with a digit -- so a
// mods-only input yields an empty key rather than treating the last modifier as the key.
function parseKeyCombo(combo) {
    const parts = String(combo || "").split("+").map(p => p.trim()).filter(p => p.length > 0);
    if (parts.length === 0) return { mods: [], key: "" };

    const isMod = p => MODIFIER_KEYS.includes(p.toUpperCase());
    if (parts.every(isMod)) return { mods: parts.map(p => p.toUpperCase()), key: "" };

    const key = parts[parts.length - 1];
    const mods = parts.slice(0, -1).map(p => isMod(p) ? p.toUpperCase() : p);
    return { mods, key };
}

// Canonical form for comparing two binds, whichever system they came from. Keysym casing is
// inconsistent across sources -- variables.lua spells them `Comma`, `TAB`, `space`, `backslash`
// while qtEventToBinding emits `comma`, `Tab` -- so the same bind would otherwise read as two
// different ones, and the two keybind systems could never see each other's conflicts.
function normalizeCombo(mods, key) {
    const modStr = formatModifiers(mods);
    const k = String(key || "").toLowerCase();
    return `${modStr},${k}`;
}

// Same, for binds that arrive as one string (the Hyprland `kb*` variables).
function normalizeHyprCombo(combo) {
    const { mods, key } = parseKeyCombo(combo);
    return normalizeCombo(mods, key);
}

function resolveToHyprland(action) {
    const act = getActionById(action.id);
    if (!act) return null;
    const arg = act.hasArg ? (action.argument || "") : (act.arg || "");
    return { dispatcher: act.dispatcher, argument: arg };
}

function luaString(s) {
    return `"${String(s).replace(/\\/g, "\\\\").replace(/"/g, "\\\"")}"`;
}

// Hyprland rejects `keyword bind` when the config is lua ("keyword can't work
// with non-legacy parsers"), so dynamic binds are applied as `eval hl.bind(...)`
// instead. Translate a legacy dispatcher + arg into the lua dispatcher call.
// Returns null for dispatchers with no lua equivalent, which are then skipped.
function luaDispatcher(dispatcher, arg) {
    const a = arg || "";
    switch (dispatcher) {
    case "exec":
        return `hl.dsp.exec_cmd(${luaString(a)})`;
    case "global":
        return `hl.dsp.global(${luaString(a)})`;
    case "killactive":
        return "hl.dsp.window.close()";
    case "togglefloating":
        return "hl.dsp.window.float()";
    case "fullscreen":
        return `hl.dsp.window.fullscreen({ mode = ${luaString(a === "1" ? "maximized" : "fullscreen")} })`;
    case "pseudo":
        return "hl.dsp.window.pseudo()";
    case "movefocus":
        return `hl.dsp.focus({ direction = ${luaString(a)} })`;
    case "workspace":
        return `hl.dsp.focus({ workspace = ${luaString(a)} })`;
    case "movetoworkspace":
        return `hl.dsp.window.move({ workspace = ${luaString(a)} })`;
    case "movetoworkspacesilent":
        return `hl.dsp.window.move({ workspace = ${luaString(a)}, follow = false })`;
    case "layoutmsg":
        return `hl.dsp.layout(${luaString(a)})`;
    // These are layout messages the legacy table spelled as dispatchers.
    case "orientation":
        return `hl.dsp.layout(${luaString(`orientation ${a}`.trim())})`;
    case "swapwithmaster":
        return `hl.dsp.layout(${luaString(`swapwithmaster ${a}`.trim())})`;
    default:
        return null;
    }
}

const MODIFIER_QT_KEYS = [
    Qt.Key_Shift, Qt.Key_Control, Qt.Key_Meta, Qt.Key_Alt, Qt.Key_AltGr,
    Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Hyper_L, Qt.Key_Hyper_R,
    Qt.Key_CapsLock, Qt.Key_NumLock
];

function isModifierKey(qtKey) {
    return MODIFIER_QT_KEYS.includes(qtKey);
}

// The modifier a key press *is*, as opposed to the modifiers it was held with. Qt reports
// `event.modifiers` as the state before the press, so a capture that wants the key just pressed
// to count has to add it back. Returns null for modifiers Hyprland's lua parser has no name for.
function modifierNameForKey(qtKey) {
    switch (qtKey) {
    case Qt.Key_Meta:
    case Qt.Key_Super_L:
    case Qt.Key_Super_R:
        return "SUPER";
    case Qt.Key_Control:
        return "CTRL";
    case Qt.Key_Alt:
        return "ALT";
    case Qt.Key_Shift:
        return "SHIFT";
    default:
        return null;
    }
}

const QT_TO_KEYSYM = {
    [Qt.Key_Return]: "Return",
    [Qt.Key_Enter]: "KP_Enter",
    [Qt.Key_Tab]: "Tab",
    [Qt.Key_Backtab]: "Tab",
    [Qt.Key_Space]: "space",
    [Qt.Key_Backspace]: "BackSpace",
    [Qt.Key_Delete]: "Delete",
    [Qt.Key_Insert]: "Insert",
    [Qt.Key_Home]: "Home",
    [Qt.Key_End]: "End",
    [Qt.Key_PageUp]: "Prior",
    [Qt.Key_PageDown]: "Next",
    [Qt.Key_Left]: "Left",
    [Qt.Key_Right]: "Right",
    [Qt.Key_Up]: "Up",
    [Qt.Key_Down]: "Down",
    [Qt.Key_Print]: "Print",
    [Qt.Key_Menu]: "Menu",
    [Qt.Key_Pause]: "Pause",
    [Qt.Key_Period]: "period",
    [Qt.Key_Greater]: "period",
    [Qt.Key_Comma]: "comma",
    [Qt.Key_Less]: "comma",
    [Qt.Key_Slash]: "slash",
    [Qt.Key_Question]: "slash",
    [Qt.Key_Backslash]: "backslash",
    [Qt.Key_Bar]: "backslash",
    [Qt.Key_Semicolon]: "semicolon",
    [Qt.Key_Colon]: "semicolon",
    [Qt.Key_Apostrophe]: "apostrophe",
    [Qt.Key_QuoteDbl]: "apostrophe",
    [Qt.Key_BracketLeft]: "bracketleft",
    [Qt.Key_BraceLeft]: "bracketleft",
    [Qt.Key_BracketRight]: "bracketright",
    [Qt.Key_BraceRight]: "bracketright",
    [Qt.Key_QuoteLeft]: "grave",
    [Qt.Key_AsciiTilde]: "grave",
    [Qt.Key_Minus]: "minus",
    [Qt.Key_Underscore]: "minus",
    [Qt.Key_Equal]: "equal",
    [Qt.Key_Plus]: "equal",
    [Qt.Key_Exclam]: "1",
    [Qt.Key_At]: "2",
    [Qt.Key_NumberSign]: "3",
    [Qt.Key_Dollar]: "4",
    [Qt.Key_Percent]: "5",
    [Qt.Key_AsciiCircum]: "6",
    [Qt.Key_Ampersand]: "7",
    [Qt.Key_Asterisk]: "8",
    [Qt.Key_ParenLeft]: "9",
    [Qt.Key_ParenRight]: "0",
    [Qt.Key_VolumeUp]: "XF86AudioRaiseVolume",
    [Qt.Key_VolumeDown]: "XF86AudioLowerVolume",
    [Qt.Key_VolumeMute]: "XF86AudioMute",
    [Qt.Key_MediaTogglePlayPause]: "XF86AudioPlay",
    [Qt.Key_MediaPlay]: "XF86AudioPlay",
    [Qt.Key_MediaNext]: "XF86AudioNext",
    [Qt.Key_MediaPrevious]: "XF86AudioPrev",
    [Qt.Key_MediaStop]: "XF86AudioStop",
    [Qt.Key_MonBrightnessUp]: "XF86MonBrightnessUp",
    [Qt.Key_MonBrightnessDown]: "XF86MonBrightnessDown"
};

function qtEventToBinding(key, modifiers, text) {
    const mods = [];
    if (modifiers & Qt.MetaModifier) mods.push("SUPER");
    if (modifiers & Qt.ControlModifier) mods.push("CTRL");
    if (modifiers & Qt.AltModifier) mods.push("ALT");
    if (modifiers & Qt.ShiftModifier) mods.push("SHIFT");

    let keysym = null;
    if (key >= Qt.Key_A && key <= Qt.Key_Z) {
        keysym = String.fromCharCode("A".charCodeAt(0) + (key - Qt.Key_A));
    } else if (key >= Qt.Key_0 && key <= Qt.Key_9) {
        keysym = String.fromCharCode("0".charCodeAt(0) + (key - Qt.Key_0));
    } else if (key >= Qt.Key_F1 && key <= Qt.Key_F35) {
        keysym = "F" + (key - Qt.Key_F1 + 1);
    } else if (QT_TO_KEYSYM.hasOwnProperty(key)) {
        keysym = QT_TO_KEYSYM[key];
    } else if (text && text.length === 1 && text.trim().length === 1) {
        keysym = text.toLowerCase();
    }

    if (!keysym) return null;
    return { mods, key: keysym };
}
