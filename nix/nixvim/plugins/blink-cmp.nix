{ nixvimLib, ... }:
{
  blink-cmp = {
    enable = true;
    settings = {
      # -- 'default' for mappings similar to built-in completion
      # -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
      # -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
      # -- See the full "keymap" documentation for information on defining your own keymap.
      keymap = { preset = "default"; };

      # -- Default list of enabled providers defined so that you can extend it
      # -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = [ "lazydev" "lsp" "snippets" "luasnip" "path" ];
        cmdline = nixvimLib.emptyTable; # disable neovim cmdline completions, use classic Tab instead
        providers = {
          lazydev = {
            name = "LazyDev";
            enabled = true;
            module = "lazydev.integrations.blink";
            score_offset = 10000; # -- show at a higher priority than lsp
          };
          lsp = {
            name = "LSP";
            enabled = true;
            module = "blink.cmp.sources.lsp";
            score_offset = 1000;
          };
          luasnip = {
            name = "luasnip";
            enabled = true;
            module = "blink.cmp.sources.luasnip";
            score_offset = 950;
          };
          snippets = {
            name = "snippets";
            enabled = true;
            module = "blink.cmp.sources.snippets";
            score_offset = 900;
          };
        };
      };
      snippets = {
        expand = nixvimLib.mkRaw ''
          function(snip) require('luasnip').lsp_expand(snip) end
        '';
        active = nixvimLib.mkRaw ''
          function(filter)
            if filter and filter.direction then
              return require('luasnip').jumpable(filter.direction)
            end
            return require('luasnip').in_snippet()
          end
        '';
        jump = nixvimLib.mkRaw ''
          function(direction)
            require('luasnip').jump(direction)
          end
        '';
      };

      appearance = {
        # -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        # -- Useful for when your theme doesn't support blink.cmp
        # -- Will be removed in a future release
        use_nvim_cmp_as_default = false;
        # -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        # -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono";
      };

      completion = {
        # -- 'prefix' will fuzzy match on the text before the cursor
        # -- 'full' will fuzzy match on the text before *and* after the cursor
        # -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
        keyword = { range = "full"; };

        # -- Disable auto brackets
        # -- NOTE: some LSPs may add auto brackets themselves anyway
        accept = { auto_brackets = { enabled = false; }; };

        # -- Insert completion item on selection, don't select by default
        list = { selection = "auto_insert"; };

        menu = {
          # -- Don't automatically show the completion menu
          auto_show = false;

          # -- nvim-cmp style menu
          draw = {
            columns = [
              (nixvimLib.listToUnkeyedAttrs [ "label" "label_description" ] // { gap = 1; })
              (nixvimLib.listToUnkeyedAttrs [ "kind_icon" "kind" ] // { gap = 1; })
            ];
          };
        };

        # -- Show documentation when selecting a completion item
        documentation = {
          auto_show = true;
          auto_show_delay_ms = 500;
        };

        # -- Display a preview of the selected item on the current line
        ghost_text = {
          enabled = true;
        };
      };

      # -- Experimental signature help support
      signature = {
        enabled = true;
      };
    };
  };
}
