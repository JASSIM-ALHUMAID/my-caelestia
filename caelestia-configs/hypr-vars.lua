-- ~/.config/caelestia/hypr-vars.lua
-- User variable overrides (merged into variables.lua table)

return {
	-- Apps. `browser` is what kbBrowser (SUPER + W) launches; upstream
	-- defaults it to firefox, which isn't installed here.
	terminal = "app2unit -- org.wezfurlong.wezterm.desktop",
	editor = "app2unit -- devin-desktop.desktop",
	browser = "app2unit -- zen.desktop",
	fileExplorer = "app2unit -- org.gnome.Nautilus.desktop",
	audioSettings = "app2unit -- com.github.wwmm.easyeffects.desktop",

	-- Touchpad
	touchpadDisableTyping = true,
	touchpadScrollFactor = 0.3,
	gestureFingers = 3,
	workspaceSwipeFingers = 3,
	gestureFingersMore = 4,

	-- Misc
	volumeStep = 8,
	volumeMax = 110,
	cursorTheme = "material_light_cursors",
	cursorSize = 24,

	-- Gaps
	workspaceGaps = 20,
	windowGapsIn = 5,
	windowGapsOut = 10,
	singleWindowGapsOut = 20,

	-- Blur
	blurEnabled = true,
	blurSize = 8,
	blurPasses = 2,

	-- Shadow
	shadowEnabled = true,
	shadowRange = 15,
	shadowRenderPower = 4,

	-- Window
	windowOpacity = 1,
	windowRounding = 15,
	windowBorderSize = 1,

	-- Keybinds
	kbToggleWindowFloating = "SUPER + SHIFT + F",

	-- Managed by Nexus
	blurSpecialWs = false,
	blurPopups = true,
	blurInputMethods = true,
	blurXray = false,
	sleepGestureCmd = "systemctl suspend-then-hibernate",
	cfgLayout = "scrolling",
	cfgColumnWidth = 0.85,
	cfgExplicitColumnWidths = "0.35, 0.5, 0.65, 0.95, 1.0",
	cfgKbLayout = "us,ara",
	cfgKbVariant = "",
	cfgKbOptions = "grp:win_space_toggle, ctrl:nocaps",
	cfgSensitivity = 0.3,
	cfgAccelProfile = "flat",
	cfgAnimationsEnabled = true,
	cfgSwipeDistance = 400,
	cfgSwipeCancelRatio = 0.15,
	cfgSwipeMinSpeed = 5,
	cfgSwipeDirectionLock = true,
	cfgSwipeCreateNew = true,

	-- Managed by Nexus
	kbMoveWinToWs = "SUPER + ALT",
	kbMoveWinToWsGroup = "CTRL + SUPER + ALT",
	kbGoToWs = "SUPER",
	kbGoToWsGroup = "CTRL + SUPER",
	kbNextWs = "CTRL + SUPER + Right",
	kbPrevWs = "CTRL + SUPER + Left",
	kbWindowGroupCycleNext = "ALT + TAB",
	kbWindowGroupCyclePrev = "SHIFT + ALT + TAB",
	kbUngroup = "SUPER + U",
	kbToggleGroup = "SUPER + Comma",
	kbMoveWindow = "SUPER + Z",
	kbResizeWindow = "SUPER + X",
	kbWindowPip = "SUPER + ALT + backslash",
	kbPinWindow = "SUPER + P",
	kbWindowFullscreen = "SUPER + F",
	kbWindowBorderedFullscreen = "SUPER + ALT + F",
	kbCloseWindow = "SUPER + Q",
	kbSpecialWs = "SUPER + S",
	kbSystemMonitorWs = "CTRL + SHIFT + Escape",
	kbMusicWs = "SUPER + M",
	kbCommunicationWs = "SUPER + D",
	kbTodoWs = "SUPER + R",
	kbTerminal = "SUPER + T",
	kbBrowser = "SUPER + W",
	kbEditor = "SUPER + C",
	kbFileExplorer = "SUPER + E",
	kbSession = "CTRL + ALT + Delete",
	kbShowSidebar = "SUPER + N",
	kbClearNotifs = "CTRL + ALT + C",
	kbShowPanels = "SUPER + K",
	kbLock = "SUPER + L",
	kbRestoreLock = "SUPER + ALT + L",
}
