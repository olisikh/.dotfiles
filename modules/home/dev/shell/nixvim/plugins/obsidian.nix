{ lib, nsLib, nsConfig, ... }:
let
  inherit (nsLib.nixvim) mkKeymaps;
  cfg = nsConfig.dev.shell.nixvim.plugins.obsidian;
in
{
  config = lib.mkIf cfg.enable {
    plugins = {
      obsidian = {
        enable = true;
        doCheck = false;
        settings = {
          inherit (cfg) workspaces;

          legacy_commands = false;

          # Keep inserted wikilinks readable now that note IDs are UUIDs.
          # Default id-based links would be:
          #   [[7bce18a9-92eb-4a33-a22a-e8bdd91b8629|Raise of AI]]
          # Path-based links stay human-friendly:
          #   [[10 Work/Raise of AI|Raise of AI]]
          wiki_link_func = lib.nixvim.mkRaw ''require("obsidian.builtin").wiki_link_path_prefix'';

          # Builds the file stem/path for new notes from the typed title.
          # Input -> output examples:
          #   "Buying a house in NL" -> "Buying a house in NL.md"
          #   "30 Personal/Netherlands/Buying a house in NL" -> "30 Personal/Netherlands/Buying a house in NL.md"
          #   nil or "" -> "Untitled 2026-05-18 234247.md"
          # Obsidian.nvim appends ".md"; returning "/" keeps nested note paths.
          note_id_func = lib.nixvim.mkRaw ''
            function(title)
              title = title or ""

              local note_id = title
                :gsub("[\r\n\t]", " ")
                :gsub("[\\:*?\"<>|]", " ")
                :gsub("%s+", " ")
                :gsub("^%s+", "")
                :gsub("%s+$", "")

              if note_id == "" then
                return "Untitled " .. os.date("%Y-%m-%d %H%M%S")
              end

              return note_id
            end
          '';
          # Keeps frontmatter stable and searchable:
          #   id = stable UUIDv4 machine id, generated once and preserved afterwards
          #   title = human note title, usually the filename/title typed to :Obsidian new
          #   created = note creation date for human sorting/filtering
          #   aliases/tags = written only when non-empty
          frontmatter = {
            sort = [
              "id"
              "title"
              "created"
              "aliases"
              "tags"
            ];
            func = lib.nixvim.mkRaw ''
              function(note)
                local metadata = note.metadata or {}
                local out = {}

                for key, value in pairs(metadata) do
                  out[key] = value
                end

                local function clean(value)
                  return tostring(value or "")
                    :gsub("[\r\n\t]", " ")
                    :gsub("%s+", " ")
                    :gsub("^%s+", "")
                    :gsub("%s+$", "")
                end

                local function basename(value)
                  return clean(value)
                    :gsub("%.md$", "")
                    :gsub("^.*/", "")
                end

                local title = clean(metadata.title or note.title or basename(note.path or note.id))
                local existing_id = clean(metadata.id or note.id)
                local function should_preserve_id(value)
                  return value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
                end

                local function uuidv4()
                  local uv = vim.uv or vim.loop
                  if uv and uv.random then
                    local bytes = { string.byte(uv.random(16), 1, 16) }
                    bytes[7] = bit.bor(bit.band(bytes[7], 0x0f), 0x40)
                    bytes[9] = bit.bor(bit.band(bytes[9], 0x3f), 0x80)
                    return string.format(
                      "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                      bytes[1],
                      bytes[2],
                      bytes[3],
                      bytes[4],
                      bytes[5],
                      bytes[6],
                      bytes[7],
                      bytes[8],
                      bytes[9],
                      bytes[10],
                      bytes[11],
                      bytes[12],
                      bytes[13],
                      bytes[14],
                      bytes[15],
                      bytes[16]
                    )
                  end

                  return string.format("%s-%s", os.date("%Y%m%dT%H%M%S"), tostring(math.random(100000, 999999)))
                end

                if should_preserve_id(existing_id) then
                  out.id = existing_id
                else
                  out.id = uuidv4()
                end
                if title ~= "" then
                  out.title = title
                end
                out.created = metadata.created or os.date("%Y-%m-%d")

                local aliases = {}
                local seen = {}
                local function add_alias(alias)
                  alias = clean(alias)
                  if alias == "" or alias == title or alias == note.id or seen[alias] then
                    return
                  end
                  seen[alias] = true
                  table.insert(aliases, alias)
                end

                for _, alias in ipairs(note.aliases or {}) do
                  add_alias(alias)
                end

                if #aliases > 0 then
                  out.aliases = aliases
                else
                  out.aliases = nil
                end

                if note.tags ~= nil and not vim.tbl_isempty(note.tags) then
                  out.tags = note.tags
                else
                  out.tags = nil
                end

                return out
              end
            '';
          };
        };
      };
    };

    keymaps = mkKeymaps [
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
