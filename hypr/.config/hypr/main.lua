local hl = hl
local primaryMonitor = "DP-1"
local secondaryMonitor = "HDMI-A-1"

hl.monitor({
	output = primaryMonitor,
	mode = "5120x1440@120.00Hz",
	position = "0x0",
	scale = 1,
})
hl.monitor({
	output = secondaryMonitor,
	mode = "2560x1440@59.95Hz",
	position = "2560x-1440",
	scale = 1,
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,

		border_size = 2,

		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = false,

		-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 20,
		rounding_power = 2,

		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 0.9,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a,
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- Default springs
hl.curve("easy", { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
	master = {
		new_status = "master",
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
})

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = false,
		},
	},
})

local ipc = "noctalia msg "

local mainMod = "SUPER" -- Sets "Windows"/"Cmd" key as main modifier
local windowMod = "ALT" -- Sets "Alt" key as windows modifier

hl.bind(mainMod .. " + CTRL + Q", hl.dsp.exec_cmd(ipc .. "session lock"))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("ghostty"))
hl.bind(
	mainMod .. " + M",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd(ipc .. "window-switcher hold"))

-- Move focus with windowMod + hjkl keys
hl.bind(windowMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(windowMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(windowMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(windowMod .. " + l", hl.dsp.focus({ direction = "right" }))

-- Move windows with windowMod + shift + hjkl keys
hl.bind(windowMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(windowMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))
hl.bind(windowMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(windowMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))

hl.bind(windowMod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))

local workspaces = {
	{
		name = "code",
		monitor = primaryMonitor,
	},
	{
		name = "browser",
		monitor = secondaryMonitor,
	},
	{
		name = "social",
		monitor = primaryMonitor,
	},
	{
		name = "tasks",
		monitor = primaryMonitor,
	},
	{
		name = "notes",
		monitor = primaryMonitor,
	},
	{
		name = "music",
		monitor = primaryMonitor,
	},
	{
		name = "misc",
		monitor = primaryMonitor,
	},
	{
		name = "games",
		monitor = primaryMonitor,
	},
	{
		name = "secondary",
		monitor = secondaryMonitor,
	},
	{
		name = "secondary-misc",
		monitor = secondaryMonitor,
	},
}

for i, workspace in ipairs(workspaces) do
	hl.workspace_rule({
		workspace = i,
		monitor = workspace.monitor,
		persistent = true,
		default_name = workspace.name,
	})
	-- Movement keybinds
	local key = i % 10 -- 10 maps to key 0
	hl.bind(windowMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(windowMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad workspace, tilde
hl.bind(windowMod .. " + SHIFT + grave", hl.dsp.workspace.toggle_special("magic"))

-- Move/resize windows with windowMod + LMB/RMB and dragging
hl.bind(windowMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(windowMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(windowMod .. " + SHIFT + minus", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"))

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures/Screenshots"))

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

hl.layer_rule({
	name = "noctalia",
	match = {
		namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
	},
	no_anim = true,
	ignore_alpha = 0.5,
	blur = true,
	blur_popups = true,
})
