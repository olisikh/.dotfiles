vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.expandtab = true

local function java_action(kind, desc)
	return function()
		vim.lsp.buf.code_action({
			context = { only = { kind } },
			apply = true,
		})
	end
end

local map_opts = { buffer = true, silent = true }

vim.keymap.set(
	"n",
	"<leader>co",
	java_action("source.organizeImports"),
	vim.tbl_extend("force", map_opts, { desc = "java: [o]rganize imports" })
)
vim.keymap.set(
	{ "n", "v" },
	"<leader>cev",
	java_action("refactor.extract.variable"),
	vim.tbl_extend("force", map_opts, { desc = "java: [e]xtract [v]ariable" })
)
vim.keymap.set(
	{ "n", "v" },
	"<leader>cec",
	java_action("refactor.extract.constant"),
	vim.tbl_extend("force", map_opts, { desc = "java: [e]xtract [c]onstant" })
)
vim.keymap.set(
	{ "n", "v" },
	"<leader>cem",
	java_action("refactor.extract.method"),
	vim.tbl_extend("force", map_opts, { desc = "java: [e]xtract [m]ethod" })
)
vim.keymap.set(
	{ "n", "v" },
	"<leader>ci",
	java_action("refactor.inline"),
	vim.tbl_extend("force", map_opts, { desc = "java: [i]nline" })
)
vim.keymap.set("n", "<leader>cg", function()
	vim.lsp.buf.code_action({
		context = { only = { "source.generate" } },
	})
end, vim.tbl_extend("force", map_opts, { desc = "java: [g]enerate" }))
