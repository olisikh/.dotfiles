{ self, ... }: {

    plugins = {
      web-devicons.enable = true;

      lualine.enable = true;
      # wezterm.enable = true;

      oil = {
        enable = true;
      };

      treesitter = {
        enable = true;
      };


      nvim-autopairs = {
        enable = true;
      };

      lazygit = {
        enable = true;
      };

      dap = {
        enable = true;
        # TODO: add config
      };

      trouble = {
        enable = true;
      };

      gitsigns = {
        enable = true;
        settings.current_line_blame = true;
      };

      which-key = {
        enable = false;
      # registrations = {
        # "<leader>fg" = "Find Git files with telescope";
        # "<leader>fw" = "Find text with telescope";
        # "<leader>ff" = "Find files with telescope";
      # };
      };

      markdown-preview = {
        enable = true;
        settings.theme = "dark";
      };

      telescope = {
        enable = true;
        extensions = {
          fzf-native = {
            enable = true;
          };
        };
      };

      todo-comments = {
        enable = true;
          # settings.colors = {
            # error = ["DiagnosticError" "ErrorMsg" "#DC2626"];
            # warning = ["DiagnosticWarn" "WarningMsg" "#FBBF24"];
            # info = ["DiagnosticInfo" "#2563EB"];
            # hint = ["DiagnosticHint" "#10B981"];
            # default = ["Identifier" "#7C3AED"];
            # test = ["Identifier" "#FF00FF"];
          # };
      };

      neo-tree = {
        enable = true;
        enableDiagnostics = true;
        enableGitStatus = true;
        enableModifiedMarkers = true;
        enableRefreshOnWrite = true;
        closeIfLastWindow = true;
        popupBorderStyle = "rounded"; # Type: null or one of “NC”, “double”, “none”, “rounded”, “shadow”, “single”, “solid” or raw lua code
        buffers = {
          bindToCwd = false;
          followCurrentFile = {
            enabled = true;
          };
        };
        window = {
          width = 40;
          height = 15;
          autoExpandWidth = false;
          mappings = {
            "<space>" = "none";
          };
        };
      };

      undotree = {
        enable = true;
        settings = {
          autoOpenDiff = true;
          focusOnToggle = true;
        };
      };

      hardtime = {
        enable = false;
        settings = {
        # disableMouse = true;
        # enabled = false;
        # disabledFiletypes = [ "Oil" ];
        # restrictionMode = "hint";
        # hint = true;
        # maxCount = 40;
        # maxTime = 1000;
        # restrictedKeys = {
        #   "h" = [ "n" "x" ];
        #   "j" = [ "n" "x" ];
        #   "k" = [ "n" "x" ];
        #   "l" = [ "n" "x" ];
        #   "-" = [ "n" "x" ];
        #   "+" = [ "n" "x" ];
        #   "gj" = [ "n" "x" ];
        #   "gk" = [ "n" "x" ];
        #   "<CR>" = [ "n" "x" ];
        #   "<C-M>" = [ "n" "x" ];
        #   "<C-N>" = [ "n" "x" ];
        #   "<C-P>" = [ "n" "x" ];
        };
      };

      lsp = {
        enable = true;
        servers = {
        };
      };

      fidget = {
        enable = true;
      };
    };

}
