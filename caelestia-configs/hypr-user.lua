-- ~/.config/caelestia/hypr-user.lua
-- User overrides — loaded last, can override anything above
local vars = require("hypr-vars")
-- Exec
hl.exec_cmd("systemctl --user start hyprpolkitagent")

hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

-- Layout. These come from Nexus > Hyprland > Config, which stores them as `cfg*` keys in
-- hypr-vars.lua. `or` keeps the file working if a key hasn't been written yet.
hl.config({
	general = { layout = vars.cfgLayout or "scrolling" },
	scrolling = {
		column_width = vars.cfgColumnWidth or 0.85,
		explicit_column_widths = vars.cfgExplicitColumnWidths or "0.35, 0.5, 0.65, 0.95, 1.0",
	},
})

-- Animations
hl.config({
	animations = {
		-- `~= false` rather than `or true`: false is a legitimate value that `or` would discard.
		enabled = vars.cfgAnimationsEnabled ~= false,
	},
})
-- hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "standard", style = "slidevert" })
hl.curve("niri_wobble", { type = "bezier", points = { { 0.15, 1.15 }, { 0.35, 1.0 } } })
hl.curve("niri_decel", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("niri_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "niri_wobble", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "niri_accel", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "niri_decel", style = "slide" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "niri_decel" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "niri_accel" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "niri_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, bezier = "niri_accel", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "niri_decel", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 4, bezier = "niri_wobble", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 4, bezier = "niri_accel", style = "slidevert" })

hl.config({
	gestures = {
		workspace_swipe_distance = vars.cfgSwipeDistance or 500,
		workspace_swipe_cancel_ratio = vars.cfgSwipeCancelRatio or 0.15,
		workspace_swipe_min_speed_to_force = vars.cfgSwipeMinSpeed or 5,
		workspace_swipe_direction_lock = vars.cfgSwipeDirectionLock ~= false,
		workspace_swipe_direction_lock_threshold = 10,
		workspace_swipe_create_new = vars.cfgSwipeCreateNew ~= false,
	},
})

hl.gesture({
	fingers = vars.workspaceSwipeFingers, -- match the original number of fingers
	direction = "horizontal",
	action = "unset",
})
hl.gesture({
	fingers = vars.workspaceSwipeFingers,
	direction = "horizontal",
	action = "workspace",
})
-- Input
hl.config({
	input = {
		kb_layout = vars.cfgKbLayout or "us,ara",
		kb_variant = vars.cfgKbVariant or "",
		kb_options = vars.cfgKbOptions or "grp:win_space_toggle, ctrl:nocaps",
		sensitivity = vars.cfgSensitivity or 0.3,
		accel_profile = vars.cfgAccelProfile or "flat",
	},
})

-- Env
hl.config({
	env = {
		{ "QML2_IMPORT_PATH", os.getenv("HOME") .. "/.local/lib/qt6/qml" },
		{ "CAELESTIA_LIB_DIR", os.getenv("HOME") .. "/.local/lib/caelestia" },
		-- Lucienne/VCN2 has no AV1 hwdec and Qt's FFmpeg backend won't fall
		-- back to software on its own — force it for video wallpapers.
		{ "QT_FFMPEG_DECODING_HW_DEVICE_TYPES", "none" },
	},
})

-- Tap Super alone = launcher. Upstream keybinds.lua already binds this, and a
-- second bind on the same combo fires the toggle twice (opens then closes it),
-- so do NOT re-add it here.

-- Super+Z / Super+X: hold and move the mouse to move/resize the window
-- (bound in keybinds.lua), tap without dragging to change workspace. The tap
-- half is `click = true` — a release bind that only fires when the pointer
-- stayed within binds:drag_threshold, so it doesn't fight the hold bind.
hl.bind("SUPER + Z", hl.dsp.focus({ workspace = "-1" }), { click = true })
hl.bind("SUPER + X", hl.dsp.focus({ workspace = "+1" }), { click = true })
