{ ... }: {
  globals = {
    mapleader = " ";
    maplocalleader = " ";
    loaded_netrw = 1;
    loaded_netrwPlugin = 1;
  };

  diagnostics = {
    virtual_text = true;
  };

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
    clipboard = "unnamedplus";
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

    completeopt = "menu,menuone,noinsert";
    termguicolors = true;
  };
}
