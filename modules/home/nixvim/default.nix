{ lib, config, namespace, pkgs, inputs, ... }:
let
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.nixvim;

  nixvimLib = inputs.nixvim.lib.nixvim;

  kotlin-dap-adapter = pkgs.fetchzip {
    name = "kotlin-dap-adapter-0.4.4";
    url = "https://github.com/fwcd/kotlin-debug-adapter/releases/download/0.4.4/adapter.zip";
    hash = "sha256-gNbGomFcWqOLTa83/RWS4xpRGr+jmkovns9Sy7HX9bg=";
  };
in
{
  options.${namespace}.nixvim = {
    enable = mkBoolOpt false "Enable nixvim program";

    plugins = {
      avante = {
        enable = mkBoolOpt true "Enable Avante plugin";
        provider = mkOption {
          type = types.enum [ "claude" "openai" "ollama" "copilot" ];
          default = "claude";
          description = "AI provider to use with Avante";
        };
      };

      copilot = {
        enable = mkBoolOpt true "Enable GitHub Copilot";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      defaultEditor = true;

      # NOTE: due to overlay, nixvim would install and use nightly
      # TODO: commented out because neotest-scala and ziofix plugins don't work properly on nightly
      # package = pkgs.neovim;

      colorschemes = import ./colorscheme.nix;

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
          command = "silent! lua vim.lsp.codelens.refresh()";
        }
        {
          event = [ "CursorHold" "CursorHoldI" ];
          pattern = "*";
          group = "user_lsp";
          command = "silent! lua vim.lsp.buf.document_highlight()";
        }
        {
          event = "CursorMoved";
          pattern = "*";
          group = "user_lsp";
          command = "silent! lua vim.lsp.buf.clear_references()";
        }
      ];

      imports = [
        ./options.nix
        ./keymaps.nix
      ];

      plugins = import ./plugins.nix { inherit pkgs config namespace lib nixvimLib; };

      extraPackages = with pkgs; [
        gcc
        jdt-language-server
        vscode-extensions.vscjava.vscode-java-debug
        vscode-extensions.vscjava.vscode-java-test
        vscode-extensions.ms-python.debugpy
        vscode-extensions.davidanson.vscode-markdownlint
        vscode-extensions.vadimcn.vscode-lldb
        vscode-js-debug
        gofumpt
        gotools
        black
        isort
        delve
        prettierd
        yamllint
        hadolint
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
      extraPlugins = import ./extra/plugins.nix { inherit pkgs nixvimLib; };
      extraFiles = import ./extra/files.nix { inherit pkgs; };
      extraConfigLua = import ./extra/config.nix { inherit kotlin-dap-adapter; };
      extraConfigLuaPost = ''
        -- This line is called a `modeline`. See `:help modeline`
        -- vim: ts=2 sts=2 sw=2 et
      '';
    };
  };
}
