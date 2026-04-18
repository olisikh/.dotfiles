{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.core.homebrew = {
    enable = mkBoolOpt false "Enable common homebrew darwin module";
    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Set to true to automatically update Homebrew before installing packages.";
    };

    upgrade = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Set to true to automatically upgrade Homebrew packages after installation.";
    };

    cleanup = lib.mkOption {
      type = lib.types.enum [ "none" "check" "uninstall" "zap" ];
      default = "zap";
      description = ''Set the cleanup strategy to use after installing Homebrew packages.
      - 'none': packages not present in the generated Brewfile are left installed
      - 'zap': uninstalls all packages not listed in the generated Brewfile, and if the package is a cask, removes all files associated with that cask
      - 'check': verifies during system activation that no Homebrew packages (taps, formulae, casks, etc.) are installed that aren’t present in the generated Brewfile
      - 'uninstall': uninstalls all packages not listed in the generated Brewfile'';
    };

    brews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Homebrew brews to enable";
    };

    casks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Homebrew casks to enable";
    };

    taps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Homebrew taps to enable";
    };
  };

  config = mkIf cfg.enable {
    homebrew = {
      inherit (cfg) brews casks taps;
      enable = true;
      enableZshIntegration = true;
      onActivation = {
        inherit (cfg) autoUpdate upgrade cleanup;
      };
    };

    environment.systemPath = [ "/opt/homebrew/bin" ];
  };
}
