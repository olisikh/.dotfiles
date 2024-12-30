{ ... }: {
  plugins = {
    web-devicons.enable = true;

    lualine = {
      enable = true;
      settings = {
        options = {
          theme = "catppuccin";
        };
        sections = {
          lualine_c = [
            "filename"
          ];
          lualine_x = [
            "harpoon2" # NOTE: plugin is not available as vimPlugin
            "copilot"
            "encoding"
            "filetype"
          ];
        };
      };
    };

    oil.enable = true;
    nvim-tree = {
      enable = true; # NOTE: newer alternative: neo-tree
      renderer = {
        icons = {
          gitPlacement = "after";
        };
      };
      view = {
        width = 50;
      };
      git = {
        enable = true;
        ignore = true;
      };
      filters = {
        dotfiles = true;
      };
      onAttach = {
        __raw =
          #lua
          ''
            function(bufnr)
              require("nvim-tree.api")
                .config
                .mappings
                .default_on_attach(bufnr)
            end
          '';
      };
    };

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

    # TODO: add config
    dap = {
      enable = true;
      signs = {
        dapBreakpoint = {
          text = "●";
          texthl = "DapBreakpoint";
        };
        dapBreakpointCondition = {
          text = "●";
          texthl = "DapBreakpointCondition";
        };
        dapBreakpointRejected = {
          text = "●";
          texthl = "DapBreakpointRejected";
        };
        dapStopped = {
          text = "→";
          texthl = "DapStopped";
        };
        dapLogPoint = {
          text = "◆";
          texthl = "DapLogPoint";
        };
      };
      extensions = {
        dap-go.enable = true;
        dap-python.enable = true;
        dap-ui.enable = true;
        dap-virtual-text = {
          enable = true;
          enabledCommands = true;
          highlightChangedVariables = true;
          highlightNewAsChanged = true;
          showStopReason = true;
          commented = true;
          onlyFirstDefinition = true;
          allReferences = true;
          displayCallback =
            # lua
            '' 
            function(variable, _buf, _stackframe, _node)
              return ' ' .. variable.name .. ' = ' .. variable.value .. ' '
            end
            '';
          # -- experimental features:
          virtTextPos = "eol"; # -- position of virtual text, see `:h nvim_buf_set_extmark()`
          allFrames = false; # -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
          virtLines = false; # -- show virtual lines instead of virtual text (will flicker!)
          virtTextWinCol = null; # -- position the virtual text at a fixed window column (starting from the first text column) ,
        };
      };
      configurations = {
        # TODO: should I define configurations here or elsewhere?
      };
    };


    # TODO: configure, install adapters
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

    trouble.enable = true;
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
        ui-select = {
          enable = true;
        };
      };
    };

    todo-comments.enable = true;

    copilot-lua.enable = true;

    # TODO: install ollama
    # ollama = {
    #   enable = true;
    # };

    undotree = {
      enable = true;
      settings = {
        autoOpenDiff = true;
        focusOnToggle = true;
      };
    };

    hardtime.enable = true;

    blink-cmp = {
      enable = true;
      luaConfig = {
        pre =
          # lua
          ''
            require('blink.cmp').setup({
              -- 'default' for mappings similar to built-in completion
              -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
              -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
              -- See the full "keymap" documentation for information on defining your own keymap.
              keymap = { preset = 'default' },

              -- Default list of enabled providers defined so that you can extend it
              -- elsewhere in your config, without redefining it, due to `opts_extend`
              sources = {
                default = { 'lazydev', 'lsp', 'path', 'snippets' },
                providers = {
                  lazydev = {
                    name = 'LazyDev',
                    module = 'lazydev.integrations.blink',
                    score_offset = 100, -- show at a higher priority than lsp
                  },
                },
              },

              appearance = {
                -- Sets the fallback highlight groups to nvim-cmp's highlight groups
                -- Useful for when your theme doesn't support blink.cmp
                -- Will be removed in a future release
                use_nvim_cmp_as_default = false,
                -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- Adjusts spacing to ensure icons are aligned
                nerd_font_variant = 'mono',
              },

              completion = {
                -- 'prefix' will fuzzy match on the text before the cursor
                -- 'full' will fuzzy match on the text before *and* after the cursor
                -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
                keyword = { range = 'full' },

                -- Disable auto brackets
                -- NOTE: some LSPs may add auto brackets themselves anyway
                accept = { auto_brackets = { enabled = false } },

                -- Insert completion item on selection, don't select by default
                list = { selection = 'auto_insert' },

                menu = {
                  -- Don't automatically show the completion menu
                  auto_show = false,

                  -- nvim-cmp style menu
                  draw = {
                    columns = {
                      { 'label', 'label_description', gap = 1 },
                      { 'kind_icon', 'kind', gap = 1 },
                    },
                  },
                },

                -- Show documentation when selecting a completion item
                documentation = { auto_show = true, auto_show_delay_ms = 500 },

                -- Display a preview of the selected item on the current line
                ghost_text = { enabled = true },
              },

              -- Experimental signature help support
              signature = { enabled = true },
            })'';
      };
    };

    lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        lua_ls = {
          enable = true;
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false;
              };
              telemetry = {
                enable = false;
              };
              format = {
                enable = false;
              };
              hint = {
                enable = true;
              };
            };
          };
        };
        dockerls.enable = true;
        bashls.enable = true;
        html.enable = true;
        cssls.enable = true;
        tailwindcss.enable = true;
        ts_ls = {
          enable = true;
          settings = {
            javascript = {
              inlayHints = {
                includeInlayEnumMemberValueHints = true;
                includeInlayFunctionLikeReturnTypeHints = true;
                includeInlayFunctionParameterTypeHints = true;
                includeInlayParameterNameHints = "literals"; # -- 'none' | 'literals' | 'all';
                includeInlayParameterNameHintsWhenArgumentMatchesName = false;
                includeInlayPropertyDeclarationTypeHints = true;
                includeInlayVariableTypeHints = false;
                includeInlayVariableTypeHintsWhenTypeMatchesName = false;
              };
            };
            typescript = {
              inlayHints = {
                includeInlayEnumMemberValueHints = true;
                includeInlayFunctionLikeReturnTypeHints = true;
                includeInlayFunctionParameterTypeHints = true;
                includeInlayParameterNameHints = "literals"; # -- 'none' | 'literals' | 'all';
                includeInlayParameterNameHintsWhenArgumentMatchesName = false;
                includeInlayPropertyDeclarationTypeHints = true;
                includeInlayVariableTypeHints = false;
                includeInlayVariableTypeHintsWhenTypeMatchesName = false;
              };
            };
          };
        };
        gopls = {
          enable = true;
          settings = {
            gopls = {
              # -- setup inlay hints
              hints = {
                assignVariableTypes = true;
                compositeLiteralFields = true;
                compositeLiteralTypes = true;
                constantValues = true;
                functionTypeParameters = true;
                parameterNames = true;
                rangeVariableTypes = true;
              };
            };
          };
        };
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
          settings = {
            yaml = {
              keyOrdering = false; # -- disable alphabetic ordering of keys
              schemas = {
                kubernetes = "templates/**";
                "http://json.schemastore.org/github-workflow" = ".github/workflows/*";
                "http://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
                "http://json.schemastore.org/prettierrc" = ".prettierrc.{yml,yaml}";
                "http://json.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
                "http://json.schemastore.org/chart" = "Chart.{yml,yaml}";
                "https://json.schemastore.org/dependabot-2.0.json" = ".github/dependabot.{yml,yaml}";
                "https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json" = "*gitlab-ci*.{yml,yaml}";
                "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json" = "*api*.{yml,yaml}";
                "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = "*docker-compose*.{yml,yaml}";
                "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" = "*flow*.{yml,yaml}";
              };
            };
          };
        };
      };
    };

    none-ls = {
      enable = true;
    };

    helm.enable = true;

    rustaceanvim = {
      enable = true;
      # TODO: configure
    };
    crates.enable = true;

    fidget.enable = true;

    nvim-surround.enable = true;

    # NOTE: Not sure if I need this plugin
    # guess-indent.enable = true;

    # TODO: missing plugins
    # nvim-fundo
    # alisiikh/nvim-scala-zio-quickfix
  };
}
