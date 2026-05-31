{ lib, ... }:
with lib; {

  zsh = {

    # NOTE: zsh initContent ordering helpers
    # lower number = earlier in .zshrc
    mkEarly = content: mkOrder 500 content;
    mkMid = content: mkOrder 1000 content;
    mkLate = content: mkOrder 2000 content;
  };
}
