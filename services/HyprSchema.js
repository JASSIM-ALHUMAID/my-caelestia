.pragma library

// Declarative description of every Hyprland setting Nexus exposes. Both Hyprland sub-pages
// render themselves from these tables rather than hand-writing a row per setting.
//
// Each entry is:
//   key      GlobalConfig.services property name (also the hypr-vars.lua key)
//   type     "int" | "real" | "bool" | "string" | "enum" | "keybind"
//   def      the upstream default, mirrored from ~/.local/share/caelestia/hypr for reference.
//            The authoritative default lives in C++ (ConfigObject::captureDefaults) -- that's
//            what isModified/resetOption read -- so this field is documentation, not behaviour.
//   min/max/step   numeric rows only
//   options  enum rows only, as [{ value, label, icon }]
//   label/subtext  UI strings. Not qsTr()'d here (a .pragma library has no qsTr); the renderer
//            passes them through qsTr at binding time.

// ---------------------------------------------------------------- Variables (variables.lua)

var VAR_SECTIONS = [
    {
        id: "volume",
        title: "Volume",
        vars: [
            { key: "audioIncrement", type: "real", def: 0.1, min: 0.01, max: 0.5, step: 0.01, scale: 100,
              label: "Volume step", subtext: "Amount the volume changes per scroll (%)" },
            { key: "maxVolume", type: "real", def: 1.0, min: 0.5, max: 2.0, step: 0.05, scale: 100,
              label: "Max volume", subtext: "Upper limit for output volume (%)" }
        ]
    },
    {
        id: "gaps",
        title: "Gaps",
        vars: [
            { key: "workspaceGaps", type: "int", def: 20, min: 0, max: 100, step: 1,
              label: "Workspace gaps", subtext: "Gap between workspaces" },
            { key: "windowGapsIn", type: "int", def: 5, min: 0, max: 50, step: 1,
              label: "Window gaps (in)", subtext: "Inner gap between windows in a column" },
            { key: "windowGapsOut", type: "int", def: 10, min: 0, max: 50, step: 1,
              label: "Window gaps (out)", subtext: "Outer gap around windows" },
            { key: "singleWindowGapsOut", type: "int", def: 20, min: 0, max: 100, step: 1,
              label: "Single window gaps", subtext: "Outer gap for single-window columns" }
        ]
    },
    {
        id: "blur",
        title: "Blur",
        vars: [
            { key: "blurEnabled", type: "bool", def: true,
              label: "Blur enabled", subtext: "Enable background blur behind windows" },
            { key: "blurSize", type: "int", def: 8, min: 0, max: 50, step: 1,
              label: "Blur size", subtext: "Blur radius in pixels" },
            { key: "blurPasses", type: "int", def: 2, min: 0, max: 10, step: 1,
              label: "Blur passes", subtext: "Number of blur iterations" },
            { key: "blurXray", type: "bool", def: false,
              label: "X-ray", subtext: "Blur the wallpaper rather than the windows behind" },
            { key: "blurSpecialWs", type: "bool", def: false,
              label: "Blur special workspaces", subtext: "Apply blur on special workspaces too" },
            { key: "blurPopups", type: "bool", def: true,
              label: "Blur popups", subtext: "Blur behind menus and popup surfaces" },
            { key: "blurInputMethods", type: "bool", def: true,
              label: "Blur input methods", subtext: "Blur behind IME candidate windows" }
        ]
    },
    {
        id: "shadow",
        title: "Shadow",
        vars: [
            { key: "shadowEnabled", type: "bool", def: true,
              label: "Shadow enabled", subtext: "Show window shadows" },
            { key: "shadowRange", type: "int", def: 15, min: 0, max: 100, step: 1,
              label: "Shadow range", subtext: "Shadow blur radius" },
            { key: "shadowRenderPower", type: "int", def: 4, min: 0, max: 10, step: 1,
              label: "Shadow power", subtext: "Shadow falloff exponent" }
        ]
    },
    {
        id: "window",
        title: "Window",
        vars: [
            { key: "windowOpacity", type: "real", def: 0.95, min: 0.0, max: 1.0, step: 0.01,
              label: "Window opacity", subtext: "Window background opacity" },
            { key: "windowRounding", type: "int", def: 15, min: 0, max: 50, step: 1,
              label: "Window rounding", subtext: "Corner radius in pixels" },
            { key: "windowBorderSize", type: "int", def: 1, min: 0, max: 10, step: 1,
              label: "Window border size", subtext: "Border width in pixels" }
        ]
    },
    {
        id: "touchpad",
        title: "Touchpad",
        vars: [
            { key: "touchpadDisableTyping", type: "bool", def: true,
              label: "Disable while typing", subtext: "Disable touchpad while typing on keyboard" },
            { key: "touchpadScrollFactor", type: "real", def: 0.3, min: 0.1, max: 2.0, step: 0.1,
              label: "Scroll factor", subtext: "Touchpad scroll speed multiplier" },
            { key: "gestureFingers", type: "int", def: 3, min: 2, max: 5, step: 1,
              label: "Gesture fingers", subtext: "Number of fingers for gestures" },
            { key: "workspaceSwipeFingers", type: "int", def: 4, min: 2, max: 5, step: 1,
              label: "Workspace swipe fingers", subtext: "Fingers to swipe between workspaces" },
            { key: "gestureFingersMore", type: "int", def: 4, min: 2, max: 5, step: 1,
              label: "Gesture fingers (more)", subtext: "Additional gesture finger count" }
        ]
    },
    {
        id: "misc",
        title: "Misc",
        vars: [
            { key: "sleepGestureCmd", type: "string", def: "systemctl suspend-then-hibernate",
              label: "Sleep gesture command", subtext: "Run by the four-finger down gesture" }
        ]
    }
];

// ----------------------------------------------------------------- Config (hypr-user.lua)

var CFG_SECTIONS = [
    {
        id: "layout",
        title: "Layout",
        vars: [
            { key: "cfgLayout", type: "enum", def: "scrolling",
              options: [
                  { value: "dwindle", label: "Dwindle", icon: "grid_view" },
                  { value: "master", label: "Master", icon: "view_sidebar" },
                  { value: "scrolling", label: "Scrolling", icon: "view_column" }
              ],
              label: "Tiling layout", subtext: "How new windows are placed" },
            { key: "cfgColumnWidth", type: "real", def: 0.5, min: 0.1, max: 1.0, step: 0.05,
              label: "Column width", subtext: "Scrolling layout: default column width" },
            { key: "cfgExplicitColumnWidths", type: "string", def: "0.35, 0.5, 0.65, 1.0",
              label: "Column width presets", subtext: "Scrolling layout: comma-separated widths to cycle" }
        ]
    },
    {
        id: "input",
        title: "Input",
        vars: [
            { key: "cfgKbLayout", type: "string", def: "us",
              label: "Keyboard layout", subtext: "XKB layout, comma-separated for multiple" },
            { key: "cfgKbVariant", type: "string", def: "",
              label: "Keyboard variant", subtext: "XKB variant, one per layout" },
            { key: "cfgKbOptions", type: "string", def: "",
              label: "Keyboard options", subtext: "XKB options, e.g. grp:win_space_toggle" },
            { key: "cfgSensitivity", type: "real", def: 0.0, min: -1.0, max: 1.0, step: 0.05,
              label: "Pointer sensitivity", subtext: "-1.0 slowest, 1.0 fastest" },
            { key: "cfgAccelProfile", type: "enum", def: "flat",
              options: [
                  { value: "flat", label: "Flat", icon: "trending_flat" },
                  { value: "adaptive", label: "Adaptive", icon: "trending_up" }
              ],
              label: "Acceleration profile", subtext: "Pointer acceleration curve" }
        ]
    },
    {
        id: "animations",
        title: "Animations",
        vars: [
            { key: "cfgAnimationsEnabled", type: "bool", def: true,
              label: "Animations enabled", subtext: "Master switch for compositor animations" }
        ]
    },
    {
        id: "gestures",
        title: "Workspace swipe",
        vars: [
            { key: "cfgSwipeDistance", type: "int", def: 700, min: 100, max: 2000, step: 50,
              label: "Swipe distance", subtext: "Travel needed for a full workspace switch" },
            { key: "cfgSwipeCancelRatio", type: "real", def: 0.15, min: 0.0, max: 1.0, step: 0.05,
              label: "Cancel ratio", subtext: "Fraction of the swipe that snaps back" },
            { key: "cfgSwipeMinSpeed", type: "int", def: 5, min: 0, max: 20, step: 1,
              label: "Min speed to force", subtext: "Speed that switches regardless of distance" },
            { key: "cfgSwipeDirectionLock", type: "bool", def: true,
              label: "Direction lock", subtext: "Lock the swipe to its initial axis" },
            { key: "cfgSwipeCreateNew", type: "bool", def: true,
              label: "Create new workspace", subtext: "Swiping past the last workspace creates one" }
        ]
    }
];

// ------------------------------------------------------------- Keybinds (variables.lua kb*)
//
// Every `kb*` key of variables.lua, in upstream's own order and grouping. The value is a
// Hyprland lua key combo ("SUPER + SHIFT + F"); hypr/hyprland/keybinds.lua passes it straight
// to hl.bind. Rows carrying `mode: "mods"` are a modifier *prefix* with no key -- keybinds.lua
// appends " + <digit>" for workspaces 1-10 -- so they capture modifiers only and claim ten
// combos each for conflict purposes (`expand`).

var BIND_SECTIONS = [
    {
        id: "bindWorkspaces",
        title: "Workspaces",
        vars: [
            { key: "kbGoToWs", type: "keybind", def: "SUPER", mode: "mods", expand: 10,
              label: "Go to workspace", subtext: "Modifier prefix; 1-9 and 0 are appended" },
            { key: "kbGoToWsGroup", type: "keybind", def: "CTRL + SUPER", mode: "mods", expand: 10,
              label: "Go to workspace group", subtext: "Modifier prefix; 1-9 and 0 are appended" },
            { key: "kbMoveWinToWs", type: "keybind", def: "SUPER + ALT", mode: "mods", expand: 10,
              label: "Move window to workspace", subtext: "Modifier prefix; 1-9 and 0 are appended" },
            { key: "kbMoveWinToWsGroup", type: "keybind", def: "CTRL + SUPER + ALT", mode: "mods", expand: 10,
              label: "Move window to workspace group", subtext: "Modifier prefix; 1-9 and 0 are appended" },
            { key: "kbNextWs", type: "keybind", def: "CTRL + SUPER + Right",
              label: "Next workspace", subtext: "Focus the workspace to the right" },
            { key: "kbPrevWs", type: "keybind", def: "CTRL + SUPER + Left",
              label: "Previous workspace", subtext: "Focus the workspace to the left" }
        ]
    },
    {
        id: "bindWindowGroup",
        title: "Window group",
        vars: [
            { key: "kbWindowGroupCycleNext", type: "keybind", def: "ALT + TAB",
              label: "Cycle group forward", subtext: "Next window in the group" },
            { key: "kbWindowGroupCyclePrev", type: "keybind", def: "SHIFT + ALT + TAB",
              label: "Cycle group backward", subtext: "Previous window in the group" },
            { key: "kbToggleGroup", type: "keybind", def: "SUPER + Comma",
              label: "Toggle group", subtext: "Group or ungroup the focused window" },
            { key: "kbUngroup", type: "keybind", def: "SUPER + U",
              label: "Ungroup", subtext: "Break the focused window out of its group" }
        ]
    },
    {
        id: "bindWindow",
        title: "Window",
        vars: [
            { key: "kbCloseWindow", type: "keybind", def: "SUPER + Q",
              label: "Close window", subtext: "Close the focused window" },
            { key: "kbToggleWindowFloating", type: "keybind", def: "SUPER + ALT + space",
              label: "Toggle floating", subtext: "Float or tile the focused window" },
            { key: "kbWindowFullscreen", type: "keybind", def: "SUPER + F",
              label: "Fullscreen", subtext: "Toggle fullscreen" },
            { key: "kbWindowBorderedFullscreen", type: "keybind", def: "SUPER + ALT + F",
              label: "Bordered fullscreen", subtext: "Fullscreen keeping gaps and borders" },
            { key: "kbPinWindow", type: "keybind", def: "SUPER + P",
              label: "Pin window", subtext: "Keep a floating window on every workspace" },
            { key: "kbWindowPip", type: "keybind", def: "SUPER + ALT + backslash",
              label: "Picture in picture", subtext: "Toggle PiP for the focused window" },
            { key: "kbMoveWindow", type: "keybind", def: "SUPER + Z",
              label: "Move window", subtext: "Hold to drag the window; also accepts mouse:272" },
            { key: "kbResizeWindow", type: "keybind", def: "SUPER + X",
              label: "Resize window", subtext: "Hold to resize the window; also accepts mouse:273" }
        ]
    },
    {
        id: "bindSpecialWs",
        title: "Special workspaces",
        vars: [
            { key: "kbSpecialWs", type: "keybind", def: "SUPER + S",
              label: "Scratchpad", subtext: "Toggle the special workspace" },
            { key: "kbSystemMonitorWs", type: "keybind", def: "CTRL + SHIFT + Escape",
              label: "System monitor", subtext: "Toggle the system monitor workspace" },
            { key: "kbMusicWs", type: "keybind", def: "SUPER + M",
              label: "Music", subtext: "Toggle the music workspace" },
            { key: "kbCommunicationWs", type: "keybind", def: "SUPER + D",
              label: "Communication", subtext: "Toggle the communication workspace" },
            { key: "kbTodoWs", type: "keybind", def: "SUPER + R",
              label: "Todo", subtext: "Toggle the todo workspace" }
        ]
    },
    {
        id: "bindApps",
        title: "Apps",
        vars: [
            { key: "kbTerminal", type: "keybind", def: "SUPER + T",
              label: "Terminal", subtext: "Launch the terminal set on the Variables page" },
            { key: "kbBrowser", type: "keybind", def: "SUPER + W",
              label: "Browser", subtext: "Launch the browser set on the Variables page" },
            { key: "kbEditor", type: "keybind", def: "SUPER + C",
              label: "Editor", subtext: "Launch the editor set on the Variables page" },
            { key: "kbFileExplorer", type: "keybind", def: "SUPER + E",
              label: "File explorer", subtext: "Launch the file manager set on the Variables page" }
        ]
    },
    {
        id: "bindMisc",
        title: "Misc",
        vars: [
            { key: "kbShowSidebar", type: "keybind", def: "SUPER + N",
              label: "Show sidebar", subtext: "Toggle the shell sidebar" },
            { key: "kbShowPanels", type: "keybind", def: "SUPER + K",
              label: "Show panels", subtext: "Toggle the shell panels" },
            { key: "kbClearNotifs", type: "keybind", def: "CTRL + ALT + C",
              label: "Clear notifications", subtext: "Dismiss all notifications" },
            { key: "kbSession", type: "keybind", def: "CTRL + ALT + Delete",
              label: "Session menu", subtext: "Open the logout/reboot/shutdown menu" },
            { key: "kbLock", type: "keybind", def: "SUPER + L",
              label: "Lock", subtext: "Lock the session" },
            { key: "kbRestoreLock", type: "keybind", def: "SUPER + ALT + L",
              label: "Restore lock", subtext: "Bring back a lock screen that failed to show" }
        ]
    }
];

// Every combo a bind claims. A prefix row claims one per digit, since that's what keybinds.lua
// actually registers -- kbGoToWs = "SUPER" takes SUPER+1 through SUPER+0.
function bindCombos(value, v) {
    if (!value)
        return [];
    if (!v.expand)
        return [value];

    var combos = [];
    for (var i = 1; i <= v.expand; i++)
        combos.push(value + " + " + (i % 10));
    return combos;
}

// Every key in a section list. Replaces the hand-maintained reset list the old page carried,
// which had already drifted out of sync with the rows above it.
function allKeys(sections) {
    var keys = [];
    for (var i = 0; i < sections.length; i++)
        for (var j = 0; j < sections[i].vars.length; j++)
            keys.push(sections[i].vars[j].key);
    return keys;
}
