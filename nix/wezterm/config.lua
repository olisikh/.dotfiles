local function capitalize(s)
	return s:sub(1, 1):upper() .. s:sub(2):lower()
end

local function truncate(s, max_length)
	if #s > max_length then
		return string.sub(s, 1, max_length - 2) .. ".."
	else
		return s
	end
end

local themeStyle = capitalize(os.getenv("THEME_STYLE") or "Mocha")

local w = require("wezterm")
local c = w.config_builder()
local nf = w.nerdfonts

local function is_vim(pane)
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	Left = "h",
	Down = "j",
	Up = "k",
	Right = "l",
	-- reverse lookup
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key)
	local mods = resize_or_move == "resize" and "META" or "CTRL"
	return {
		key = key,
		mods = mods,
		action = w.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

local process_icons = {
	["docker"] = nf.linux_docker,
	["docker-compose"] = nf.linux_docker,
	["scala"] = "",
	["psql"] = "󱤢",
	["usql"] = "󱤢",
	["kuberlr"] = nf.linux_docker,
	["ssh"] = nf.fa_exchange,
	["ssh-add"] = nf.fa_exchange,
	["kubectl"] = nf.linux_docker,
	["stern"] = nf.linux_docker,
	["nvim"] = nf.custom_vim,
	["make"] = nf.seti_makefile,
	["vim"] = nf.dev_vim,
	["node"] = nf.mdi_hexagon,
	["go"] = nf.seti_go,
	["python3"] = "",
	["python"] = "",
	["zsh"] = nf.dev_terminal,
	["bash"] = nf.cod_terminal_bash,
	["btm"] = nf.mdi_chart_donut_variant,
	["htop"] = nf.mdi_chart_donut_variant,
	["cargo"] = nf.dev_rust,
	["sudo"] = nf.fa_hashtag,
	["lazydocker"] = nf.linux_docker,
	["git"] = nf.dev_git,
	["lua"] = nf.seti_lua,
	["wget"] = nf.mdi_arrow_down_box,
	["curl"] = nf.mdi_flattr,
	["gh"] = nf.dev_github_badge,
	["ruby"] = nf.cod_ruby,
	["gear"] = "",
}

local function get_dir(tab)
	local active_pane = tab.active_pane
	local current_dir = active_pane and active_pane.current_working_dir

	return string.gsub(tostring(current_dir or "unknown"), "(.*[/\\])(.*)/", "%2")
end

local function get_process(tab)
	if not tab.active_pane or tab.active_pane.foreground_process_name == "" then
		return process_icons["gear"]
	end

	local process_name = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")
	if string.find(process_name, "kubectl") then
		process_name = "kubectl"
	end

	return process_icons[process_name] or string.format("[%s]", process_name)
end

w.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local idx = tab.tab_index + 1
	local process = get_process(tab)

	local new_title = nil
	if #tab.tab_title > 0 then
		new_title = tab.tab_title
	else
		new_title = get_dir(tab)
	end

	local prefix = string.format(" %d:%s ", idx, process or "[?]")

	new_title = truncate(new_title, (max_width - #prefix) + 1)

	local title = string.format("%s%s ", prefix, new_title)

	-- local has_unseen_output = false
	-- if not tab.is_active then
	-- 	for _, pane in ipairs(tab.panes) do
	-- 		if pane.has_unseen_output then
	-- 			has_unseen_output = true
	-- 			break
	-- 		end
	-- 	end
	-- end
	--
	-- if has_unseen_output then
	-- 	return {
	-- 		{ Foreground = { Color = "#28719c" } },
	-- 		{ Text = title },
	-- 	}
	-- end

	return {
		{ Text = title },
	}
end)

c.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 }
c.font_size = 14.0
c.hide_tab_bar_if_only_one_tab = true
c.use_fancy_tab_bar = false
c.color_scheme = "Catppuccin " .. themeStyle
c.keys = {
	-- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
	{ mods = "OPT", key = "LeftArrow", action = w.action({ SendString = "\x1bb" }) },
	-- Make Option-Right equivalent to Alt-f; forward-word
	{ mods = "OPT", key = "RightArrow", action = w.action({ SendString = "\x1bf" }) },

	-- split window
	{ mods = "LEADER", key = '"', action = w.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ mods = "LEADER", key = "%", action = w.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

	-- move between split panes
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),

	-- resize panes
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),

	-- zoom into split
	{ mods = "LEADER", key = "z", action = w.action.TogglePaneZoomState },

	-- swap splits
	{ mods = "LEADER", key = "Space", action = w.action.PaneSelect({ mode = "SwapWithActive" }) },

	-- activate copy mode or vim mode
	{ key = "[", mods = "LEADER", action = w.action.ActivateCopyMode },

	{ key = "1", mods = "LEADER", action = w.action({ ActivateTab = 0 }) },
	{ key = "2", mods = "LEADER", action = w.action({ ActivateTab = 1 }) },
	{ key = "3", mods = "LEADER", action = w.action({ ActivateTab = 2 }) },
	{ key = "4", mods = "LEADER", action = w.action({ ActivateTab = 3 }) },
	{ key = "5", mods = "LEADER", action = w.action({ ActivateTab = 4 }) },
	{ key = "6", mods = "LEADER", action = w.action({ ActivateTab = 5 }) },
	{ key = "7", mods = "LEADER", action = w.action({ ActivateTab = 6 }) },
	{ key = "8", mods = "LEADER", action = w.action({ ActivateTab = 7 }) },
	{ key = "9", mods = "LEADER", action = w.action({ ActivateTab = 8 }) },

	{ key = "c", mods = "LEADER", action = w.action({ SpawnTab = "CurrentPaneDomain" }) },
	{ key = "&", mods = "LEADER|SHIFT", action = w.action({ CloseCurrentTab = { confirm = true } }) },
	{ key = "d", mods = "LEADER", action = w.action({ CloseCurrentPane = { confirm = true } }) },
	{ key = "x", mods = "LEADER", action = w.action({ CloseCurrentPane = { confirm = true } }) },

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

w.plugin.require("https://github.com/nekowinston/wezterm-bar").apply_to_config(c, {
	position = "top",
	max_width = 25,
	dividers = "slant_right", -- or "slant_left", "arrows", "rounded", false
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
