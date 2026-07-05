{ ... }:
{
  plugins = {
    which-key = {
      enable = true;
      settings = {
        spec = [
          {
            __unkeyed-1 = "<leader><leader>";
            group = "window";
            icon = {
              icon = "";
              color = "blue";
            };
          }
          {
            __unkeyed-1 = "<leader>b";
            group = "[b]uffer";
            icon = {
              icon = "󰈔";
              color = "cyan";
            };
          }
          {
            __unkeyed-1 = "<leader>c";
            group = "[c]ode";
            icon = {
              icon = "";
              color = "green";
            };
          }
          {
            __unkeyed-1 = "<leader>d";
            group = "[d]ebug";
            icon = {
              icon = "";
              color = "red";
            };
          }
          {
            __unkeyed-1 = "<leader>f";
            group = "[f]ile";
            icon = {
              icon = "󰈔";
              color = "cyan";
            };
          }
          {
            __unkeyed-1 = "<leader>g";
            group = "[g]it";
            icon = {
              icon = "";
              color = "orange";
            };
          }
          {
            __unkeyed-1 = "<leader>h";
            group = "[h]arpoon";
            icon = {
              icon = "󰛢";
              color = "azure";
            };
          }
          {
            __unkeyed-1 = "<leader>l";
            group = "[l]ife";
            icon = {
              icon = "󰐴";
              color = "green";
            };
          }
          {
            __unkeyed-1 = "<leader>o";
            group = "[o]pencode";
            icon = {
              icon = "";
              color = "purple";
            };
          }
          {
            __unkeyed-1 = "<leader>s";
            group = "[s]earch";
            icon = {
              icon = "";
              color = "blue";
            };
          }
          {
            __unkeyed-1 = "<leader>t";
            group = "[t]est";
            icon = {
              icon = "󰙨";
              color = "green";
            };
          }
          {
            __unkeyed-1 = "<leader>x";
            group = "diagnostics";
            icon = {
              icon = "󱖫";
              color = "red";
            };
          }
          {
            __unkeyed-1 = "<leader>z";
            group = "[z]ettelkasten";
            icon = {
              icon = "󰠮";
              color = "yellow";
            };
          }
          {
            __unkeyed-1 = "<leader>sg";
            desc = "fff: [s]earch [g]rep";
            icon = {
              icon = "";
              color = "blue";
            };
          }
          {
            __unkeyed-1 = "<leader>sp";
            desc = "fff: [s]earch [p]roject files";
            icon = {
              icon = "";
              color = "blue";
            };
          }
          {
            __unkeyed-1 = "gr";
            group = "[g]oto / [r]ename";
            icon = {
              icon = "󰞂";
              color = "azure";
            };
          }
          {
            __unkeyed-1 = "grn";
            desc = "lsp: re[n]ame";
          }
          {
            __unkeyed-1 = "gra";
            desc = "lsp: code [a]ction";
          }
          {
            __unkeyed-1 = "grr";
            desc = "lsp: [r]eferences";
          }
          {
            __unkeyed-1 = "gri";
            desc = "lsp: [i]mplementation";
          }
          {
            __unkeyed-1 = "grt";
            desc = "lsp: [t]ype definition";
          }
          {
            __unkeyed-1 = "grD";
            desc = "lsp: [D]eclaration";
          }
          {
            __unkeyed-1 = "gO";
            desc = "lsp: d[O]cument symbols";
          }
        ];
        spelling = {
          enabled = false;
        };
        win = {
          border = "rounded";
        };
      };
    };
  };
}
