{
  plugins.octools-nvim = {
    enable = true;
  };

  extraConfigLua = ''
    require("octools").setup({
      opencode_cmd = "opencode",
      model = "opencode/gpt-5.1-codex-mini",
      notify = true,
      show_fidget = true,
    })

    vim.keymap.set({ "n", "v" }, "<leader>oi", ":OcTools implement<CR>", { desc = "octools: implement at cursor" })
    vim.keymap.set({ "n", "v" }, "<leader>oC", ":OcTools cancel<CR>", { desc = "octools: cancel generation" })
  '';
}
