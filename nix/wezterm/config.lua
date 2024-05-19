local function capitalize(s)
	return s:sub(1, 1):upper() .. s:sub(2):lower()
end

local themeStyle = capitalize(os.getenv("THEME_STYLE") or "Mocha")

local w = require("wezterm")
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
}

local function get_dir(tab)
	local active_pane = tab.active_pane
	local current_dir = active_pane and active_pane.current_working_dir

	local dir = string.gsub(tostring(current_dir or "N/A"), "(.*[/\\])(.*)/", "%2")
	return dir
end

local function get_process(tab)
	if not tab.active_pane or tab.active_pane.foreground_process_name == "" then
		return nil
	end

	local process_name = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")
	if string.find(process_name, "kubectl") then
		process_name = "kubectl"
	end

	local icon = process_icons[process_name] or string.format("[%s]", process_name)
	return icon
end

w.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local has_unseen_output = false

	if not tab.is_active then
		for _, pane in ipairs(tab.panes) do
			if pane.has_unseen_output then
				has_unseen_output = true
				break
			end
		end
	end

	local idx = tab.tab_index + 1
	local process = get_process(tab)
	local cwd = get_dir(tab)

	local prefix = string.format(" %d:%s ", idx, process or "[?]")

	local space_left = (max_width - #prefix) + 1
	if #cwd > space_left then
		cwd = string.sub(cwd, 1, space_left - 2) .. ".."
	end

	local title = string.format("%s%s ", prefix, cwd)

	if has_unseen_output then
		return {
			{ Foreground = { Color = "#28719c" } },
			{ Text = title },
		}
	end

	return {
		{ Text = title },
	}
end)

return {
	leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 },
	font_size = 14.0,
	hide_tab_bar_if_only_one_tab = true,
	use_fancy_tab_bar = false,
	color_scheme = "Catppuccin " .. themeStyle, -- or Macchiato, Frappe, Latte
	keys = {
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
	},
}
