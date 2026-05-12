{ pkgs, ... }: {
  extraPlugins = with pkgs.vimPlugins; [
    cellular-automaton-nvim
  ];

  extraConfigLua = ''
    local opts = { silent = true, remap = false }

    vim.keymap.set(
      'n',
      '<leader>lr',
      '<cmd>CellularAutomaton make_it_rain<cr>',
      vim.tbl_extend('force', opts, { desc = 'cellular-automaton: Make it rain' })
    );

    vim.keymap.set(
      'n',
      '<leader>lg',
      '<cmd>CellularAutomaton game_of_life<cr>',
      vim.tbl_extend('force', opts, { desc = 'cellular-automaton: Game of Life' })
    );
  '';
}
