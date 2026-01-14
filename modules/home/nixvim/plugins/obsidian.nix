{ pkgs, lib, ... }:
{
  plugins = {
    obsidian = {
      enable = true;
      package = pkgs.vimPlugins.obsidian-nvim; # NOTE: my overlay is not used otherwise, need this line
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
            -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
            -- In this case a note with the title 'My new note' will be given an ID that looks
            -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
            local suffix = ""
            if title ~= nil then
              -- If title is given, transform it into valid file name.
              suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
            else
              -- If title is nil, just add 4 random uppercase letters to the suffix.
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
      options = {
        desc = "telescope: [s]earch [o]bsidian";
      };
    }
    {
      key = "<leader>zd";
      action = ":Obsidian daily<cr>";
      mode = "n";
      options = {
        desc = "obsidian: [z]k [d]aily";
      };
    }
    {
      key = "<leader>zn";
      action = ":Obsidian new<cr>";
      mode = "n";
      options = {
        desc = "obsidian: [z]k [n]ew";
      };
    }
    {
      key = "<leader>zo";
      action = ":Obsidian open<cr>";
      mode = "n";
      options = {
        desc = "obsidian: [z]k [o]pen";
      };
    }
  ];
}
