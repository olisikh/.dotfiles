{ ... }:
{
  plugins.inc-rename = {
    enable = true;

    luaConfig.post = ''
      vim.keymap.set("n", "<leader>rn", function()
        return ":IncRename " .. vim.fn.expand("<cword>")
      end, { expr = true })
    '';
  };
}
