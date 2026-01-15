{ channels, inputs, ... }:

final: prev: {
  vimPlugins = prev.vimPlugins.extend (self: super: {
    aerial-nvim = super.aerial-nvim.overrideAttrs (old: {
      nvimSkipModules = (old.nvimSkipModules or [ ]) ++ [
        "aerial.fzf-lua"
      ];
    });
  });
}

