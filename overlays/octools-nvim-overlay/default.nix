{ ... }:

final: prev:
let
  pkgs = prev.pkgs;
in
{
  vimPlugins = prev.vimPlugins.extend (self: super: {

    octools-nvim = (pkgs.vimUtils.buildVimPlugin {
      name = "octools-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "olisikh";
        repo = "octools.nvim";
        rev = "v0.0.1";
        hash = "sha256-WPUg24z0pcRRCzgWN8aGeEbUqxgAyQzeENF+FOGWbmg=";
      };

      # No external dependencies required
      # The plugin only depends on Neovim's built-in functionality
      # and the opencode CLI tool (external requirement)
    });

  });
}
