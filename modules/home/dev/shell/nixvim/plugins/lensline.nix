{ ... }:
{
  plugins.lensline = {
    enable = true;
    settings = {
      profiles = [
        {
          name = "default";
          style = {
            placement = "inline";
            prefix = "";
          };
        }
      ];
    };
  };
}
