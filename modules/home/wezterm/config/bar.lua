local w = require("wezterm")
local utils = require("utils")

local M = {}
-- default config
local default_config = {
	max_width = 30,
	dividers = "slant_right",
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
		numerals = "arabic",
		pane_count = "superscript",
		process_icon = true,
		zoom_icon = true,
		brackets = {
			active = { "", ":" },
			inactive = { "", ":" },
		},
	},
	clock = {
		enabled = true,
		format = "%H:%M",
	},
	div = {
		l = "",
		r = "",
	},
}

-- parsed config
local merged_config = {}

local dividers = {
	slant_right = {
		left = utf8.char(0xe0be),
		right = utf8.char(0xe0bc),
	},
	slant_left = {
		left = utf8.char(0xe0ba),
		right = utf8.char(0xe0b8),
	},
	arrows = {
		left = utf8.char(0xe0b2),
		right = utf8.char(0xe0b0),
	},
	rounded = {
		left = utf8.char(0xe0b6),
		right = utf8.char(0xe0b4),
	},
}

-- conforming to https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd
-- exporting an apply_to_config function, even though we don't change the users config
M.apply_to_config = function(global_config, user_config)
	-- make the opts arg optional
	if not user_config then
		user_config = {}
	end

	-- combine user config with defaults
	merged_config = utils.table_merge(default_config, user_config)

	if merged_config.dividers then
		merged_config.div.l = dividers[merged_config.dividers].left
		merged_config.div.r = dividers[merged_config.dividers].right
	end

	-- set the right-hand padding to 0 spaces, if the rounded style is active
	merged_config.p = merged_config.dividers == "rounded" and "" or " "

	-- set wezterm config options according to the parsed config
	global_config.use_fancy_tab_bar = false
	global_config.show_new_tab_button_in_tab_bar = false
	global_config.tab_max_width = merged_config.max_width
end

-- superscript/subscript
local function pane_count_style(number, script)
	local scripts = {
		superscript = { "⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹" },
		subscript = { "₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉" },
	}
	local numbers = scripts[script]
	local number_string = tostring(number)
	local result = ""
	for i = 1, #number_string do
		local char = number_string:sub(i, i)
		local num = tonumber(char)
		if num then
			result = result .. numbers[num + 1]
		else
			result = result .. char
		end
	end
	return result
end

local roman_numerals = { "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ", "Ⅵ", "Ⅶ", "Ⅷ", "Ⅸ", "Ⅹ", "Ⅺ", "Ⅻ" }

local powerline_padding = 2

-- custom tab bar
w.on("format-tab-title", function(tab, tabs, _panes, conf, _hover, _max_width)
	local colors = conf.resolved_palette.tab_bar

	local active_tab_index = 0
	for _, t in ipairs(tabs) do
		if t.is_active == true then
			active_tab_index = t.tab_index
		end
	end

	local default_colors = {
		conf.resolved_palette.ansi[2],
		conf.resolved_palette.indexed[16],
		conf.resolved_palette.ansi[4],
		conf.resolved_palette.ansi[3],
		conf.resolved_palette.ansi[5],
		conf.resolved_palette.ansi[6],
	}

	local tab_colors
	if merged_config.tabs.colors and #merged_config.tabs.colors > 0 then
		tab_colors = merged_config.tabs.colors
	else
		tab_colors = default_colors
	end

	local i = tab.tab_index % #tab_colors
	local active_bg = tab_colors[i + 1]
	local active_fg = colors.background
	local inactive_bg = colors.inactive_tab.bg_color
	local inactive_fg = colors.inactive_tab.fg_color
	local bar_bg = colors.background

	local is_last_tab = (tab.tab_index == #tabs - 1)

	local s_bg, s_fg, e_bg, e_fg

	if tab.tab_index == active_tab_index - 1 then
		s_bg = inactive_bg
		s_fg = inactive_fg
		e_bg = tab_colors[(i + 1) % #tab_colors + 1]
		e_fg = inactive_bg
	elseif tab.is_active then
		s_bg = active_bg
		s_fg = active_fg
		e_bg = is_last_tab and bar_bg or inactive_bg
		e_fg = active_bg
	else
		s_bg = inactive_bg
		s_fg = inactive_fg
		e_bg = is_last_tab and bar_bg or inactive_bg
		e_fg = inactive_bg
	end

	local pane_count = ""
	if merged_config.tabs.pane_count then
		local tabi = w.mux.get_tab(tab.tab_id)
		local muxpanes = tabi:panes()
		local count = #muxpanes == 1 and "" or tostring(#muxpanes)
		pane_count = pane_count_style(count, merged_config.tabs.pane_count)
	end

	local index_i
	if merged_config.tabs.numerals == "roman" then
		index_i = roman_numerals[tab.tab_index + 1]
	else
		index_i = tab.tab_index + 1
	end

	local index
	if tab.is_active then
		index = string.format(
			"%s%s%s",
			merged_config.tabs.brackets.active[1],
			index_i,
			merged_config.tabs.brackets.active[2]
		)
	else
		index = string.format(
			"%s%s%s",
			merged_config.tabs.brackets.inactive[1],
			index_i,
			merged_config.tabs.brackets.inactive[2]
		)
	end

	local icon = merged_config.tabs.process_icon and (utils.get_process_icon(tab) .. " ") or ""
	local name = utils.build_tab_title(tab, merged_config.tabs.zoom_icon)

	local tab_title = string.format("%s%s%s", index, icon, name)

	-- start and end hardcoded numbers are the Powerline + " " padding
	local filler_width = powerline_padding * 2 + string.len(index) + string.len(pane_count)
	local width = merged_config.max_width - filler_width - 1
	if (#tab_title + filler_width) > merged_config.max_width then
		tab_title = w.truncate_right(tab_title, width) .. "…"
	end

	local title = string.format(" %s%s%s", tab_title, pane_count, merged_config.p)

	return {
		{ Background = { Color = s_bg } },
		{ Foreground = { Color = s_fg } },
		{ Text = title },
		{ Background = { Color = e_bg } },
		{ Foreground = { Color = e_fg } },
		{ Text = merged_config.div.r },
	}
end)

w.on("update-status", function(window, _pane)
	local active_kt = window:active_key_table() ~= nil
	local show = merged_config.indicator.leader.enabled or (active_kt and merged_config.indicator.mode.enabled)
	if not show then
		window:set_left_status("")
		return
	end

	local present, conf = pcall(window.effective_config, window)
	if not present then
		return
	end
	local palette = conf.resolved_palette

	local leader = ""
	if merged_config.indicator.leader.enabled then
		local leader_text = merged_config.indicator.leader.off
		if window:leader_is_active() then
			leader_text = merged_config.indicator.leader.on
		end
		leader = w.format({
			{ Foreground = { Color = palette.background } },
			{ Background = { Color = palette.ansi[5] } },
			{ Text = " " .. leader_text .. merged_config.p },
		})
	end

	local mode = ""
	if merged_config.indicator.mode.enabled then
		local mode_text = ""
		local active = window:active_key_table()
		if merged_config.indicator.mode.names[active] ~= nil then
			mode_text = merged_config.indicator.mode.names[active] .. ""
		end
		mode = w.format({
			{ Foreground = { Color = palette.background } },
			{ Background = { Color = palette.ansi[5] } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = mode_text },
			"ResetAttributes",
		})
	end

	local first_tab_active = window:mux_window():tabs_with_info()[1].is_active
	local divider_bg = first_tab_active and palette.ansi[2] or palette.tab_bar.inactive_tab.bg_color

	local divider = w.format({
		{ Background = { Color = divider_bg } },
		{ Foreground = { Color = palette.ansi[5] } },
		{ Text = merged_config.div.r },
	})

	window:set_left_status(leader .. mode .. divider)

	if merged_config.clock.enabled then
		local time = w.time.now():format(merged_config.clock.format) .. " "
		window:set_right_status(w.format({
			{ Background = { Color = palette.tab_bar.background } },
			{ Foreground = { Color = palette.ansi[6] } },
			{ Text = time },
		}))
	else
		window:set_right_status("")
	end
end)

return M
