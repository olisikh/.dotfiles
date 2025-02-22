{ pkgs, lib, ... }:
{
  xdg.configFile = {
    "sketchybar" = {
      source = lib.cleanSourceWith { src = lib.cleanSource ./config/.; };
      recursive = true;
    };

    "sketchybar/sketchybarrc" = {
      executable = true;
      text =
        # lua
        ''
          #!/usr/bin/env lua

          -- Add the sketchybar module to the package cpath (the module could be
          -- installed into the default search path then this would not be needed)
          package.cpath = package.cpath .. ";${pkgs.sbarlua}/lib/lua/5.4/sketchybar.so"

          -- Require the sketchybar module
          sbar = require("sketchybar")

          -- Bundle the entire initial configuration into a single message to sketchybar
          -- This improves startup times drastically, try removing both the begin and end
          -- config calls to see the difference -- yeah..
          sbar.begin_config()
          require("init")
          sbar.hotload(true)
          sbar.end_config()

          -- Run the event loop of the sketchybar module (without this there will be no
          -- callback functions executed in the lua module)
          sbar.event_loop()
        '';
    };
  };
}
