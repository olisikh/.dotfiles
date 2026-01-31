{ pkgs, lib, ... }:
let
  kotlin-dap-adapter = pkgs.fetchzip {
    name = "kotlin-dap-adapter-0.4.4";
    url = "https://github.com/fwcd/kotlin-debug-adapter/releases/download/0.4.4/adapter.zip";
    hash = "sha256-gNbGomFcWqOLTa83/RWS4xpRGr+jmkovns9Sy7HX9bg=";
  };

  jsConfigs = [
    {
      type = "pwa-node";
      request = "launch";
      name = "Launch file";
      file = ''''${file}'';
      cwd = ''''${workspaceFolder}'';
    }
    {
      type = "pwa-node";
      request = "attach";
      name = "Attach";
      processId = lib.nixvim.mkRaw "require('dap.utils').pick_process";
      cwd = ''''${workspaceFolder}'';
    }
    {
      type = "pwa-node";
      request = "launch";
      name = "Debug Jest Tests";
      # -- trace = true, -- include debugger info
      runtimeExecutable = "node";
      runtimeArgs = [
        "./node_modules/jest/bin/jest.js"
        "--runInBand"
      ];
      rootPath = ''''${workspaceFolder}'';
      cwd = ''''${workspaceFolder}'';
      console = "integratedTerminal";
      internalConsoleOptions = "neverOpen";
    }
    {
      type = "pwa-node";
      request = "launch";
      name = "Debug Mocha Tests";
      # -- trace = true, -- include debugger info
      runtimeExecutable = "node";
      runtimeArgs = [ "./node_modules/mocha/bin/mocha.js" ];
      rootPath = ''''${workspaceFolder}'';
      cwd = ''''${workspaceFolder}'';
      console = "integratedTerminal";
      internalConsoleOptions = "neverOpen";
    }
    # TODO: not working, can't debug vitest tests
    # {
    #   type = "pwa-node";
    #   request = "launch";
    #   name = "Debug Vitest Tests";
    #   # -- trace = true, -- include debugger info
    #   runtimeExecutable = "node";
    #   runtimeArgs = [ 
    #     "./node_modules/node_modules/vitest/vitest.mjs" 
    #     "--threads"
    #     "false"
    #   ];
    #   rootPath = '''${workspaceFolder}'';
    #   cwd = '''${workspaceFolder}'';
    #   console = "integratedTerminal";
    #   internalConsoleOptions = "neverOpen";
    #   autoAttachChildProcesses = false;
    #   sourceMaps = true;
    #   smartStep = true;
    # }
  ];
in
{
  plugins = {
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
      adapters = {
        servers = {
          "pwa-node" = {
            host = "localhost";
            port = 8123;
            executable = {
              command = "${pkgs.vscode-js-debug}/bin/js-debug";
            };
          };
        };
      };
      configurations = {
        java = [
          {
            type = "java";
            request = "launch";
            name = "Debug (Attach) - Remote";
            hostName = "127.0.0.1";
            port = 5005;
          }
        ];

        javascript = jsConfigs;
        typescript = jsConfigs;
      };
    };

    "dap-go" = {
      enable = true;
      settings = {
        delve.path = "${pkgs.delve}/bin/dlv";
      };
    };

    "dap-python".enable = true;
    "dap-ui".enable = true;
    "dap-virtual-text".enable = true;
  };

  extraPlugins = [ pkgs.vimPlugins.nvim-dap-kotlin ];

  extraConfigLua = ''
    vim.diagnostic.config { 
      float = { border = border },
      signs = { 
        text = {
          [vim.diagnostic.severity.ERROR] = ' ',
          [vim.diagnostic.severity.WARN] = ' ',
          [vim.diagnostic.severity.INFO] = ' ',
          [vim.diagnostic.severity.HINT] = ' ',
        }
      }
    }

    require('lspconfig.ui.windows').default_options = { border = border }

    -- NOTE: open and close DAP UI when debugging on/off
    require('dap').listeners.after.event_initialized['dapui_config'] = require('dapui').open
    require('dap').listeners.before.event_terminated['dapui_config'] = require('dapui').close
    require('dap').listeners.before.event_exited['dapui_config'] = require('dapui').close

    -- TODO: configure nvim-dap-kotlin
    -- polyfil a function that is used by plugin
    require('dap-kotlin').setup({
      dap_command = "${kotlin-dap-adapter}/bin/kotlin-debug-adapter"
    })

    -- NOTE: setup kotlin-lsp from Jetbrains
    vim.lsp.config('kotlin-lsp', {
      cmd = { 'kotlin-lsp', '--stdio' },
      settings = {
        kotlin_lsp = { }
      }
    })
  '';

  keymaps = [
    # NOTE: DAP
    #
    # nmap('<leader>db', dap.toggle_breakpoint, { desc = 'dap: set breakpoint' })
    {
      key = "<leader>db";
      action = ":lua require('dap').toggle_breakpoint()<cr>";
      mode = "n";
      options = {
        desc = "dap: set breakpoint";
      };
    }
    # nmap('<leader>dB', function()
    #   dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
    # end, { desc = 'dap: cond breakpoint' })
    {
      key = "<leader>dB";
      action = ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition:'))<cr>";
      mode = "n";
      options = {
        desc = "dap: set breakpoint";
      };
    }
    # nmap('<leader>dc', dap.continue, { desc = 'dap: [c]ontinue' })
    {
      key = "<leader>dc";
      action = ":lua require('dap').continue()<cr>";
      mode = "n";
      options = {
        desc = "dap: [c]ontinue";
      };
    }
    # nmap('<leader>di', dap.step_into, { desc = 'dap: step [i]nto' })
    {
      key = "<leader>dsi";
      action = ":lua require('dap').step_into()<cr>";
      mode = "n";
      options = {
        desc = "dap: [s]tep [i]nto";
      };
    }
    # nmap('<leader>do', dap.step_out, { desc = 'dap: step [o]ut' })
    {
      key = "<leader>dso";
      action = ":lua require('dap').step_out()<cr>";
      mode = "n";
      options = {
        desc = "dap: [s]tep [o]ut";
      };
    }
    # nmap('<leader>dv', dap.step_over, { desc = 'dap: step o[v]er' })
    {
      key = "<leader>dso";
      action = ":lua require('dap').step_over()<cr>";
      mode = "n";
      options = {
        desc = "dap: [s]tep o[v]er";
      };
    }
    # -- nmap('<leader>dr', dap.repl.toggle, { desc = 'dap: repl toggle' })
    {
      key = "<leader>dr";
      action = "lua: require('dap').repl.toggle()<cr>";
      mode = "n";
      options = {
        desc = "dap: [r]epl toggle";
      };
    }
    # -- nmap('<leader>dh', dap_widgets.hover, { desc = 'dap: hover' })
    {
      key = "<leader>dh";
      action = ":lua require('dap.ui.widgets').hover()<cr>";
      mode = "n";
      options = {
        desc = "dap: [h]over";
      };
    }
    #
    # nmap('<leader>dd', dap_ui.toggle, { desc = 'dap-ui: toggle ui' })
    {
      key = "<leader>dd";
      action = ":lua require('dapui').toggle()<cr>";
      mode = "n";
      options = {
        desc = "dap: toggle ui";
      };
    }
    # nmap('<leader>dq', dap.terminate, { desc = 'dap: terminate' })
    {
      key = "<leader>dq";
      action = ":lua require('dap').terminate()<cr>";
      mode = "n";
      options = {
        desc = "dap: terminate";
      };
    }
  ];
}
