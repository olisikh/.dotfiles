{ lib, ... }:
with lib;
rec {
  mkOpt = type: default: desc:
    mkOption {
      inherit type default;
      description = desc;
    };

  mkOpt' = type: default:
    mkOpt type default null;

  mkBoolOpt = mkOpt types.bool;

  mkBoolOpt' = mkOpt' types.bool;

  enabled = {
    enable = true;
  };

  disabled = {
    enable = false;
  };

  capitalize =
    s:
    let
      len = stringLength s;
    in
    if len == 0 then "" else (lib.toUpper (substring 0 1 s)) + (substring 1 len s);

  pad = text: n:
    let
      len = lib.stringLength text;
    in
    if len >= n then
      text
    else
      text + lib.strings.replicate (n - len) " ";

  color = {
    pink = s: "\\033[0;35m${s}\\033[0m";
    green = s: "\\033[0;32m${s}\\033[0m";
    blue = s: "\\033[0;34m${s}\\033[0m";
    cyan = s: "\\033[0;36m${s}\\033[0m";
  };

  # return an int (1/0) based on boolean value
  # `boolToNum true` -> 1
  boolToNum = bool: if bool then 1 else 0;

  default-attrs = mapAttrs (_key: mkDefault);

  force-attrs = mapAttrs (_key: mkForce);

  nested-default-attrs = mapAttrs (_key: default-attrs);

  nested-force-attrs = mapAttrs (_key: force-attrs);
}
