{ pkgs, ... }:
let
  vscode_lldb = pkgs.vscode-extensions.vadimcn.vscode-lldb;
  codelldb_path = "${vscode_lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
  liblldb_path = "${vscode_lldb}/share/vscode/extensions/vadimcn.vscode-lldb/lldb/lib/liblldb.dylib";
in
{
  rustaceanvim = {
    enable = true;

    settings = {
      dap = {
        autoload_configurations = true;
        adapter =
          # lua
          ''
            function()
              return require('rustaceanvim.config').get_codelldb_adapter("${codelldb_path}", "${liblldb_path}")
            end
          '';
      };
      server = {
        default_settings = {
          rust-analyzer = {
            files = { excludeDirs = [ ".direnv" ]; };
          };
        };
      };
    };
  };
}
