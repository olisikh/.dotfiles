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
  nvim-scala-zio-quickfix = (pkgs.vimUtils.buildVimPlugin {
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
    defaultEditor = true;

    # TODO: use nightly?
    # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

    colorschemes = import ./colorscheme;

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

    imports = [
      ./options
      ./keymaps
      ./plugins
    ];

    extraPackages = with pkgs; [
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
      vale
      tflint
      pylint
      checkstyle
      nodePackages.jsonlint
      shfmt
      rustfmt
      rust-analyzer
      stylua
      jq
      ktlint
      eslint_d
      google-java-format
      lombok
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
      nvim-scala-zio-quickfix
      treesj
    ];

    extraFiles = import ./extra-files { inherit pkgs; };

    extraConfigLua = import ./extra-config;
    extraConfigLuaPost = ''
      -- This line is called a `modeline`. See `:help modeline`
      -- vim: ts=2 sts=2 sw=2 et
    '';
  };
}
