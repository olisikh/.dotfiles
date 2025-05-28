{ ... }: {
  none-ls = {
    enable = true;
    sources = {
      code_actions = {
        statix.enable = true;
      };
      diagnostics = {
        codespell.enable = true;
      };
      # WARN: for formatting conform-nvim is used, as it falls back to LSP
    };
  };
}
