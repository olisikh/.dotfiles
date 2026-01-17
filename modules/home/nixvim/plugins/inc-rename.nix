{ ... }:
{
  plugins.inc-rename = {
    enable = true;

    luaConfig.post = ''
      vim.keymap.set("n", "<leader>rn", function()
        return ":IncRename " .. vim.fn.expand("<cword>")
      end, { expr = true, desc = "lsp: incremental [r]e[n]ame" })
    '';
  };
}
