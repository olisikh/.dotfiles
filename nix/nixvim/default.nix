{ pkgs, ... }: {
  programs.nixvim = {
    enable = true;

    # TODO: use nightly?
    # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

    colorschemes.catppuccin.enable = true;

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
    ];

    imports = [
      ./plugins.nix
      ./options.nix
      ./keymaps.nix
    ];

    # TODO: all these plugins need to be installed
    extraPlugins = with pkgs.vimPlugins; [
      nvim-metals
      nvim-jdtls
      crates-nvim
      vim-helm
      vim-sleuth
      colorizer
      lazydev-nvim
      harpoon2
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
      "ftplugin/java.lua".text = import ./ftplugin/java.lua.nix { inherit pkgs; };
      "ftplugin/lua.lua".source = ./ftplugin/lua.lua;
    };
  };
}


