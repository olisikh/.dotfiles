{ pkgs, ... }:
let
  jsDapConfig = [
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
      processId = { __raw = "require'dap.utils'.pick_process"; };
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
      runtimeArgs = [
        "./node_modules/mocha/bin/mocha.js"
      ];
      rootPath = ''''${workspaceFolder}'';
      cwd = ''''${workspaceFolder}'';
      console = "integratedTerminal";
      internalConsoleOptions = "neverOpen";
    }
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
    extensions = {
      dap-go = {
        enable = true;
        delve.path = "${pkgs.delve}/bin/dlv";
      };
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
      java = [
        {
          type = "java";
          request = "launch";
          name = "Debug (Attach) - Remote";
          hostName = "127.0.0.1";
          port = 5005;
        }
      ];

      javascript = jsDapConfig;
      typescript = jsDapConfig;
    };
  };

  dap-lldb = {
    enable = true;
    settings = {
      codelldb_path = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
    };
  };
}
