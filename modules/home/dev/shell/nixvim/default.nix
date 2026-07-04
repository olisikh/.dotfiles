{ lib, config, namespace, pkgs, inputs, system, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.dev.shell.nixvim;

  neovimNightlyPkg = inputs.nightly-neovim-overlay.packages.${system}.default;
in
{
  options.${namespace}.dev.shell.nixvim = {
    enable = mkBoolOpt false "Enable nixvim program";
    nightly = mkBoolOpt false "Use nightly neovim";

    plugins = {
      nvim-java = {
        enable = mkBoolOpt true "Enable nvim-java plugin";

        runtimes = mkOpt
          (lib.types.listOf (lib.types.submodule {
            options = {
              name = mkOpt lib.types.str "" "Runtime name exposed to jdtls";
              path = mkOpt lib.types.str "" "Runtime path exposed to jdtls";
              default = mkOpt lib.types.bool false "Whether this runtime is the default jdtls runtime";
            };
          })) [ ] "Additional Java runtimes exposed to jdtls";

        tools = {
          jdk = {
            path = mkOpt lib.types.str "${pkgs.jdk25}" "JDK home path used by nvim-java";
            version = mkOpt lib.types.str "25" "JDK version used by nvim-java";
          };

          jdtls = {
            path = mkOpt lib.types.str "${pkgs.${namespace}.jdt-language-server}/share/java/jdtls" "jdtls path used by nvim-java";
            version = mkOpt lib.types.str "1.60.0" "jdtls version used by nvim-java";
          };

          java-test.path = mkOpt lib.types.str "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test" "Java test extension path used by nvim-java";
          java-debug.path = mkOpt lib.types.str "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug" "Java debug extension path used by nvim-java";
          lombok.path = mkOpt lib.types.str "${pkgs.lombok}/share/java/lombok.jar" "Lombok jar path used by nvim-java";
          spring-boot-tools = {
            enable = mkBoolOpt true "Enable Spring Boot Tools integration for nvim-java";
            path = mkOpt lib.types.str "${pkgs.${namespace}.vscode-spring-boot}/share/vscode/extensions/vmware.vscode-spring-boot" "Spring Boot Tools extension path used by nvim-java";
          };
        };
      };
      obsidian = {
        enable = mkBoolOpt true "Enable obsidian plugin";
        workspaces = mkOpt
          (lib.types.listOf (lib.types.submodule {
            options = {
              name = mkOpt lib.types.str "" "Obsidian workspace name";
              path = mkOpt lib.types.str "" "Obsidian vault path";
            };
          })) [ ] "Obsidian.nvim workspaces";
      };
      copilot.enable = mkBoolOpt true "Enable copilot plugin";
    };
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      _module.args = {
        # NOTE: propagate inputs to each module imported within this scope
        inherit inputs namespace system;
        nsLib = lib.${namespace};
        nsConfig = config.${namespace};

        # NOTE: use pkgs with applied snowfall overlays
        pkgs = lib.mkForce pkgs;
      };

      enable = true;
      defaultEditor = true;

      package = mkIf cfg.nightly neovimNightlyPkg;


      luaLoader.enable = true;
      clipboard.register = "unnamedplus";

      imports = [
        ./colorscheme.nix
        ./options.nix
        ./keymaps.nix
        ./plugins.nix
        ./files.nix
        ./autocmds.nix
        ./autogroups.nix
      ];

      # TODO: move each package to respective plugin that uses it
      extraPackages = with pkgs; [
        gcc
        fzf
        pkgs.${namespace}.jdt-language-server
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

      # NOTE: auto-load all plugins from ~/Develop/nvim-plugins folder (my own convention)
      extraConfigLuaPre = ''
        vim.o.sessionoptions = vim.o.sessionoptions .. ",globals";

        -- set backup directory to be a subdirectory of data to ensure that backups are not written to git repos
        vim.o.backupdir = vim.fn.stdpath("data") .. "/backup"

        -- set swap directory to ensure swap files are not written to git repos.
        vim.o.directory = vim.fn.stdpath("data") .. "/swap"

        -- set undodir to ensure that the undofiles are not saved to git repos.
        vim.o.undodir = vim.fn.stdpath("data") .. "/undo"

        -- make those directories if they don't exist
        vim.fn.mkdir(vim.o.backupdir, "p")
        vim.fn.mkdir(vim.o.directory, "p")
        vim.fn.mkdir(vim.o.undodir, "p")

        -- Auto-load all plugins from ~/Develop/nvim-plugins folder (my own convention).
        local root = vim.fn.expand("~/Develop/nvim-plugins")

        -- If you have nested dirs or want only some, adjust the pattern.
        for name, t in vim.fs.dir(root) do
          if t == "directory" then
            local p = root .. "/" .. name

            -- Optional: ignore dot dirs and __disabled plugins
            if name:sub(1, 1) ~= "." and name:sub(1, 2) ~= "__" then
              -- Add plugin to runtimepath.
              -- Use prepend if you want local plugins to override Nix-provided ones.
              vim.opt.rtp:prepend(p)
            end
          end
        end
      '';

      extraConfigLuaPost = ''
        -- This line is called a `modeline`. See `:help modeline`
        -- vim: ts=2 sts=2 sw=2 et
      '';
    };
  };
}
