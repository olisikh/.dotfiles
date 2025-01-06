{ pkgs, lib, config, ... }:
let
  nixvimLib = config.lib.nixvim;
in
{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # TODO: use nightly?
    # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

    colorschemes = import ./colorscheme;

    autoGroups = {
      user_generic.clear = true;
      user_lsp.clear = true;
    };

    autoCmd = [
      {
        event = "TextYankPost";
        pattern = "*";
        group = "user_generic";
        command = "silent! lua vim.highlight.on_yank()";
      }
      {
        event = [ "BufRead" "BufNewFile" ];
        pattern = [ "*.tf" " *.tfvars" " *.hcl" ];
        group = "user_lsp";
        command = "set filetype=terraform";
      }
      {
        event = "FileType";
        pattern = "helm";
        group = "user_lsp";
        command = "LspRestart";
      }
      {
        event = [ "BufEnter" "CursorHold" "InsertLeave" ];
        pattern = "*";
        group = "user_lsp";
        callback = nixvimLib.mkRaw
          # lua
          ''
            function()
              pcall(vim.lsp.codelens.refresh)
            end
          '';
      }
    ];

    imports = [
      ./options
      ./keymaps
    ];

    plugins = import ./plugins { inherit pkgs nixvimLib; };

    extraPackages = with pkgs; [
      gcc
      jdt-language-server
      vscode-extensions.vscjava.vscode-java-debug
      vscode-extensions.vscjava.vscode-java-test
      vscode-extensions.ms-python.debugpy
      vscode-extensions.davidanson.vscode-markdownlint
      # vscode-extensions.vadimcn.vscode-lldb # TODO: code-lldb fails to build
      vscode-js-debug
      gofumpt
      gotools
      black
      isort
      delve
      prettierd
      yamllint
      hadolint
      vale
      tflint
      pylint
      checkstyle
      nodePackages.jsonlint
      shfmt
      rustfmt
      rust-analyzer
      libiconv
      stylua
      jq
      ktlint
      eslint_d
      google-java-format
      lombok
      nixpkgs-fmt
    ];

    # TODO: all these plugins need to be installed
    # maybe some of them I could contribute to nixvim
    extraPlugins = import ./extra/plugins { inherit pkgs lib; };
    extraFiles = import ./extra/files { inherit pkgs; };
    extraConfigLua = import ./extra/config { inherit pkgs; };
    extraConfigLuaPost = ''
      -- This line is called a `modeline`. See `:help modeline`
      -- vim: ts=2 sts=2 sw=2 et
    '';
  };
}
