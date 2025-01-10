{ ... }: {
  keymaps = [
    # -- Make sure Space is not mapped to anything, used as leader key
    # map({ 'n', 'v' }, '<Space>', '<nop>', { silent = true })
    # map('n', '<esc>', '<nop>', { silent = true })
    {
      key = "<Space>";
      action = "<nop>";
      mode = "n";
      options = {
        silent = true;
      };
    }
    {
      key = "<Space>";
      action = "<nop>";
      mode = "v";
      options = {
        silent = true;
      };
    }
    {
      key = "<Esc>";
      action = "<nop>";
      mode = "n";
      options = {
        silent = true;
      };
    }

    # -- Shift Q to do nothing, avoid weirdness
    # map('n', 'Q', '<nop>')
    {
      key = "Q";
      action = "<nop>";
      mode = "n";
      options = {
        silent = true;
      };
    }

    #
    # -- Remap for dealing with word wrap
    # map('n', 'k', "v:count == 0 ? 'gk' : 'kzz'", { expr = true, silent = true })
    # map('n', 'j', "v:count == 0 ? 'gj' : 'jzz'", { expr = true, silent = true })
    {
      key = "k";
      action = "v:count == 0 ? 'gk' : 'kzz'";
      mode = "n";
      options = {
        expr = true;
        silent = true;
      };
    }
    {
      key = "j";
      action = "v:count == 0 ? 'gj' : 'jzz'";
      mode = "n";
      options = {
        expr = true;
        silent = true;
      };
    }

    # -- Join lines together
    # map('n', 'J', 'mzJ`z', { desc = 'join lines' })
    {
      key = "J";
      action = "mzJ`z";
      mode = "n";
      options = {
        desc = "join lines";
      };
    }

    # -- Move things between statements
    # map('v', 'J', ":m '>+1<cr>gv=gv", { desc = 'move selection down between statements' })
    # map('v', 'K', ":m '<-2<cr>gv=gv", { desc = 'move selection up between statements' })
    {
      key = "J";
      action = ":m '>+1<cr>gv=gv";
      mode = "v";
      options = {
        desc = "move selection down";
      };
    }
    {
      key = "K";
      action = ":m '<-2<cr>gv=gv";
      mode = "v";
      options = {
        desc = "move selection up";
      };
    }

    # -- Keep cursor in the middle when moving half page up/down
    # -- map('n', '<C-d>', '<C-d>zz', { desc = 'jump half page down' })
    # -- map('n', '<C-u>', '<C-u>zz', { desc = 'jump half page up' })
    {
      key = "<C-d>";
      action = "<C-d>zz";
      mode = "n";
      options = {
        desc = "jump half page down";
      };
    }
    {
      key = "<C-u>";
      action = "<C-u>zz";
      mode = "n";
      options = {
        desc = "jump half page up";
      };
    }

    # -- Cursor in the middle during searches
    # map('n', 'n', 'nzzzv', { desc = 'jump to next match item' })
    # map('n', 'N', 'Nzzzv', { desc = 'jump to prev match item' })
    {
      key = "n";
      action = "nzzzv";
      mode = "n";
      options = {
        desc = "jump to next match";
      };
    }
    {
      key = "N";
      action = "Nzzzv";
      mode = "n";
      options = {
        desc = "jump to prev match";
      };
    }

    # -- Paste the text and keep it in clipboard while pasting
    # map('x', '<leader>p', '"_dP', { desc = 'paste keeping the clipboard' })
    {
      key = "<leader>p";
      action = ''"_dP'';
      mode = "x";
      options = {
        desc = "paste & keep";
      };
    }

    # -- copy into system clipboard, (useful for copying outside of vim context)
    # map({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'copy to blackhole register' })
    # map('n', '<leader>Y', '"+Y', { desc = 'copy line to blackhole register' })
    # map({ 'n', 'v' }, '<leader>d', '"_d', { desc = 'cut to blackhole register' })
    {
      key = "<leader>y";
      action = ''"+y'';
      mode = "n";
      options = {
        desc = "yank to system clipboard";
      };
    }
    {
      key = "<leader>y";
      action = ''"+y'';
      mode = "v";
      options = {
        desc = "yank to system clipboard";
      };
    }
    {
      key = "<leader>Y";
      action = ''"+Y'';
      mode = "n";
      options = {
        desc = "copy line to blackhole";
      };
    }
    # {
    #   key = "<leader>d";
    #   action = ''"_d'';
    #   mode = "n";
    #   options = {
    #     desc = "cut to blackhole";
    #   };
    # }
    # {
    #   key = "<leader>d";
    #   action = ''"_d'';
    #   mode = "v";
    #   options = {
    #     desc = "cut to blackhole";
    #   };
    # }

    #
    # -- Increase speed of window resize commande
    # nmap('<C-w>>', ':vertical resize +10<cr>', { noremap = true, silent = true })
    # nmap('<C-w><', ':vertical resize -10<cr>', { noremap = true, silent = true })
    # nmap('<C-w>+', ':horizontal resize +5<cr>', { noremap = true, silent = true })
    # nmap('<C-w>-', ':horizontal resize -5<cr>', { noremap = true, silent = true })
    {
      key = "<C-w>>";
      action = ":vertical resize +10<cr>";
      mode = "n";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<C-w><";
      action = ":vertical resize -10<cr>";
      mode = "n";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<C-w>+";
      action = ":horizontal resize +5<cr>";
      mode = "n";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<C-w>-";
      action = ":horizontal resize -5<cr>";
      mode = "n";
      options = {
        noremap = true;
        silent = true;
      };
    }
    #
    # -- Shift line or block right and left
    # nmap('<Tab>', '>>', { noremap = true, silent = true })
    # nmap('<S-Tab>', '<<', { noremap = true, silent = true })
    # map('v', '<Tab>', '>gv', { noremap = true, silent = true })
    # map('v', '<S-Tab>', '<gv', { noremap = true, silent = true })
    {
      key = "<Tab>";
      action = ">>";
      mode = "n";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<S-Tab>";
      action = "<<";
      mode = "n";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<Tab>";
      action = ">gv";
      mode = "v";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<S-Tab>";
      action = "<gv";
      mode = "v";
      options = {
        noremap = true;
        silent = true;
      };
    }

    #
    # -- keep jump keymaps
    # nmap('<C-i>', '<C-i>', { noremap = true })
    # nmap('<C-o>', '<C-o>', { noremap = true })
    {
      key = "<C-i>";
      action = "<C-i>";
      mode = "n";
      options = {
        noremap = true;
      };
    }
    {
      key = "<C-o>";
      action = "<C-o>";
      mode = "n";
      options = {
        noremap = true;
      };
    }
  ]
  ++ import ./dap.nix
  ++ import ./lsp.nix
  ++ import ./telescope.nix
  ++ import ./smart-splits.nix
  ++ import ./oil.nix
  ++ import ./nvim-tree.nix
  ++ import ./neotest.nix
  ++ import ./trouble.nix
  ++ import ./nvim-jdtls.nix
  ++ import ./lazy-git.nix
  ++ import ./todo-comments.nix
  ++ import ./treesj.nix
  ++ import ./undotree.nix
  ++ import ./obsidian.nix;
}
