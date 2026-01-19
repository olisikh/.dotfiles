local bar = require("bar")
local nav = require("nav")

local theme_style = "Mocha"

local w = require("wezterm")
local config = w.config_builder()

local bg_opacity = 1

config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 }
config.font_size = 13.0
config.hide_tab_bar_if_only_one_tab = false
config.window_background_opacity = bg_opacity
config.macos_window_background_blur = 10
config.audible_bell = "Disabled" -- or "SystemBeep"

config.color_scheme = "Catppuccin " .. theme_style
config.colors = {
	tab_bar = {
		-- TODO: how to access catppuccin palette, take the color and apply opacity?
		-- catppuccin mocha background
		background = "rgba(30, 30, 46," .. bg_opacity .. ")",
	},
}

config.keys = {
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

	-- Disable M+Enter hotkey to use it in Neovim
	{
		key = "Enter",
		mods = "ALT",
		action = w.action.DisableDefaultAssignment,
	},
}

nav.apply_to_config(config)
bar.apply_to_config(config, {
	dividers = "arrows", -- or "slant_right", "slant_left", "arrows", "rounded", false
	tabs = {
		numerals = "arabic", -- or "roman"
		pane_count = "superscript", -- or "subscript", false
		process_icon = false,
		zoom_icon = true, -- an icon "🔍", or boolean
	},
	clock = { -- note that this overrides the whole set_right_status
		enabled = false,
	},
})

return config
