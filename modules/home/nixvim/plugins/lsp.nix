{...}:{
  lsp = {
    enable = true;
    inlayHints = false; # NOTE: disable inlay-hints by default
    capabilities = # lua
      ''require('blink.cmp').get_lsp_capabilities(capabilities)'';
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
      # jdtls.enable = true;
      # kotlin_language_server.enable = true;
      # kotlin-lsp = true; # NOTE: unavailable, not in nixpkgs, enabled manually in extra lua config
      pylsp.enable = true;
      # pylyzer.enable = true;
      terraformls.enable = true;
      marksman.enable = true;
      nil_ls.enable = true;

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
}
