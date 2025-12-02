{ channels, inputs, ... }:

final: prev: {
  vimPlugins = prev.vimPlugins.extend (self: super: {
    obsidian-nvim = super.obsidian-nvim.overrideAttrs (old: {
      nvimSkipModules = (old.nvimSkipModules or [ ]) ++ [
        "obsidian.picker._fzf"
      ];
    });
  });
}

