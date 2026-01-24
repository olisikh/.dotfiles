{ pkgs, ... }:

let
  garbuliya = pkgs.vimUtils.buildVimPlugin {
    name = "garbuliya";
    src = pkgs.writeTextDir "lua/garbuliya.lua" (builtins.readFile ./garbuliya/init.lua);
  };
in
{
  extraPlugins = [
    garbuliya
  ];

  extraConfigLua = ''
    require("garbuliya").setup({
      endpoint = "https://opencode.ai/zen/v1/chat/completions",
      api_key  = os.getenv("OPENCODE_API_KEY"),
      model    = "grok-code",
    })
  '';
}
