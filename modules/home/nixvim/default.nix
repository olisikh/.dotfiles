{ lib, config, namespace, pkgs, inputs, system, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.nixvim;

  neovimNightlyPkg = inputs.nightly-neovim-overlay.packages.${system}.default;
in
{
  options.${namespace}.nixvim = {
    enable = mkBoolOpt false "Enable nixvim program";
    nightly = mkBoolOpt false "Use nightly neovim";
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      _module.args = {
        # NOTE: propagate inputs to each module imported within this scope
        inherit inputs lib namespace system;

        # NOTE: use pkgs with applied snowfall overlays
        pkgs = lib.mkForce pkgs;
      };

      enable = true;
      defaultEditor = true;

      # NOTE: due to overlay, nixvim would install and use nightly
      package = mkIf cfg.nightly neovimNightlyPkg;

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
        ./colorscheme.nix
        ./options.nix
        ./keymaps.nix
        ./plugins.nix
      ];

      # TODO: move each package to respective plugin that uses it
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
        yq
        ktlint
        eslint_d
        google-java-format
        lombok
        nixpkgs-fmt
      ];

      extraPlugins = with pkgs.vimPlugins; [ fzf-lua ];

      extraFiles = {
        "ftplugin/scala.lua".source = ./ftplugin/scala.lua;
        "ftplugin/terraform.lua".source = ./ftplugin/terraform.lua;
        "ftplugin/kotlin.lua".source = ./ftplugin/kotlin.lua;

        "ftplugin/java.lua".text = import ./ftplugin/java.lua.nix { inherit pkgs; };

        "queries/lua/injections.scm".source = ./queries/lua/injections.scm;
        "queries/scala/injections.scm".source = ./queries/scala/injections.scm;

        # custom snippets
        "snippets".source = ./snippets;
      };

      extraConfigLua = ''
        vim.loop.fs_mkdir(vim.o.backupdir, 750)
        vim.loop.fs_mkdir(vim.o.directory, 750)
        vim.loop.fs_mkdir(vim.o.undodir, 750)

        -- set backup directory to be a subdirectory of data to ensure that backups are not written to git repos
        vim.o.backupdir = vim.fn.stdpath("data") .. "/backup"

        -- Configure 'directory' to ensure that Neovim swap files are not written to repos.
        vim.o.directory = vim.fn.stdpath("data") .. "/directory" 
        vim.o.sessionoptions = vim.o.sessionoptions .. ",globals"

        -- set undodir to ensure that the undofiles are not saved to git repos.
        vim.o.undodir = vim.fn.stdpath("data") .. "/undo" 
      '';

      extraConfigLuaPost = ''
        -- This line is called a `modeline`. See `:help modeline`
        -- vim: ts=2 sts=2 sw=2 et
      '';
    };
  };
}
