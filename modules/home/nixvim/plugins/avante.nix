{ config, namespace, ... }:
let
  cfg = config.${namespace}.nixvim.plugins.avante;
in
{
  avante = {
    enable = cfg.enable;

    settings = {
      provider = cfg.provider;

      providers = {
        openrouter = {
          __inherited_from = "openai";
          endpoint = "https://openrouter.ai/api/v1";
          api_key_name = "OPENROUTER_API_KEY";
          model = "google/gemini-2.5-flash";
        };
        ollama = {
          endpoint = "http://localhost:11434";
          model = "qwen3-coder:30b";
        };
      };

      behaviour = {
        auto_suggestions = false; # using copilot
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
