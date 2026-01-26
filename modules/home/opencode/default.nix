{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.opencode;
in
{
  options.${namespace}.opencode = {
    enable = mkBoolOpt false "Enable OpenCode program";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      settings = {
        theme = "catppuccin";
        autoupdate = false;
        autoshare = false;

        model = "opencode/glm-4.7";
        small_model = "opencode/gpt-5.1-codex-mini";

        plugin = [ "opencode-antigravity-auth" "oh-my-opencode" ];

        provider = {
          google = {
            name = "Google";
            models = {
              antigravity-gemini-3-pro-high = {
                name = "Gemini 3 Pro High (Antigravity)";
                thinking = true;
                attachment = true;
                limit = {
                  context = 1048576;
                  output = 65535;
                };
                modalities = {
                  input = [
                    "text"
                    "image"
                    "pdf"
                  ];
                  output = [
                    "text"
                  ];
                };
              };
              antigravity-gemini-3-pro-low = {
                name = "Gemini 3 Pro Low (Antigravity)";
                thinking = true;
                attachment = true;
                limit = {
                  context = 1048576;
                  output = 65535;
                };
                modalities = {
                  input = [
                    "text"
                    "image"
                    "pdf"
                  ];
                  output = [
                    "text"
                  ];
                };
              };
              antigravity-gemini-3-flash = {
                name = "Gemini 3 Flash (Antigravity)";
                attachment = true;
                limit = {
                  context = 1048576;
                  output = 65536;
                };
                modalities = {
                  input = [
                    "text"
                    "image"
                    "pdf"
                  ];
                  output = [
                    "text"
                  ];
                };
              };
            };
          };
        };
      };
    };

    home = {
      file = {
        ".config/opencode/oh-my-opencode.jsonc".source = ./config/oh-my-opencode.jsonc;
      };

      sessionVariables = {
        OPENCODE_CONFIG = "${config.home.homeDirectory}/.config/opencode/config.json";
      };
    };
  };
}

