{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.virtualization.multipass;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.dev.virtualization.multipass = {
    enable = mkBoolOpt false "Enable multipass module";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "multipass requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "multipass" ];

    launchd.user.agents.multipassd = {
      path = [ config.environment.systemPath ];

      serviceConfig = {
        Label = "com.canonical.multipass.multipassd";
        ProgramArguments = [
          "/Applications/Multipass.app/Contents/Library/LoginItems/multipassd.app/Contents/MacOS/multipassd"
        ];

        RunAtLoad = true;
        KeepAlive = true;

        StandardOutPath = "/tmp/multipassd.stdout.log";
        StandardErrorPath = "/tmp/multipassd.stderr.log";
      };
    };
  };
}
