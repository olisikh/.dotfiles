local w = require("wezterm")
local nf = w.nerdfonts

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
	["java"] = nf.dev_java,
	["gear"] = "",
}

function M.is_vim(pane)
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

function M.get_process(tab)
	if not tab.active_pane or tab.active_pane.foreground_process_name == "" then
		return process_icons["gear"]
	end

	local process_name = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")
	if string.find(process_name, "kubectl") then
		process_name = "kubectl"
	end

	return process_icons[process_name] or string.format("[%s]", process_name)
end

function M.build_tab_title(tab)
	local tab_title = nil
	if #tab.tab_title > 0 then
		tab_title = tab.tab_title
	else
		tab_title = M.get_dir(tab) or tab.active_pane.title
	end

	if tab.active_pane.is_zoomed then
		tab_title = " " .. tab_title
	end

	return tab_title
end

return M
