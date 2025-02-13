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
		-- rotate splits
		{ mods = "LEADER", key = "b", action = w.action.RotatePanes("CounterClockwise") },
		{ mods = "LEADER", key = "n", action = w.action.RotatePanes("Clockwise") },

		-- activate copy mode or vim mode
		{ mods = "LEADER", key = "[", action = w.action.ActivateCopyMode },

		{ mods = "LEADER", key = "1", action = w.action({ MoveTab = 0 }) },
		{ mods = "LEADER", key = "2", action = w.action({ MoveTab = 1 }) },
		{ mods = "LEADER", key = "3", action = w.action({ MoveTab = 2 }) },
		{ mods = "LEADER", key = "4", action = w.action({ MoveTab = 3 }) },
		{ mods = "LEADER", key = "5", action = w.action({ MoveTab = 4 }) },
		{ mods = "LEADER", key = "6", action = w.action({ MoveTab = 5 }) },
		{ mods = "LEADER", key = "7", action = w.action({ MoveTab = 6 }) },
		{ mods = "LEADER", key = "8", action = w.action({ MoveTab = 7 }) },
		{ mods = "LEADER", key = "9", action = w.action({ MoveTab = 8 }) },

		-- map a tab
		{ mods = "LEADER", key = "c", action = w.action({ SpawnTab = "CurrentPaneDomain" }) },
		-- close a tab
		{ mods = "LEADER|SHIFT", key = "&", action = w.action({ CloseCurrentTab = { confirm = true } }) },

		-- close current pane
		{ mods = "LEADER", key = "d", action = w.action({ CloseCurrentPane = { confirm = true } }) },
		{ mods = "LEADER", key = "x", action = w.action({ CloseCurrentPane = { confirm = true } }) },

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
