local w = require("wezterm")

local bar = require("bar")
local nav = require("nav")

local config = w.config_builder()

local bg_opacity = 1
local bell_enabled = true

config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 }

config.font = w.font("JetBrains Mono", { weight = "Medium" })
config.font_size = 15.0

config.hide_tab_bar_if_only_one_tab = false
config.window_background_opacity = bg_opacity
config.macos_window_background_blur = 10
config.audible_bell = "Disabled" -- or "SystemBeep"
config.unzoom_on_switch_pane = true

config.color_scheme = "Catppuccin Mocha"
config.colors = {
	tab_bar = {
		-- TODO: how to access catppuccin palette, take the color and apply opacity?
		-- catppuccin mocha background
		background = "rgba(30, 30, 46," .. bg_opacity .. ")",
	},
}

config.keys = {
	-- Hermes recognizes Option-Enter as a multiline key. Map Shift-Enter to its
	-- exact escape sequence because WezTerm otherwise sends it as plain Enter.
	{ mods = "SHIFT", key = "Enter", action = w.action({ SendString = "\x1b\r" }) },

	-- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
	{ mods = "OPT", key = "LeftArrow", action = w.action({ SendString = "\x1bb" }) },
	-- Make Option-Right equivalent to Alt-f; forward-word
	{ mods = "OPT", key = "RightArrow", action = w.action({ SendString = "\x1bf" }) },

	-- Set a custom title for a tab
	{
		key = "E",
		mods = "LEADER",
		action = w.action.PromptInputLine({
			description = "Rename tab",
			action = w.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Show workspaces menu
	{
		key = "w",
		mods = "LEADER",
		action = w.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES", title = "Workspaces" }),
	},
	{
		key = "t",
		mods = "LEADER",
		action = w.action.ShowLauncherArgs({ flags = "FUZZY|TABS", title = "Tabs" }),
	},
	{
		key = "l",
		mods = "LEADER",
		action = w.action.ShowLauncherArgs({ flags = "FUZZY|COMMANDS", title = "Commands launcher" }),
	},

	-- Rename current workspace
	{
		key = "R",
		mods = "LEADER",
		action = w.action.PromptInputLine({
			description = "Rename workspace",
			action = w.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					w.mux.rename_workspace(w.mux.get_active_workspace(), line)
				end
			end),
		}),
	},

	-- Toggle bell sound (mute)
	{
		key = "m",
		mods = "LEADER",
		action = w.action_callback(function(window, pane)
			bell_enabled = not bell_enabled
			local msg = bell_enabled and "Bell: ON" or "Bell: OFF"
			window:toast_notification("wezterm", msg, nil, 2000)
		end),
	},

	-- Disable M+Enter hotkey to use it in Neovim
	{
		key = "Enter",
		mods = "ALT",
		action = w.action.DisableDefaultAssignment,
	},
}

-- HACK: peak terminal customization
w.on("bell", function(window, pane)
	if not bell_enabled then
		return
	end
	w.run_child_process({ "afplay", w.config_dir .. "/faaah.mp3" })
end)

nav.apply_to_config(config)
bar.apply_to_config(config, {
	dividers = "arrows", -- or "slant_right", "slant_left", "arrows", "rounded", false
	tabs = {
		process_icon = false,
	},
	clock = { -- note that this overrides the whole set_right_status
		enabled = false,
	},
})

-- Persistent bell mute indicator in right status (overrides bar's empty string)
w.on("update-status", function(window)
	if not bell_enabled then
		window:set_right_status(w.format({
			{ Foreground = { Color = "#f38ba8" } },
			{ Text = " 🔇 " },
		}))
	end
end)

return config
