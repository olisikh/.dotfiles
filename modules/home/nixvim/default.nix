{ lib, config, namespace, pkgs, inputs, system, ... }:
let
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.nixvim;

  nixvimLib = inputs.nixvim.lib.nixvim;
  neovimNightlyPkg = inputs.nightly-neovim-overlay.packages.${system}.default;

  kotlin-dap-adapter = pkgs.fetchzip {
    name = "kotlin-dap-adapter-0.4.4";
    url = "https://github.com/fwcd/kotlin-debug-adapter/releases/download/0.4.4/adapter.zip";
    hash = "sha256-gNbGomFcWqOLTa83/RWS4xpRGr+jmkovns9Sy7HX9bg=";
  };
in
{
  options.${namespace}.nixvim = {
    enable = mkBoolOpt false "Enable nixvim program";

    nightly = mkBoolOpt false "Use nightly neovim";

    plugins = {
      avante = {
        enable = mkBoolOpt true "Enable Avante plugin";
        provider = mkOption {
          type = types.enum [ "claude" "openai" "ollama" "copilot" "openrouter" ];
          default = "openrouter";
          description = "AI provider to use with Avante";
        };
      };

      obsidian = {
        enable = mkBoolOpt true "Enable Obsidian plugin";
      };

      copilot = {
        enable = mkBoolOpt true "Enable GitHub Copilot";
        enable-nes = mkBoolOpt false "Enable GitHub Copilot 'Next Edit Suggestion'";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      defaultEditor = true;

      # NOTE: due to overlay, nixvim would install and use nightly
      package = mkIf cfg.nightly neovimNightlyPkg;

      colorschemes = import ./colorscheme.nix { inherit nixvimLib; };

      autoGroups = {
        user_generic.clear = true;
        user_lsp.clear = true;
      };

      # NOTE: supposed to be better, this experimental lua loader uses cache; disable if you have issues
      luaLoader.enable = true;
      clipboard.register = "unnamedplus";

      # WARN: this could could improve performance by a lot, by repacking plugins into one,
      # but plugins must have unique names and files
      performance.combinePlugins.enable = false;

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
        fzf
        jdt-language-server
        vscode-extensions.vscjava.vscode-java-debug
        vscode-extensions.vscjava.vscode-java-test
        vscode-extensions.ms-python.debugpy
        vscode-extensions.davidanson.vscode-markdownlint
        vscode-extensions.vadimcn.vscode-lldb
        vscode-js-debug
        codespell
        gofumpt
        gotools
        black
        isort
        delve
        prettierd
        scalafmt
        yamllint
        hadolint
        tflint
        pylint
        checkstyle
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
      extraPlugins = import ./extra/plugins.nix { inherit pkgs lib nixvimLib; };
      extraFiles = import ./extra/files.nix { inherit pkgs; };
      extraConfigLua = import ./extra/config.nix { inherit kotlin-dap-adapter; };
      extraConfigLuaPost = ''
        -- This line is called a `modeline`. See `:help modeline`
        -- vim: ts=2 sts=2 sw=2 et
      '';
    };
  };
}
