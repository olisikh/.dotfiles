{ ... }:
{
  imports = [ (./.. + "/olisikh@olisikh-mini/default.nix") ];
  _module.args.profile = "boring";
}
