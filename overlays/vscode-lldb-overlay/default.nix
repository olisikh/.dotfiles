{ channels, inputs, ... }:

final: prev: {
  vscode-extensions = prev.vscode-extensions // {
    vadimcn = prev.vscode-extensions.vadimcn // {
      vscode-lldb = inputs.vscodelldb-fix.legacyPackages."${prev.system}".vscode-extensions.vadimcn.vscode-lldb;
    };
  };
}

