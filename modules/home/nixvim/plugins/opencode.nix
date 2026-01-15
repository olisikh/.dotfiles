{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf;

  # cfg = config.${namespace}.nixvim.plugins.opencode;
in
{
  # options.${namespace}.nixvim.plugins.opencode = {
  #   enable = lib.mkBoolOpt true "Enable OpenCode plugin";
  # };



  plugins.opencode = {
    enable = true;

    settings = { };
  };


  keymaps = [
    {
      mode = [ "n" "x" ];
      key = "<C-a>";
      action = ":lua require('opencode').ask('@this: ', { submit = true })<cr>";
      options = {
        desc = "Ask opencode";
      };
    }
    {
      mode = [ "n" "x" ];
      key = "<C-x>";
      action = ":lua require('opencode').select()<cr>";
      options = {
        desc = "Execute opencode action";
      };
    }
    {
      mode = [ "n" "t" ];
      key = "<C-.>";
      action = ":lua require('opencode').toggle()<cr>";
      options = {
        desc = "Toggle opencode";
      };
    }
    {
      mode = [ "n" "x" ];
      key = "go";
      action = ":lua return require('opencode').operator('@this ')<cr>";
      options = {
        expr = true;
        desc = "Add range to opencode";
      };
    }
    {
      mode = "n";
      key = "goo";
      action = ":lua return require('opencode').operator('@this ') .. '_'<cr>";
      options = {
        expr = true;
        desc = "Add line to opencode";
      };
    }
    {
      mode = "n";
      key = "<S-C-u>";
      action = ":lua require('opencode').command('session.half.page.up')<cr>";
      options = {
        desc = "opencode half page up";
      };
    }
    {
      mode = "n";
      key = "<S-C-d>";
      action = ":lua require('opencode').command('session.half.page.down')<cr>";
      options = {
        desc = "opencode half page down";
      };
    }
    {
      mode = "n";
      key = "+";
      action = "<C-a>";
      options = {
        desc = "Increment";
        noremap = true;
      };
    }
    {
      mode = "n";
      key = "-";
      action = "<C-x>";
      options = {
        desc = "Decrement";
        noremap = true;
      };
    }
  ];
}
