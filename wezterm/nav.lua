local w = require("wezterm")
local utils = require("utils")

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

---Nvim-like navigation in wezterm
---@param resize_or_move string expected to be one of "resize" or "move"
---@param key string key name
---@return table
local function split_nav(resize_or_move, key)
	local mods = resize_or_move == "resize" and "META" or "CTRL"
	return {
		key = key,
		mods = mods,
		action = w.action_callback(function(win, pane)
			if utils.is_vim(pane) then
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

local M = {}

function M.apply_to_config(c)
	local function merge_keys(t1, t2)
		for _, v in ipairs(t2) do
			table.insert(t1, v)
		end
		return t1
	end

	c.keys = merge_keys(c.keys or {}, {
		-- split window
		{ mods = "LEADER", key = '"', action = w.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ mods = "LEADER", key = "%", action = w.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

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
	})
end

return M
