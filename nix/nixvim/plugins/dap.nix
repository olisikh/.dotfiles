{ pkgs, nixvimLib, ... }:
let
  jsConfigs = [
    {
      type = "pwa-node";
      request = "launch";
      name = "Launch file";
      program = ''''${file}'';
      cwd = ''''${workspaceFolder}'';
    }
    {
      type = "pwa-node";
      request = "attach";
      name = "Attach";
      processId = nixvimLib.mkRaw "require('dap.utils').pick_process";
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
    #   rootPath = ''''${workspaceFolder}'';
    #   cwd = ''''${workspaceFolder}'';
    #   console = "integratedTerminal";
    #   internalConsoleOptions = "neverOpen";
    #   autoAttachChildProcesses = false;
    #   sourceMaps = true;
    #   smartStep = true;
    # }
  ];
in
{
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


  dap-go = {
    enable = true;
    settings = {
      delve.path = "${pkgs.delve}/bin/dlv";
    };
  };
  dap-python.enable = true;
  dap-ui.enable = true;
  dap-virtual-text.enable = true;
}
