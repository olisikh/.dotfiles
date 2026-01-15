{ lib, ... }:
{
  plugins = {
    blink-cmp = {
      enable = true;
      settings = {
        # -- 'default' for mappings similar to built-in completion
        # -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
        # -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
        # -- See the full "keymap" documentation for information on defining your own keymap.
        keymap.preset = "default";

        # -- Default list of enabled providers defined so that you can extend it
        # -- elsewhere in your config, without redefining it, due to `opts_extend`

        cmdline.enabled = false; # disable neovim cmdline completions, use classic Tab instead

        sources = {
          default = [ "lazydev" "lsp" "snippets" "path" ];
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
            snippets = {
              name = "snippets";
              enabled = true;
              module = "blink.cmp.sources.snippets";
              score_offset = 900;
            };
          };
        };

        # NOTE: disabling luasnip enables default vim.snippets
        snippets.preset = "luasnip";

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
          list = { selection = { preselect = true; auto_insert = true; }; };

          menu = {
            # -- Don't automatically show the completion menu
            auto_show = false;

            # -- nvim-cmp style menu
            draw = {
              columns = [
                (lib.nixvim.listToUnkeyedAttrs [ "label" "label_description" ] // { gap = 1; })
                (lib.nixvim.listToUnkeyedAttrs [ "kind_icon" "kind" ] // { gap = 1; })
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
            enabled = false; # conflicts with copilot
          };
        };

        # -- Experimental signature help support
        signature = {
          enabled = true;
        };
      };
    };
  };
}
