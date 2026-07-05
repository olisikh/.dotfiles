{ ... }: {
  globals = {
    mapleader = " ";
    maplocalleader = " ";
    loaded_netrw = 1;
    loaded_netrwPlugin = 1;
  };

  diagnostic = {
    settings = {
      virtual_text = {
        current_line = true;
      };
      update_in_insert = false;
    };
  };


  extraConfigLua = ''
    -- Hide diagnostic virtual text while typing in insert mode;
    -- restore it when leaving insert mode.
    local diagnostics_group = vim.api.nvim_create_augroup("DiagnosticInsertToggle", { clear = true })

    vim.api.nvim_create_autocmd("InsertEnter", {
      group = diagnostics_group,
      callback = function()
        vim.diagnostic.config({ virtual_text = false })
      end,
    })

    vim.api.nvim_create_autocmd("InsertLeave", {
      group = diagnostics_group,
      callback = function()
        vim.diagnostic.config({ virtual_text = { current_line = true } })
      end,
    })
  '';

  opts = {
    cursorline = false;
    linebreak = true;
    wrap = true;
    colorcolumn = "121";
    scrolloff = 8;
    splitbelow = true; # when splitting horizontally
    splitright = true; # when splitting vertically
    guicursor = "n-v-c:block-Cursor/lCursor-blinkon0,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175";
    hlsearch = false;
    number = true;
    relativenumber = true;
    mouse = "a";
    breakindent = true;
    swapfile = false;
    backup = false;
    undofile = true;

    autoindent = true;
    smartindent = true;
    indentexpr = "";
    backspace = "indent,eol,start";
    tabstop = 2;
    shiftwidth = 2;
    expandtab = true;

    showtabline = 0;
    ignorecase = true;
    smartcase = true;
    signcolumn = "yes";
    updatetime = 250;
    timeout = true;
    timeoutlen = 300;

    winborder = "rounded";

    completeopt = "menu,menuone,noinsert";
    termguicolors = true;

    autoread = true; # automatically read files updated outside of nvim

    list = false; # show whitespaces, tabs, etc as virtual text
    listchars = {
      tab = "↦↦";
      space = "·";
      # multispace = "·";
      lead = "·";
      trail = "·";
      nbsp = "␣";
      # eol = "↲";
    };

    laststatus = 3;
  };
}
