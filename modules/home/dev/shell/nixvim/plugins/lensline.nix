{ ... }:
{
  plugins.lensline = {
    enable = true;
    settings = {
      profiles = [
        {
          name = "default";
          style = {
            placement = "inline";
            prefix = "";
            highlight = "LenslineText";
          };
        }
      ];
    };
  };

  extraConfigLua = ''
    -- Change the style of lens text (inspired by gitsigns current_line_blame).
    local function lensline_apply_highlight()
      vim.api.nvim_set_hl(0, "LenslineText", { fg = "#45475a" })
    end

    lensline_apply_highlight()

    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("LenslineHighlight", { clear = true }),
      callback = lensline_apply_highlight,
    })
  '';
}
