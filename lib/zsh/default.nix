{ lib, ... }:
with lib; {

  # NOTE: zsh initContent ordering helpers
  # lower number = earlier in .zshrc
  mkZshEarly = content: mkOrder 500 content;
  mkZshMid = content: mkOrder 1000 content;
  mkZshLate = content: mkOrder 2000 content;
}
