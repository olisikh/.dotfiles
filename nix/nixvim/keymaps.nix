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
      action = "\"_dP";
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
      action = "\"+y";
      mode = "n";
      options = {
        desc = "copy to blackhole";
      };
    }
    {
      key = "<leader>y";
      action = "\"+y";
      mode = "v";
      options = {
        desc = "copy to blackhole";
      };
    }
    {
      key = "<leader>Y";
      action = "\"+Y";
      mode = "n";
      options = {
        desc = "copy line to blackhole";
      };
    }
    {
      key = "<leader>d";
      action = "\"_d";
      mode = "n";
      options = {
        desc = "cut to blackhole";
      };
    }
    {
      key = "<leader>d";
      action = "\"_d";
      mode = "v";
      options = {
        desc = "cut to blackhole";
      };
    }

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

    # Oil plugin
    # nmap('-', oil.open, { desc = 'oil: open parent directory' })
    # nmap('_', function() oil.open(vim.uv.cwd()) end, { desc = 'oil: open cwd directory' })
    {
      key = "-";
      action = ":lua require('oil').open()<cr>";
      mode = "n";
      options = {
        desc = "oil: open parent folder";
      };
    }
    {
      key = "_";
      action = ":lua require('oil').open(vim.uv.cwd()))<cr>";
      mode = "n";
      options = {
        desc = "oil: open cwd folder";
      };
    }

    # Smart Splits for Wezterm
    # vim.keymap.set('n', '<A-h>', s.resize_left)
    {
      key = "<A-h>";
      action = ":lua require('smart-splits').resize_left()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<A-j>', s.resize_down)
    {
      key = "<A-j>";
      action = ":lua require('smart-splits').resize_down()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<A-k>', s.resize_up)
    {
      key = "<A-k>";
      action = ":lua require('smart-splits').resize_up()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<A-l>', s.resize_right)
    {
      key = "<A-l>";
      action = ":lua require('smart-splits').resize_right()<cr>";
      mode = "n";
    }
    # -- moving between splits
    # vim.keymap.set('n', '<C-h>', s.move_cursor_left)
    {
      key = "<C-h>";
      action = ":lua require('smart-splits').move_cursor_left()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<C-j>', s.move_cursor_down)
    {
      key = "<C-j>";
      action = ":lua require('smart-splits').move_cursor_down()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<C-k>', s.move_cursor_up)
    {
      key = "<C-k>";
      action = ":lua require('smart-splits').move_cursor_up()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<C-l>', s.move_cursor_right)
    {
      key = "<C-l>";
      action = ":lua require('smart-splits').move_cursor_right()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<C-\\>', s.move_cursor_previous)
    # -- swapping buffers between windows
    # vim.keymap.set('n', '<leader><leader>h', s.swap_buf_left)
    {
      key = "<leader><leader>h";
      action = ":lua require('smart-splits').swap_buf_left()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<leader><leader>j', s.swap_buf_down)
    {
      key = "<leader><leader>j";
      action = ":lua require('smart-splits').swap_buf_down()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<leader><leader>k', s.swap_buf_up)
    {
      key = "<leader><leader>k";
      action = ":lua require('smart-splits').swap_buf_up()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<leader><leader>l', s.swap_buf_right)
    {
      key = "<leader><leader>l";
      action = ":lua require('smart-splits').swap_buf_right()<cr>";
      mode = "n";
    }

    # Telescope
    #     -- Telescope key mappings
    # nmap('<leader>?', telescope_builtin.oldfiles, { desc = 'telescope: find recently opened files' })
    {
      key = "<leader>?";
      action = ":lua require('telescope.builtin').oldfiles()<cr>";
      mode = "n";
      options = {
        desc = "telescope: recent files";
      };
    }
    # nmap('<leader><space>', telescope_builtin.buffers, { desc = 'telescope: find existing buffers' })
    {
      key = "<leader><Space>";
      action = ":lua require('telescope.builtin').buffers()<cr>";
      mode = "n";
      options = {
        desc = "telescope: buffers";
      };
    }
    # nmap('<leader>/', function()
    #   telescope_builtin.current_buffer_fuzzy_find(telescope_themes.get_dropdown({ winblend = 10, previewer = false }))
    # end, { desc = 'telescope: fuzzy find in current buffer' })
    {
      key = "<leader><Space>";
      action = ":lua require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({ winblend = 10, previewer = false }))<cr>";
      mode = "n";
      options = {
        desc = "telescope: find in buffer";
      };
    }
    #
    # nmap('<leader>sf', telescope_builtin.git_files, { desc = 'telescope: [s]earch [f]iles' })
    {
      key = "<leader>sf";
      action = ":lua require('telescope.builtin').git_files()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [f]iles";
      };
    }
    # nmap('<leader>sp', telescope_builtin.find_files, { desc = 'telescope: [s]earch [p]roject files' })
    {
      key = "<leader>sp";
      action = ":lua require('telescope.builtin').find_files()<cr>";
      mode = "n";
      options = {
        desc = "telescope: search [p]roject [f]iles";
      };
    }
    # nmap('<leader>sh', telescope_builtin.help_tags, { desc = 'telescope: [s]earch [h]elp' })
    {
      key = "<leader>sh";
      action = ":lua require('telescope.builtin').help_tags()<cr>";
      mode = "n";
      options = {
        desc = "telescope: search [h]elp";
      };
    }
    # nmap('<leader>sw', telescope_builtin.grep_string, { desc = 'telescope: [s]earch current [w]ord' })
    {
      key = "<leader>sw";
      action = ":lua require('telescope.builtin').grep_string()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [w]ord";
      };
    }
    # nmap('<leader>sg', telescope_builtin.live_grep, { desc = 'telescope: [s]earch by [g]rep' })
    {
      key = "<leader>sg";
      action = ":lua require('telescope.builtin').live_grep()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [g]rep";
      };
    }
    # nmap('<leader>sd', telescope_builtin.diagnostics, { desc = 'telescope: [s]earch [d]iagnostics' })
    {
      key = "<leader>sd";
      action = ":lua require('telescope.builtin').diagnostics()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [d]iagnostics";
      };
    }
    # nmap('<leader>sk', telescope_builtin.keymaps, { desc = 'telescope: [s]earch [k]eymaps' })
    {
      key = "<leader>sk";
      action = ":lua require('telescope.builtin').keymaps()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [k]eymaps";
      };
    }


    # LazyGit
    {
      key = "<leader>gg";
      action = "<cmd>LazyGit<cr>";
      mode = "n";
      options = {
        desc = "lazygit: open";
      };
    }
    {
      key = "<leader>gf";
      action = "<cmd>LazyGitCurrentFile<cr>";
      mode = "n";
      options = {
        desc = "lazygit: open current file";
      };
    }

    # LSP
    # nmap('<leader>cr', vim.lsp.buf.rename, { desc = 'lsp: [r]ename' })
    {
      key = "<leader>cr";
      action = ":lua vim.lsp.buf.rename()<cr>";
      mode = "n";
      options = {
        desc = "lsp: [r]ename";
      };
    }
    # nmap('<leader>ca', vim.lsp.buf.code_action, { desc = 'lsp: [c]ode [a]ction' })
    {
      key = "<leader>ca";
      action = ":lua vim.lsp.buf.code_action<cr>";
      mode = "n";
      options = {
        desc = "lsp: [c]ode [a]ction";
      };
    }
    # nmap('<leader>cd', vim.diagnostic.open_float, { desc = 'diagnostic: show [c]ode [d]iagnostic' })
    {
      key = "<leader>cd";
      action = ":lua vim.diagnostic.open_float<cr>";
      mode = "n";
      options = {
        desc = "lsp: [c]ode [d]iagnostic";
      };
    }
    # nmap('<leader>cf', function() vim.lsp.buf.format() end, { desc = 'lsp: [c]ode [f]ormat' })
    {
      key = "<leader>cf";
      action = ":lua vim.lsp.buf.format()<cr>";
      mode = "n";
      options = {
        desc = "lsp: [c]ode [f]ormat";
      };
    }

    # map('v', '<leader>cf', function()
    #   local vstart = vim.fn.getpos("'<")
    #   local vend = vim.fn.getpos("'>")
    #
    #   vim.lsp.buf.format({ range = { vstart, vend } })
    # end, { desc = 'lsp: [c]ode [f]ormat' })
    {
      key = "<leader>cf";
      action = ":lua vim.lsp.buf.format({ range = { vim.fn.getpos(\"'<\"), vim.fn.getpos(\"'>\") } })<cr>";
      mode = "v";
      options = {
        desc = "lsp: [c]ode [f]ormat";
      };
    }
    # nmap('<leader>ci', function()
    #   vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    # end, { desc = 'lsp: toggle inlay hints (buffer)' })
    {
      key = "<leader>ci";
      action = ":lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>";
      mode = "n";
      options = {
        desc = "lsp: [c]ode [i]nlay hints";
      };
    }
    # nmap('gd', telescope_builtin.lsp_definitions, { desc = 'lsp: [g]oto [d]efinition' })
    {
      key = "gd";
      action = ":lua require('telescope.builtin').lsp_definitions()<cr>";
      mode = "n";
      options = {
        desc = "lsp: [g]oto [d]efinition";
      };
    }
    # nmap('gr', telescope_builtin.lsp_references, { desc = 'lsp: [g]oto [r]eferences' })
    {
      key = "gr";
      action = ":lua require('telescope.builtin').lsp_references()<cr>";
      mode = "n";
      options = {
        desc = "lsp: [g]oto [r]eferences";
      };
    }


    # JDTLS
    # nmap('<leader>jv', function() jdtls.extract_variable() end, { desc = 'jdtls: extract [v]ariable' })
    {
      key = "<leader>jv";
      action = ":lua require('jdtls').extract_variable()<cr>";
      mode = "n";
      options = {
        desc = "jdtls: extract [v]ariable";
      };
    }
    # nmap('<leader>jm', function() jdtls.extract_method() end, { desc = 'jdtls: extract [m]ethod' })
    {
      key = "<leader>jm";
      action = ":lua require('jdtls').extract_method()<cr>";
      mode = "n";
      options = {
        desc = "jdtls: extract [m]ethod";
      };
    }
    # nmap('<leader>jc', function() jdtls.extract_constant() end, { desc = 'jdtls: extract [c]onstant' })
    {
      key = "<leader>jc";
      action = ":lua require('jdtls').extract_constant()<cr>";
      mode = "n";
      options = {
        desc = "jdtls: extract [c]onstant";
      };
    }
    # nmap('<leader>jt', function() jdtls.pick_test() end, { desc = 'jdtls: run [t]est' })
    {
      key = "<leader>jt";
      action = ":lua require('jdtls').pick_test()<cr>";
      mode = "n";
      options = {
        desc = "jdtls: run [t]est";
      };
    }
    # nmap('<leader>co', function() jdtls.organize_imports() end, { desc = 'jdtls: [o]rganize imports' })
    {
      key = "<leader>co";
      action = ":lua require('jdtls').organize_imports()<cr>";
      mode = "n";
      options = {
        desc = "jdtls: [o]rganize imports";
      };
    }

    # NeoTree
    # nmap('<leader>o', api.tree.toggle, { desc = 'nvim-tree: toggle', noremap = true })
    {
      key = "<leader>o";
      action = ":lua require('nvim-tree.api').tree.toggle()<cr>";
      mode = "n";
      options = {
        desc = "nvim-tree: toggle";
        noremap = true;
      };
    }
    # nmap('<leader>O', ':NvimTreeFindFile<cr>', { desc = 'nvim-tree: locale file in a tree', noremap = true })
    {
      key = "<leader>O";
      action = ":NvimTreeFindFile<cr>";
      mode = "n";
      options = {
        desc = "nvim-tree: navigate to file";
        noremap = true;
      };
    }


  ];
} 
