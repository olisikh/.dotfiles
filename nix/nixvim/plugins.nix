{ pkgs, ... }: {
  plugins = {
    web-devicons.enable = true;

    lualine.enable = true;
    oil.enable = true;
    nvim-tree.enable = true; # NOTE: newer alternative: neo-tree
    smart-splits.enable = true;
    treesitter = {
      enable = true;
      settings = {
        auto_install = true;
        highlight = { enable = true; };
        indent = { enable = true; disable = [ "python" ]; };
        incremental_selection = {
          enable = true;
          keymaps = {
            init_selection = "<C-space>";
            node_incremental = "<C-space>";
            node_decremental = "<C-b>";
            # -- scope_incremental = "<C-b>";
          };
        };
      };
    };
    treesitter-refactor.enable = true;
    treesitter-textobjects = {
      enable = true;
      select = {
        enable = true;
        lookahead = true; # -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          # -- You can use the capture groups defined in textobjects.scm
          aa = "@parameter.outer";
          ia = "@parameter.inner";
          af = "@function.outer";
          "if" = "@function.inner";
          ac = "@class.outer";
          ic = "@class.inner";
        };
      };
      move = {
        enable = true;
        setJumps = true;
        gotoNextStart = {
          "]m" = "@function.outer";
          "]]" = "@class.outer";
        };
        gotoNextEnd = {
          "]M" = "@function.outer";
          "][" = "@class.outer";
        };
        gotoPreviousStart = {
          "[m" = "@function.outer";
          "[[" = "@class.outer";
        };
        gotoPreviousEnd = {
          "[M" = "@function.outer";
          "[]" = "@class.outer";
        };
      };
      swap = {
        enable = true;
        swapPrevious = {
          "[p" = "@parameter.inner";
        };
        swapNext = {
          "]p" = "@parameter.inner";
        };
      };
    };
    treesitter-context = {
      enable = true;

      settings = {
        max_lines = 5; # -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0; # -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true;
        multiline_threshold = 20; # -- Maximum number of lines to show for a single context
        trim_scope = "inner"; # -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = "cursor"; # -- Line used to calculate context. Choices: 'cursor', 'topline'
        # -- Separator between context and content. Should be a single character string, like '-'.
        # -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        # separator = nil,
        zindex = 20; # -- The Z-index of the context window
        # on_attach = nil, # -- (fun(buf: integer): boolean) return false to disable attaching
      };
    };

    nvim-autopairs.enable = true;
    lazygit.enable = true;

    # harpoon.enable = true;
    # TODO: add the following plugin for nice icons in lualine
    # harpoon-lualine = {
    #   enable = true;
    # };
    # or use harpoon2?

    dap = {
      enable = true;
      # TODO: add config
    };

    neotest = {
      enable = true;
      settings = {
        diagnostic = {
          enabled = true;
          severity = 1; # ERROR
        };
        status = {
          enabled = true;
          signs = false;
          virtual_text = true;
        };
      };
    };

    trouble = {
      enable = true;
    };

    sleuth.enable = true;
    colorizer.enable = true;

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

    copilot-lua.enable = true;

    undotree = {
      enable = true;
      settings = {
        autoOpenDiff = true;
        focusOnToggle = true;
      };
    };

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
            "lazydev"
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
            draw = {
              # columns = [
              #   [ "label" "label_description" { gap = 1; } ]
              #   [ "kind_icon" "kind" ]
              # ];
            };
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
        kotlin_language_server.enable = true;
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

    helm.enable = true;

    rustaceanvim = {
      enable = true;
    };
    crates.enable = true;

    # nvim-jdtls = {
      # enable = true;
      # configuration = "${pkgs.jdt-language-server}/config_mac";
      # data = "~/.cache/jdtls/workspace";
    # };

    fidget = {
      enable = true;
    };

    nvim-surround.enable = true;

    # NOTE: Not sure if I need this plugin
    # guess-indent.enable = true;

    # TODO: missing plugins
    # nvim-fundo
    # alisiikh/nvim-scala-zio-quickfix
  };
}
