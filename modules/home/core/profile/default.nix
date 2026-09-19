{ config, lib, ... }:
let
  profile = config._module.args.profile;
in
{
  _module.args.profile = lib.mkDefault "default";

  # The managed state file is authoritative for existing shells; session
  # variables additionally expose the selected profile to newly started apps.
  home.sessionVariables.DOTFILES_PROFILE = profile;

  home.file.".config/dotfiles/.env".text = ''
    DOTFILES_PROFILE=${profile}
  '';
}
