{ nixvimLib, lib, config, namespace, ... }:
let
  cfg = config.${namespace}.nixvim.plugins.avante;
in
{
  avante = {
    enable = cfg.enable;

    settings = {
      provider = cfg.provider;

      # auto_suggestions_provider = "copilot";

      behaviour = {
        auto_suggestions = false; # using copilot
      };

      claude = {
        endpoint = "https://api.anthropic.com";
        model = "claude-3-5-sonnet-20241022";
        temperature = 0;
        max_tokens = 4096;
      };

      mappings = {
        diff = {
          both = "cb";
          next = "]x";
          none = "c0";
          ours = "co";
          prev = "[x";
          theirs = "ct";
        };
        jump = {
          next = "]]";
          prev = "[[";
        };
      };

      # suggestion = {
      #   debounce = 2000;
      #   throttle = 600;
      # };
    };
  };
}
