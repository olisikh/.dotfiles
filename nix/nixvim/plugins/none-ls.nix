{
  none-ls = {
    enable = true;
    sources = {
      code_actions = {
        statix.enable = true;
      };
      formatting = {
        prettier = {
          enable = true;
          disableTsServerFormatter = true;
        };
        black.enable = true;
        nixpkgs_fmt.enable = true;
        gofumpt.enable = true;
        goimports.enable = true;
        stylua.enable = true;
        ktlint.enable = true;
        # jsonlint.enable = true;
        # yamllint.enable = true;
      };
    };
  };
}
