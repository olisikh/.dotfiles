{ lib, ... }:
with lib;
rec {
  mkOptRequired = type: desc:
    mkOption {
      inherit type;
      description = desc;
    };

  mkOptRequired' = type:
    mkOption {
      inherit type;
    };

  mkOpt = type: default: desc:
    mkOption {
      inherit type default;
      description = desc;
    };

  mkOpt' = type: default: mkOpt type default null;

  mkBoolOpt = mkOpt types.bool;

  mkBoolOpt' = mkOpt' types.bool;

  enabled = {
    enable = true;
  };

  disabled = {
    enable = false;
  };
}
