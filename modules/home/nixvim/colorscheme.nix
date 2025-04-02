{ nixvimLib, ... }: {
  catppuccin = {
    enable = true;
    settings = {
      dim_inactive = {
        enabled = false;
      };
      transparent_background = false;
      default_integrations = true;
      integrations = {
        fidget = true;
        cmp = false;
        blink_cmp = true;
        gitsigns = true;
        nvimtree = true;
        neotest = true;
        treesitter = true;
        treesitter_context = true;
        telescope.enabled = true;
        lsp_trouble = true;
        harpoon = true;
        mason = true;
        notify = true;
        which_key = true;
        dap = true;
        dap_ui = true;
        markdown = true;
        indent_blankline = {
          enabled = true;
          colored_indent_levels = false;
        };
        native_lsp = {
          enabled = true;
          virtual_text = {
            errors = [ "italic" ];
            hints = [ "italic" ];
            warnings = [ "italic" ];
            information = [ "italic" ];
          };
          underlines = {
            errors = [ "underline" ];
            hints = [ "underline" ];
            warnings = [ "underline" ];
            information = [ "underline" ];
          };
          inlay_hints = {
            background = false;
          };
        };
      };
      custom_highlights = nixvimLib.mkRaw ''
        function(colors)
          return {
            WinSeparator = { fg = colors.overlay0 } -- make window borders more visible
          }
        end
      '';
    };
  };
}
