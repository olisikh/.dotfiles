{ ... }:
{
  plugins = {
    lsp = {
      enable = true;
      inlayHints = false;
      servers = {
        lua_ls = {
          enable = true;
          settings = {
            Lua = {
              workspace.checkThirdParty = false;
              telemetry.enable = false;
              format.enable = false;
              hint.enable = true;
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
        pylsp.enable = true;
        # pylyzer.enable = true;
        terraformls.enable = true;
        marksman.enable = true;
        nil_ls.enable = true;
        nixd.enable = true;

        helm_ls = {
          enable = true;
          filetypes = [ "helm" ];
        };

        jsonls = {
          enable = true;
          filetypes = [ "json" "jsonc" ];
          settings = {
            json = {
              schemas = [
                {
                  fileMatch = [ "package.json" ];
                  url = "https://json.schemastore.org/package.json";
                }
                {
                  fileMatch = [ "tsconfig*.json" ];
                  url = "https://json.schemastore.org/tsconfig.json";
                }
                {
                  fileMatch = [ "jsconfig.json" ];
                  url = "https://json.schemastore.org/jsconfig.json";
                }
                {
                  fileMatch = [ ".prettierrc" ".prettierrc.json" "prettier.config.json" ];
                  url = "https://json.schemastore.org/prettierrc.json";
                }
                {
                  fileMatch = [ "lerna.json" ];
                  url = "https://json.schemastore.org/lerna.json";
                }
                {
                  fileMatch = [ "nodemon.json" "nodemon.jsonc" ];
                  url = "https://json.schemastore.org/nodemon.json";
                }
                {
                  fileMatch = [ "oh-my-opencode.json" "oh-my-opencode.jsonc" ];
                  url = "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/refs/heads/dev/assets/oh-my-opencode.schema.json";
                }
                {
                  fileMatch = [ "opencode.json" "opencode.jsonc" ];
                  url = "https://opencode.ai/config.json";
                }
              ];
            };
          };
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
  };

  extraConfigLua = ''
    -- NOTE: setup border for ui elements
    local border = "rounded"

    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border })
    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border })

    -- Configure kotlin-lsp
    vim.lsp.config('kotlin-lsp', {
      cmd = { 'kotlin-lsp', '--stdio' },
      settings = {
        kotlin_lsp = { }
      }
    })
  '';

  keymaps = [
    # nmap('<leader>cd', vim.diagnostic.open_float, { desc = 'diagnostic: show [c]ode [d]iagnostic' })
    {
      key = "grx";
      action = ":lua vim.diagnostic.open_float()<cr>";
      mode = "n";
      options = {
        desc = "lsp: [c]ode [d]iagnostic";
      };
    }

    # nmap('<leader>cf', function() vim.lsp.buf.format() end, { desc = 'lsp: [c]ode [f]ormat' })
    # map('v', '<leader>cf', function()
    #   local vstart = vim.fn.getpos("'<")
    #   local vend = vim.fn.getpos("'>")
    #
    #   vim.lsp.buf.format({ range = { vstart, vend } })
    # end, { desc = 'lsp: [c]ode [f]ormat' })
    {
      key = "grf";
      action = ":lua require('conform').format()<cr>";
      mode = ["n" "v"];
      options = {
        desc = "lsp: [c]ode [f]ormat";
      };
    }

    # nmap('<leader>ci', function()
    #   vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    # end, { desc = 'lsp: toggle inlay hints (buffer)' })
    {
      key = "grh";
      action = ":lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>";
      mode = "n";
      options = {
        desc = "lsp: [c]ode [i]nlay hints";
      };
    }
    # map("n", "<leader>cl", vim.lsp.codelens.run)
    {
      key = "grl";
      action = ":lua vim.lsp.codelens.run()<cr>";
      mode = "n";
      options = {
        desc = "lsp: [g]oto [l]ens";
      };
    }
    # nmap('gd', telescope_builtin.lsp_definitions, { desc = 'lsp: [g]oto [d]efinition' })
    {
      key = "grd";
      action = ":lua require('telescope.builtin').lsp_definitions()<cr>";
      mode = "n";
      options = {
        desc = "lsp: [g]oto [d]efinition";
      };
    }
  ];
}
