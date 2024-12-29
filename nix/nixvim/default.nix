{ pkgs, ... }: {
  programs.nixvim = {
    enable = true;

    # TODO: use nightly?
    # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        dim_inactive = {
          enabled = false;
        };
        transparent_background = false;
        default_integrations = true;
        integrations = {
          fidget = true;
          cmp = false;
          blink_cmp = true;
          gitsigns = true;
          nvimtree = true;
          neotest = true;
          treesitter = true;
          treesitter_context = true;
          telescope = {
            enabled = true;
          };
          lsp_trouble = true;
          harpoon = true;
          mason = true;
          notify = true;
          which_key = true;
          dap = true;
          dap_ui = true;
          markdown = true;
          indent_blankline = {
            enabled = true;
            colored_indent_levels = false;
          };
          native_lsp = {
            enabled = true;
            virtual_text = {
              errors = [ "italic" ];
              hints = [ "italic" ];
              warnings = [ "italic" ];
              information = [ "italic" ];
            };
            underlines = {
              errors = [ "underline" ];
              hints = [ "underline" ];
              warnings = [ "underline" ];
              information = [ "underline" ];
            };
            inlay_hints = {
              background = false;
            };
          };
        };
      };
    };

    autoCmd = [
      {
        event = [ "TextYankPost" ];
        pattern = [ "*" ];
        command = "silent! lua vim.highlight.on_yank()";
      }
      {
        event = [ "BufRead" "BufNewFile" ];
        pattern = [ "*.tf" " *.tfvars" " *.hcl" ];
        command = "set filetype=terraform";
      }
      {
        event = "FileType";
        pattern = "helm";
        command = "LspRestart";
      }
    ];

    userCommands = {
      # TODO: this is not working, fix
      #
      # CopilotToggle = {
      #   command = ''
      #     local status = require('copilot_status').status()
      #
      #     if status.status == 'offline' then
      #       vim.cmd([[Copilot enable]])
      #     else
      #       vim.cmd([[Copilot disable]])
      #     end
      #   '';
      #   nargs = 0;
      # };
    };

    imports = [
      ./plugins.nix
      ./options.nix
      ./keymaps.nix
    ];

    extraPackages = with pkgs; [
      jdt-language-server
      vscode-extensions.vscjava.vscode-java-debug
      vscode-extensions.vscjava.vscode-java-test
    ];

    # TODO: all these plugins need to be installed
    extraPlugins = with pkgs.vimPlugins; [
      nvim-metals
      nvim-jdtls
      lazydev-nvim
      copilot-lualine
      # harpoon-lualine # NOTE: missing, add to vimPlugins?
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

    extraFiles = {
      "ftplugin/lua.lua".source = ./ftplugin/lua.lua;
      "ftplugin/scala.lua".source = ./ftplugin/scala.lua;
      "ftplugin/java.lua".text = import ./ftplugin/java.lua.nix { pkgs = pkgs; };

      "queries/lua/injections.scm".source = ./queries/lua/injections.scm;
      "queries/scala/injections.scm".source = ./queries/scala/injections.scm;
    };
  };
}


