{ pkgs, ... }: {
  extraPlugins = with pkgs.vimPlugins; [
    cellular-automaton-nvim
  ];

  extraConfigLua = ''
    vim.keymap.set(
      'n',
      '<leader>lr',
      '<cmd>CellularAutomaton make_it_rain<cr>',
      { desc = 'cellular-automaton: Make it rain' }
    );

    vim.keymap.set(
      'n',
      '<leader>lg',
      '<cmd>CellularAutomaton game_of_life<cr>',
      { desc = 'cellular-automaton: Game of Life' }
    );
  '';
}

