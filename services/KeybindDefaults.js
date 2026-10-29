.pragma library

// Seed content for ~/.config/caelestia/keybinds.json, used when the file is missing, empty, or
// unparseable, and by the page's "reset all" action.
//
// This is data, not behaviour -- it lived inline in KeybindsConfig.qml, which meant one
// machine's browser, terminal and script paths were baked into a shared service. Edit this file
// to change what a fresh install starts with; the live file is user data and diverges the moment
// anything is changed in Nexus.
//
// A binding is { desc, modifiers, key, actionId, argument }:
//   modifiers  subset of SUPER / CTRL / ALT / SHIFT, canonical order applied at display time
//   key        an X keysym as Hyprland spells it ("B", "Return", "period", "BackSpace")
//   actionId   an id from KeybindActions.ACTIONS
//   argument   only meaningful when that action has hasArg; stored as "" otherwise

var CATEGORIES = [
    {
        name: "Apps",
        bindings: [
            { desc: "Browser", modifiers: ["SUPER"], key: "B", actionId: "exec", argument: "brave-browser-nightly" },
            { desc: "Terminal (WezTerm)", modifiers: ["SUPER"], key: "Return", actionId: "exec", argument: "wezterm-gui" },
            { desc: "Bluetooth manager", modifiers: ["CTRL", "ALT"], key: "B", actionId: "exec", argument: "blueman-manager" },
            { desc: "Reload shell", modifiers: ["SUPER", "SHIFT"], key: "R", actionId: "exec", argument: "qs --path ~/Projects/shell/real/shell.qml" },
            { desc: "Terminal (Kitty)", modifiers: ["SUPER", "ALT"], key: "K", actionId: "exec", argument: "kitty" }
        ]
    },
    {
        name: "Wallpaper",
        bindings: [
            { desc: "Random wallpaper", modifiers: ["SUPER", "SHIFT"], key: "W", actionId: "exec", argument: "caelestia shell wallpaper random" },
            { desc: "Random from folder", modifiers: ["CTRL", "SHIFT"], key: "P", actionId: "exec", argument: "caelestia shell wallpaper randomFrom ~/Pictures/some/ 0" },
            { desc: "Random videos from folder", modifiers: ["ALT", "SHIFT"], key: "P", actionId: "exec", argument: "caelestia shell wallpaper randomFrom ~/Pictures/some/ 2" }
        ]
    },
    {
        name: "Shell",
        bindings: [
            { desc: "Switch to Ambxst", modifiers: ["SUPER", "SHIFT"], key: "O", actionId: "exec", argument: "~/.config/dcli/scripts/switch-shell.sh ambxst" }
        ]
    },
    {
        name: "Scrolling layout",
        bindings: [
            { desc: "Move column right", modifiers: ["SUPER", "ALT"], key: "period", actionId: "scrolling.moveColRight", argument: "" },
            { desc: "Move column left", modifiers: ["SUPER", "ALT"], key: "comma", actionId: "scrolling.moveColLeft", argument: "" },
            { desc: "Increase column width", modifiers: ["SUPER", "SHIFT"], key: "period", actionId: "scrolling.colResizeIn", argument: "" },
            { desc: "Decrease column width", modifiers: ["SUPER", "SHIFT"], key: "comma", actionId: "scrolling.colResizeOut", argument: "" }
        ]
    },
    {
        name: "Workspaces",
        bindings: [
            { desc: "Next workspace", modifiers: ["SUPER"], key: "Tab", actionId: "workspace.next", argument: "" },
            { desc: "Previous workspace", modifiers: ["SUPER", "SHIFT"], key: "Tab", actionId: "workspace.prev", argument: "" }
        ]
    },
    {
        name: "Controls",
        bindings: [
            { desc: "Toggle game mode", modifiers: ["SUPER", "ALT"], key: "G", actionId: "exec", argument: "caelestia shell gameMode toggle" },
            { desc: "Toggle dashboard", modifiers: ["SUPER", "ALT"], key: "D", actionId: "exec", argument: "caelestia shell drawers toggle dashboard" },
            { desc: "Toggle taskbar", modifiers: ["SUPER", "SHIFT"], key: "A", actionId: "exec", argument: "caelestia shell drawers toggle bar" },
            { desc: "Open settings", modifiers: ["SUPER"], key: "I", actionId: "exec", argument: "caelestia shell nexus open" },
            { desc: "Toggle system monitor", modifiers: ["SUPER", "SHIFT"], key: "Return", actionId: "exec", argument: "caelestia toggle sysmon" },
            { desc: "Clipboard history", modifiers: ["SUPER"], key: "V", actionId: "global", argument: "caelestia:clipboard" },
            { desc: "Emoji picker", modifiers: ["SUPER"], key: "period", actionId: "global", argument: "caelestia:emoji" },
            { desc: "Clear clipboard", modifiers: ["SUPER"], key: "BackSpace", actionId: "global", argument: "caelestia:clearClipboard" }
        ]
    },
    {
        name: "Video wallpaper",
        bindings: [
            { desc: "Play video wallpaper", modifiers: ["CTRL", "SHIFT", "ALT"], key: "slash", actionId: "exec", argument: "~/.config/caelestia/myScripts/videoWallpepr.fish" },
            { desc: "Stop video wallpaper", modifiers: ["CTRL", "ALT"], key: "slash", actionId: "exec", argument: "pkill mpvpaper" },
            { desc: "Seek video wallpaper forward", modifiers: ["SUPER", "ALT"], key: "Right", actionId: "exec", argument: "caelestia shell wallpaper seekForward" },
            { desc: "Seek video wallpaper backward", modifiers: ["SUPER", "ALT"], key: "Left", actionId: "exec", argument: "caelestia shell wallpaper seekBackward" },
            { desc: "Toggle video wallpaper audio", modifiers: ["SUPER", "ALT"], key: "M", actionId: "exec", argument: "caelestia shell wallpaper toggleAudio" }
        ]
    },
    {
        name: "Awww wallpaper",
        bindings: [
            { desc: "Play awww wallpaper", modifiers: ["CTRL", "SHIFT"], key: "slash", actionId: "exec", argument: "~/.config/caelestia/myScripts/awww-Wallpaper.fish" },
            { desc: "Stop awww wallpaper", modifiers: ["CTRL"], key: "slash", actionId: "exec", argument: "awww kill" }
        ]
    },
    {
        name: "Hyprsunset",
        bindings: [
            { desc: "Toggle blue light filter", modifiers: ["SUPER"], key: "backslash", actionId: "exec", argument: "caelestia shell hyprSunset toggle" }
        ]
    }
];

// A fresh copy every call -- callers assign the result straight into the live `categories` and
// then mutate it, so handing out the module-level array would let edits leak into the defaults.
function categories() {
    return JSON.parse(JSON.stringify(CATEGORIES));
}
