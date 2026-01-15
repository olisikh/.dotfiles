{ ... }:
{
  plugins = {
    indent-blankline = {
      enable = true;
      settings = {
        indent = {
          char = " ";
        };
        whitespace = {
          remove_blankline_trail = false;
        };
        scope = {
          enabled = true;
          show_start = false;
          show_end = false;
          char = "▎";
        };
      };
    };
  };
}
