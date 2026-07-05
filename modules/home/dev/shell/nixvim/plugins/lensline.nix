{ ... }:
{
  plugins.lensline = {
    enable = true;
    settings = {
      profiles = [
        {
          name = "default";
          providers = [
            {
              name = "usages";
              enabled = true;
              include = [ "refs" ];
              breakdown = true;
              show_zero = false;
              labels = {
                refs = "refs";
                impls = "impls";
                defs = "defs";
                usages = "usages";
              };
              icon_for_single = "󰌹 ";
              inner_separator = ", ";
            }
            {
              name = "complexity";
              enabled = true;
              min_level = "L";
            }
            {
              name = "last_author";
              enabled = true;
              cache_max_files = 50;
            }
          ];

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
