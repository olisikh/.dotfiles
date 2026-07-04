{ ... }:
{
  extraConfigLua = ''
    -- HACK: Neovim 0.12 draws codelens as a fake virtual line above the
    -- target line. Restore the old end-of-line inline style by intercepting
    -- the extmark calls that the internal codelens provider creates.
    local orig_set_extmark = vim.api.nvim_buf_set_extmark
    vim.api.nvim_buf_set_extmark = function(bufnr, ns_id, line, col, opts)
      if opts.virt_lines and opts.virt_lines_above then
        local namespaces = vim.api.nvim_get_namespaces()
        local is_codelens = false
        for name, id in pairs(namespaces) do
          if id == ns_id and name:match("^nvim%.lsp%.codelens:") then
            is_codelens = true
            break
          end
        end

        if is_codelens then
          local parts = opts.virt_lines[1] or {}
          local virt_text = {}
          for _, chunk in ipairs(parts) do
            local text = chunk[1] or ""
            if text ~= "" and not text:match("^ +$") then
              table.insert(virt_text, chunk)
            end
          end

          if #virt_text > 0 then
            return orig_set_extmark(bufnr, ns_id, line, col, {
              virt_text = virt_text,
              virt_text_pos = "eol",
              hl_mode = opts.hl_mode or "combine",
            })
          end

          -- No real text, fall through to original (keeps placeholder behavior).
        end
      end

      return orig_set_extmark(bufnr, ns_id, line, col, opts)
    end
  '';
}
