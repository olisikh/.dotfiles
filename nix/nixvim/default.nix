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
      ./keymaps
      ./plugins
    ];

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

    extraConfigLua = import ./extra-config;
    extraFiles = import ./extra-files { inherit pkgs; };
  };
}
