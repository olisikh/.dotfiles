local w = require("wezterm")
local nf = w.nerdfonts

local M = {}

function M.capitalize(s)
	return s:sub(1, 1):upper() .. s:sub(2):lower()
end

function M.truncate(s, max_length)
	if #s > max_length then
		return string.sub(s, 1, max_length - 2) .. ".."
	else
		return s
	end
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

return M
