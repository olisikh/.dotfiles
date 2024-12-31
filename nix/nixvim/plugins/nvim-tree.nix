{
  nvim-tree = {
    enable = true;
    renderer = {
      icons = {
        gitPlacement = "after";
      };
    };
    view = {
      width = 50;
    };
    git = {
      enable = true;
      ignore = true;
    };
    filters = {
      dotfiles = true;
    };
    onAttach = {
      __raw =
        # lua
        ''
          function(bufnr)
            require("nvim-tree.api")
              .config
              .mappings
              .default_on_attach(bufnr)
          end
        '';
    };
  };
}