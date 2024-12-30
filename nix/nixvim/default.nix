{ pkgs, ... }:
let
  harpoon-lualine = (pkgs.vimUtils.buildVimPlugin {
    name = "harpoon-lualine";
    src = pkgs.fetchFromGitHub {
      owner = "letieu";
      repo = "harpoon-lualine";
      rev = "master";
      hash = "sha256-pH7U1BYD7B1y611TJ+t8ggPM3KOaSIB3Jtuj3fPKqpc=";
    };
  });
  zio-quickfix = (pkgs.vimUtils.buildVimPlugin {
    name = "nvim-scala-zio-quickfix";
    src = pkgs.fetchFromGitHub {
      owner = "olisikh";
      repo = "nvim-scala-zio-quickfix";
      rev = "main";
      hash = "sha256-dVRVDBZWncEkBw6cLBJE2HZ8KhNSpffEn3Exvnllx78=";
    };
  });
in
{
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

    userCommands = { };

    imports = [
      ./options.nix
      ./plugins.nix
    ];

    keymaps = import ./keymaps
      ++ import keymaps/dap.nix
      ++ import keymaps/lsp.nix
      ++ import keymaps/telescope.nix
      ++ import keymaps/smart-splits.nix
      ++ import keymaps/oil.nix
      ++ import keymaps/nvim-tree.nix
      ++ import keymaps/neotest.nix
      ++ import keymaps/trouble.nix
      ++ import keymaps/nvim-jdtls.nix
      ++ import keymaps/lazy-git.nix
      ++ import keymaps/todo-comments.nix;

    extraPackages = with pkgs; [
      jdt-language-server
      vscode-extensions.vscjava.vscode-java-debug
      vscode-extensions.vscjava.vscode-java-test
      vscode-extensions.ms-python.debugpy
      vscode-extensions.vadimcn.vscode-lldb
      vscode-js-debug
      delve
    ];

    # TODO: all these plugins need to be installed
    # maybe some of them I could contribute to nixvim
    extraPlugins = with pkgs.vimPlugins; [
      nvim-metals
      nvim-jdtls
      lazydev-nvim
      copilot-lualine
      harpoon2
      harpoon-lualine
      zio-quickfix
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

      -- NOTE: configure harpoon2
      local harpoon = require('harpoon')
      harpoon:setup({})

      -- TODO: move harpoon config to a separate file
      local conf = require('telescope.config').values
      local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        require('telescope.pickers')
          .new({}, {
            prompt_title = 'Harpoon',
            finder = require('telescope.finders').new_table({ results = file_paths }),
            previewer = conf.file_previewer({}),
            sorter = conf.generic_sorter({}),
          })
          :find()
      end

      vim.keymap.set('n', '<leader>H', function() toggle_telescope(harpoon:list()) end, { desc = 'harpoon: Open harpoon window' })
      vim.keymap.set('n', '<leader>h', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'harpoon: Toggle quick menu' })
      vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end, { desc = 'harpoon: Add file to list' })
      vim.keymap.set('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'harpoon: Open file 1' })
      vim.keymap.set('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'harpoon: Open file 2' })
      vim.keymap.set('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'harpoon: Open file 3' })
      vim.keymap.set('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'harpoon: Open file 4' })


      -- NOTE: replace generic letter signs with nice icons for diagnostics
      local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
      for type, icon in pairs(signs) do
        local hl = 'DiagnosticSign' .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
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
