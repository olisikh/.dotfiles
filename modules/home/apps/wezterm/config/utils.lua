local w = require("wezterm")

local M = {}

function M.table_merge(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == "table" then
			if type(t1[k] or false) == "table" then
				M.table_merge(t1[k] or {}, t2[k] or {})
			else
				t1[k] = v
			end
		else
			t1[k] = v
		end
	end
	return t1
end

function M.get_dir(tab)
	local active_pane = tab.active_pane
	local current_dir = active_pane and active_pane.current_working_dir

	if current_dir then
		return string.gsub(tostring(current_dir), "(.*[/\\])(.*)/", "%2")
	end

	return nil
end

function M.is_vim(pane)
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

function M.build_tab_title(tab)
	local tab_title = nil
	if #tab.tab_title > 0 then
		tab_title = tab.tab_title
	else
		tab_title = M.get_dir(tab) or tab.active_pane.title
	end

	return tab_title
end

function M.get_zoom_icon(tab, zoom_icon)
	if zoom_icon and tab.active_pane and tab.active_pane.is_zoomed then
		local icon = ""
		if type(zoom_icon) == "string" then
			icon = zoom_icon
		else
			-- Keep zoom explicit, but as a trailing state marker so titles remain
			-- easy to scan from their left edge.
			icon = " 󰊓"
		end

		return icon
	end

	return ""
end

return M
