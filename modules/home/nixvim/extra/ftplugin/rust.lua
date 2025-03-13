local bufnr = vim.api.nvim_get_current_buf()

vim.keymap.set("n", "<leader>cd", function()
	vim.cmd.RustLsp("explainError")
end, { desc = "rust: [c]ode [d]iagnostic" })
