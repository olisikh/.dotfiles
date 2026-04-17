{ pkgs, lib, namespace, config, hmConfig, ... }:
let
  cfg = hmConfig.${namespace}.nixvim.plugins.obsidian;
in
{
  config = lib.mkIf cfg.enable {
    plugins = {
      obsidian = {
        enable = true;
        package = pkgs.vimPlugins.obsidian-nvim;
        doCheck = false;
        settings = {
          legacy_commands = false;
          workspaces = [
            {
              name = "default";
              path = "~/notes";
            }
          ];
          note_id_func = lib.nixvim.mkRaw ''
            function(title)
              local suffix = ""
              if title ~= nil then
                suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
              else
                for _ = 1, 4 do
                  suffix = suffix .. string.char(math.random(65, 90))
                end
              end
              return suffix .. "-" .. tostring(os.time())
            end
          '';
        };
      };
    };

    keymaps = [
      {
        key = "<leader>so";
        action = ":Obsidian search<cr>";
        mode = "n";
        options.desc = "telescope: [s]earch [o]bsidian";
      }
      {
        key = "<leader>zd";
        action = ":Obsidian daily<cr>";
        mode = "n";
        options.desc = "obsidian: [z]k [d]aily";
      }
      {
        key = "<leader>zn";
        action = ":Obsidian new<cr>";
        mode = "n";
        options.desc = "obsidian: [z]k [n]ew";
      }
      {
        key = "<leader>zo";
        action = ":Obsidian open<cr>";
        mode = "n";
        options.desc = "obsidian: [z]k [o]pen";
      }
    ];
  };
}
