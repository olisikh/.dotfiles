local utils = require('user.utils')

local lsp_group = require('user.lsp_utils').lsp_group
local capabilities = require('user.lsp_utils').capabilities

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })

local servers = {
  dockerls = {},
  helm_ls = {
    init_opts = {
      no_fmt = true,
    },
    -- NOTE: Configuration: https://github.com/mrjosh/helm-ls?tab=readme-ov-file#nvim-lspconfig-setup
    settings = {
      settings = {
        ['helm-ls'] = {
          yamlls = {
            path = 'yaml-language-server',
          },
        },
      },
    },
  },
  terraformls = {},
  bashls = {},
  yamlls = {
    init_opts = {
      no_fmt = true,
    },
    -- NOTE: Configuration https://github.com/redhat-developer/yaml-language-server
    settings = {
      yaml = {
        keyOrdering = false, -- disable alphabetic ordering of keys
        schemas = {
          kubernetes = 'templates/**',
          ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*',
          ['http://json.schemastore.org/github-action'] = '.github/action.{yml,yaml}',
          ['http://json.schemastore.org/prettierrc'] = '.prettierrc.{yml,yaml}',
          ['http://json.schemastore.org/kustomization'] = 'kustomization.{yml,yaml}',
          ['http://json.schemastore.org/chart'] = 'Chart.{yml,yaml}',
          ['https://json.schemastore.org/dependabot-2.0.json'] = '.github/dependabot.{yml,yaml}',
          ['https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json'] = '*gitlab-ci*.{yml,yaml}',
          ['https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json'] = '*api*.{yml,yaml}',
          ['https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json'] = '*docker-compose*.{yml,yaml}',
          ['https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json'] = '*flow*.{yml,yaml}',
        },
      },
    },
  },
  pyright = {
    init_opts = {
      no_fmt = true,
    },
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = 'openFilesOnly',
        },
      },
    },
  },
  gopls = {
    init_opts = {
      no_fmt = true,
    },
    settings = {
      gopls = {
        -- setup inlay hints
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  },
  ts_ls = {
    init_opts = {
      no_fmt = true,
    },
    settings = {
      javascript = {
        inlayHints = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = 'literals', -- 'none' | 'literals' | 'all';
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = false,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        },
      },
      typescript = {
        inlayHints = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = 'literals', -- 'none' | 'literals' | 'all';
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = false,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        },
      },
    },
  },
  jsonls = {},
  lua_ls = {
    init_opts = {
      no_fmt = true,
    },
    settings = {
      Lua = {
        workspace = {
          checkThirdParty = false,
        },
        telemetry = {
          enable = false,
        },
        format = {
          enable = false,
        },
        hint = {
          enable = true,
        },
      },
    },
  },
  nil_ls = {
    init_opts = {
      no_fmt = true,
    },
    settings = {
      ['nil'] = {
        autostart = true,
        testSetting = 42,
      },
    },
  },
}

-- LSP servers that are configured by plugins
local managed_servers = { 'rust_analyzer', 'jdtls' }

local mason_lspconfig = require('mason-lspconfig')
mason_lspconfig.setup({
  ensure_installed = utils.list_merge(managed_servers, vim.tbl_keys(servers)),
  automatic_installation = false,
})

mason_lspconfig.setup_handlers({
  function(server_name)
    if not vim.list_contains(managed_servers, server_name) then
      local server_config = servers[server_name]
      local settings = nil
      local init_opts = nil

      if not server_config then
        vim.print('[warn] Config for LSP server: ' .. server_name .. ' is missing!')
      end

      if not server_config or not server_config.settings then
        settings = {}
      else
        settings = server_config.settings
      end

      if not server_config or not server_config.init_opts then
        init_opts = {}
      else
        init_opts = server_config.init_opts
      end

      require('lspconfig')[server_name].setup({
        capabilities = capabilities,
        settings = settings,
        on_attach = function(client, bufnr)
          require('user.lsp_utils').on_attach(client, bufnr, init_opts)
        end,
      })
    end
  end,
})

require('user.lsp.lua').setup(lsp_group)
require('user.lsp.js').setup(lsp_group)
require('user.lsp.go').setup(lsp_group)
require('user.lsp.scala').setup(lsp_group, capabilities)
require('user.lsp.rust').setup(lsp_group, capabilities)
