local utils = require("utils")
local bar = require("bar")
local nav = require("nav")

local themeStyle = utils.capitalize(os.getenv("THEME_STYLE") or "Mocha")

local w = require("wezterm")
local c = w.config_builder()

c.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 }
c.font_size = 14.0
c.hide_tab_bar_if_only_one_tab = false
c.color_scheme = "Catppuccin " .. themeStyle

c.keys = {
	-- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
	{ mods = "OPT", key = "LeftArrow", action = w.action({ SendString = "\x1bb" }) },
	-- Make Option-Right equivalent to Alt-f; forward-word
	{ mods = "OPT", key = "RightArrow", action = w.action({ SendString = "\x1bf" }) },

	-- Set a custom title for a tab
	{
		key = "E",
		mods = "LEADER",
		action = w.action.PromptInputLine({
			description = "Enter new name for tab",
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
}

nav.apply_to_config(c)
bar.apply_to_config(c, {
	max_width = 25,
	dividers = "arrows", -- or "slant_right", "slant_left", "arrows", "rounded", false
	indicator = {
		leader = {
			enabled = true,
			off = " ",
			on = " ",
		},
		mode = {
			enabled = true,
			names = {
				resize_mode = "RESIZE",
				copy_mode = "VISUAL",
				search_mode = "SEARCH",
			},
		},
	},
	tabs = {
		numerals = "arabic", -- or "roman"
		pane_count = "superscript", -- or "subscript", false
		brackets = {
			active = { "", ":" },
			inactive = { "", ":" },
		},
	},
	clock = { -- note that this overrides the whole set_right_status
		enabled = true,
		format = "%H:%M", -- use https://wezfurlong.org/wezterm/config/lua/wezterm.time/Time/format.html
	},
})

return c
