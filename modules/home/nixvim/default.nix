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

      package = mkIf cfg.nightly neovimNightlyPkg;

      autoGroups = {
        user_generic.clear = true;
        user_lsp.clear = true;
      };

      luaLoader.enable = true;
      clipboard.register = "unnamedplus";

      imports = [
        ./colorscheme.nix
        ./options.nix
        ./keymaps.nix
        ./plugins.nix
        ./files.nix
        ./autocmds.nix
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
        local root = "/Users/olisikh/Develop/nvim-plugins"

        -- If you have nested dirs or want only some, adjust the pattern.
        for name, t in vim.fs.dir(root) do
          if t == "directory" then
            local p = root .. "/" .. name

            -- Optional: ignore dot dirs
            if name:sub(1, 1) ~= "." then
              -- Add plugin to runtimepath.
              -- Use prepend if you want local plugins to override Nix-provided ones.
              vim.opt.rtp:prepend(p)
            end
          end
        end  

        -- This line is called a `modeline`. See `:help modeline`
        -- vim: ts=2 sts=2 sw=2 et
      '';
    };
  };
}
