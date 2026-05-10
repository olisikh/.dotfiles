{ ... }:
{
  plugins.telescope = {
    enable = true;
    extensions = {
      fzf-native.enable = true;
      ui-select.enable = true;
    };
  };

  keymaps = [
    {
      key = "<leader>?";
      action = ":lua require('telescope.builtin').oldfiles()<cr>";
      mode = "n";
      options = {
        desc = "telescope: recent files";
      };
    }
    {
      key = "<leader>.";
      action = ":lua require('telescope.builtin').buffers()<cr>";
      mode = "n";
      options = {
        desc = "telescope: buffers";
      };
    }
    {
      key = "<leader>sf";
      action = ":lua require('telescope.builtin').git_files()<cr>";
      mode = "n";
      options.desc = "telescope: [s]earch git [f]iles";
    }
    {
      key = "<leader>sb";
      action = ":lua require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({ winblend = 10, previewer = false }))<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [b]uffer";
      };
    }
    {
      key = "<leader>sh";
      action = ":lua require('telescope.builtin').help_tags()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [h]elp";
      };
    }
    {
      key = "<leader>sw";
      action = ":lua require('telescope.builtin').grep_string()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [w]ord";
      };
    }
    {
      key = "<leader>ss";
      action = ":lua require('telescope.builtin').lsp_document_symbols()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [s]ymbols";
      };
    }
    {
      key = "<leader>sS";
      action = ":lua require('telescope.builtin').lsp_workspace_symbols()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch workspace [S]ymbols";
      };
    }
    {
      key = "<leader>sd";
      action = ":lua require('telescope.builtin').diagnostics()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [d]iagnostics";
      };
    }
    {
      key = "<leader>sk";
      action = ":lua require('telescope.builtin').keymaps()<cr>";
      mode = "n";
      options = {
        desc = "telescope: [s]earch [k]eymaps";
      };
    }
  ];
}
