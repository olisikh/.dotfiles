{ ... }: {
  plugins = {
    web-devicons.enable = true;

    lualine.enable = true;
    oil.enable = true;
    nvim-tree.enable = true;
    smart-splits.enable = true;
    treesitter.enable = true;
    treesitter-refactor.enable = true;
    treesitter-textobjects.enable = true;
    treesitter-context.enable = true;

    nvim-autopairs.enable = true;
    lazygit.enable = true;


    harpoon.enable = true;
    # TODO: add the following plugin for nice icons in lualine
    # harpoon-lualine = {
    #   enable = true;
    # };

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
      enable = true;
      settings = {
        spelling = {
          enabled = false;
        };
        win = {
          border = "single";
        };
      };
      # TODO: refactor which-key registrations
      # registrations = {
      #   "<leader>c" = "Code";
      #   "<leader>s" = "Search";
      #   "<leader>t" = "Test"; 
      #   "<leader>x" = "Trouble"; 
      # };
    };

    markdown-preview = {
      enable = true;
      settings.theme = "dark";
    };
    render-markdown.enable = true;

    telescope = {
      enable = true;
      extensions = {
        fzf-native = {
          enable = true;
        };
        # dap = {
        #   enable = true;
        # };
        ui-select = {
          enable = true;
        };
      };
    };


    todo-comments.enable = true;

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
    # fundo.enable = true;

    hardtime = {
      enable = true;
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


    # NOTE: seems like plugin is old
    blink-cmp = {
      enable = true;

      settings = {
        keymap = {
          # -- 'default' for mappings similar to built-in completion
          # -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
          # -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
          # -- See the full "keymap" documentation for information on defining your own keymap.
          preset = "default";
        };

        appearance = {
          # -- Sets the fallback highlight groups to nvim-cmp's highlight groups
          # -- Useful for when your theme doesn't support blink.cmp
          # -- Will be removed in a future release
          use_nvim_cmp_as_default = false;

          # -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
          # -- Adjusts spacing to ensure icons are aligned
          nerd_font_variant = "mono";
        };

        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
        };

        completion = {
          # -- 'prefix' will fuzzy match on the text before the cursor
          # -- 'full' will fuzzy match on the text before *and* after the cursor
          # -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
          keyword = {
            range = "full";
          };

          # -- Disable auto brackets
          # -- NOTE: some LSPs may add auto brackets themselves anyway
          accept = {
            auto_brackets = {
              enabled = false;
            };
          };

          # -- Insert completion item on selection, don't select by default
          list = { selection = "auto_insert"; };

          menu = {
            # -- Don't automatically show the completion menu
            auto_show = false;

            # -- nvim-cmp style menu
            # TODO: figure how to fix this
            # draw = {
            #   columns = [
            #     [ "label" "label_description" { gap = 1; } ]
            #     [ "kind_icon" "kind" ]
            #   ];
            # };
          };

          # -- Show documentation when selecting a completion item
          documentation = {
            auto_show = true;
            auto_show_delay_ms = 200;
          };

          # -- Display a preview of the selected item on the current line
          ghost_text = { enabled = true; };
        };

        signature = {
          enabled = true;
        };
      };
    };

    lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        lua_ls.enable = true;
        dockerls.enable = true;
        bashls.enable = true;
        html.enable = true;
        cssls.enable = true;
        tailwindcss.enable = true;
        ts_ls.enable = true;
        gopls.enable = true;
        jdtls.enable = true;
        pylsp.enable = true;
        pylyzer.enable = true;
        terraformls.enable = true;

        nixd = {
          enable = true;

          settings = {
            formatting.command = [ "nixpkgs-fmt" ];
            nixpkgs.expr = "import <nixpkgs> {}";
          };
        };

        helm_ls = {
          enable = true;
          filetypes = [ "helm" ];
        };


        yamlls = {
          enable = true;
          filetypes = [ "yaml" ];
        };
      };
    };

    none-ls = {
      enable = true;
    };

    fidget = {
      enable = true;
    };

    nvim-surround.enable = true;

    # NOTE: Not sure if I need this plugin
    guess-indent.enable = true;

    # TODO: missing plugins
    # nvim-helm
    # nvim-metals
    # nvim-fundo
  };
}
