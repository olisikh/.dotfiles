{ ... }:
{
  autoCmd = [
    {
      event = "TextYankPost";
      pattern = "*";
      group = "user_generic";
      command = "silent! lua vim.highlight.on_yank()";
    }
  ];
}
