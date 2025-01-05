{ pkgs, lib, ... }:

with pkgs.vimPlugins; [
  lualine-nvim
  nvim-metals
  nvim-jdtls
  lazydev-nvim
  copilot-lualine
  harpoon2
  treesj
]
++ [
  # (pkgs.vimUtils.buildVimPlugin {
  #   name = "harpoon-lualine";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "letieu";
  #     repo = "harpoon-lualine";
  #     rev = "master";
  #     hash = "sha256-pH7U1BYD7B1y611TJ+t8ggPM3KOaSIB3Jtuj3fPKqpc=";
  #   };
  # })
  # (pkgs.vimUtils.buildVimPlugin {
  #   name = "scala-zio-quickfix";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "olisikh";
  #     repo = "nvim-scala-zio-quickfix";
  #     rev = "main";
  #     hash = "sha256-dVRVDBZWncEkBw6cLBJE2HZ8KhNSpffEn3Exvnllx78=";
  #   };
  # })
  # (pkgs.vimUtils.buildVimPlugin {
  #   name = "nvim-dap-kotlin";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "olisikh";
  #     repo = "nvim-dap-kotlin";
  #     rev = "fix/bugs_and_deprecations";
  #     hash = "sha256-cz0oCg5XSXKuPswMVYioawnDroPhgQd7PWt9v1ugPBE=";
  #   };
  # })
  # (pkgs.vimUtils.buildVimPlugin {
  #   name = "neotest-scala";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "olisikh";
  #     repo = "neotest-scala";
  #     rev = "main";
  #     hash = "sha256-RFEPtWPVHKehfc6PMF6ya0UaDpFIJDD8bFG8xwXPpsk=";
  #   };
  # })
  # (pkgs.vimUtils.buildVimPlugin {
  #   name = "neotest-gradle";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "olisikh";
  #     repo = "neotest-gradle";
  #     rev = "fix/no_tests_found";
  #     hash = "sha256-5vwd7VjJjiaWiNWde9iHJMPvNxrOoX28iCJFkDb93is=";
  #   };
  # })
]
