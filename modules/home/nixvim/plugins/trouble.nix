{ ... }:
{

  plugins.trouble.enable = true;

  keymaps = [
    # NOTE: Trouble
    # nmap('<leader>xx', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'trouble: document diagnostics' })
    {
      key = "<leader>xx";
      action = ":Trouble diagnostics toggle filter.buf=0<cr>";
      mode = "n";
      options = {
        desc = "trouble: document diagnostics";
      };
    }
    # nmap('<leader>xX', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'trouble: workspace diagnostics' })
    {
      key = "<leader>xd";
      action = ":Trouble diagnostics toggle<cr>";
      mode = "n";
      options = {
        desc = "trouble: workspace diagnostics";
      };
    }
    # nmap('<leader>xl', '<cmd>Trouble loclist toggle<cr>', { desc = 'trouble: [l]oclist' })
    {
      key = "<leader>xl";
      action = ":Trouble loclist toggle<cr>";
      mode = "n";
      options = {
        desc = "trouble: [l]oclist";
      };
    }
    # nmap('<leader>xq', '<cmd>Trouble qflist toggle<cr>', { desc = 'trouble: [q]uickfix' })
    {
      key = "<leader>xq";
      action = ":Trouble qflist toggle<cr>";
      mode = "n";
      options = {
        desc = "trouble: [q]uickfix";
      };
    }
  ];
}
