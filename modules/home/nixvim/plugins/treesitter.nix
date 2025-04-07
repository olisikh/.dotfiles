{ pkgs, ... }: {
  treesitter = {
    enable = true;
    gccPackage = pkgs.gcc;

    # NOTE: add treesitter grammar here to install it
    grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      bash
      diff
      json
      jsonc
      lua
      rust
      query
      make
      markdown
      markdown_inline
      python
      properties
      java
      c
      css
      html
      dockerfile
      git_config
      git_rebase
      gitattributes
      gitignore
      gitcommit
      groovy
      go
      gosum
      gomod
      hocon
      kotlin
      javascript
      typescript
      python
      toml
      yaml
      xml
      tmux
      terraform
      scala
      tsx
      sql
      scheme
      vim
      vimdoc
      ini
    ];

    settings = {
      highlight = { enable = true; };
      indent = { enable = true; disable = [ "python" ]; };
      incremental_selection = {
        enable = true;
        keymaps = {
          init_selection = "<C-space>";
          node_incremental = "<C-space>";
          node_decremental = "<C-b>";
          # -- scope_incremental = "<C-b>";
        };
      };
    };
  };

  treesitter-textobjects = {
    enable = true;
    select = {
      enable = true;
      lookahead = true; # -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        # -- You can use the capture groups defined in textobjects.scm
        aa = "@parameter.outer";
        ia = "@parameter.inner";
        af = "@function.outer";
        "if" = "@function.inner";
        ac = "@class.outer";
        ic = "@class.inner";
      };
    };
    move = {
      enable = true;
      setJumps = true;
      gotoNextStart = {
        "]m" = "@function.outer";
        "]]" = "@class.outer";
      };
      gotoNextEnd = {
        "]M" = "@function.outer";
        "][" = "@class.outer";
      };
      gotoPreviousStart = {
        "[m" = "@function.outer";
        "[[" = "@class.outer";
      };
      gotoPreviousEnd = {
        "[M" = "@function.outer";
        "[]" = "@class.outer";
      };
    };
    swap = {
      enable = true;
      swapPrevious = {
        "[p" = "@parameter.inner";
      };
      swapNext = {
        "]p" = "@parameter.inner";
      };
    };
  };

  treesitter-context = {
    enable = true;
    settings = {
      max_lines = 5; # -- How many lines the window should span. Values <= 0 mean no limit.
      min_window_height = 0; # -- Minimum editor window height to enable context. Values <= 0 mean no limit.
      line_numbers = true;
      multiline_threshold = 20; # -- Maximum number of lines to show for a single context
      trim_scope = "inner"; # -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      mode = "cursor"; # -- Line used to calculate context. Choices: 'cursor', 'topline'
      # -- Separator between context and content. Should be a single character string, like '-'.
      # -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
      # separator = nil,
      zindex = 20; # -- The Z-index of the context window
      # on_attach = nil, # -- (fun(buf: integer): boolean) return false to disable attaching
    };
  };

  treesitter-refactor.enable = true;
}
