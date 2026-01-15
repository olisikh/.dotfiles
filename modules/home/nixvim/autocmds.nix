{ ... }:
{
  autoCmd = [
    {
      event = "TextYankPost";
      pattern = "*";
      group = "user_generic";
      command = "silent! lua vim.highlight.on_yank()";
    }
    {
      event = [ "BufRead" "BufNewFile" ];
      pattern = [ "*.tf" " *.tfvars" " *.hcl" ];
      group = "user_lsp";
      command = "set filetype=terraform";
    }
    {
      event = "FileType";
      pattern = "helm";
      group = "user_lsp";
      command = "LspRestart";
    }
    {
      event = [ "BufEnter" "CursorHold" "InsertLeave" ];
      pattern = "*";
      group = "user_lsp";
      command = "silent! lua vim.lsp.codelens.refresh()";
    }
    {
      event = [ "CursorHold" "CursorHoldI" ];
      pattern = "*";
      group = "user_lsp";
      command = "silent! lua vim.lsp.buf.document_highlight()";
    }
    {
      event = "CursorMoved";
      pattern = "*";
      group = "user_lsp";
      command = "silent! lua vim.lsp.buf.clear_references()";
    }
  ];
}
