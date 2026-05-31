{ ... }:
{
  nixvim = {
    mkKeymaps = keymaps:
      map
        (keymap:
          keymap // {
            options = {
              silent = true;
              noremap = true;
            } // (keymap.options or { });
          })
        keymaps;
  };
}
