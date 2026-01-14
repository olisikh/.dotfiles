{ pkgs, lib, ... }:
let
  # TODO: override these plugins in vimPlugins?
  neotest-scala = (pkgs.vimUtils.buildVimPlugin {
    name = "neotest-scala";
    src = pkgs.fetchFromGitHub {
      owner = "olisikh";
      repo = "neotest-scala";
      rev = "main";
      hash = "sha256-RFEPtWPVHKehfc6PMF6ya0UaDpFIJDD8bFG8xwXPpsk=";
    };
    dependencies = with pkgs.vimPlugins; [
      plenary-nvim
      nvim-nio
      nvim-treesitter-parsers.xml
      neotest
    ];
  });
  neotest-gradle = (pkgs.vimUtils.buildVimPlugin {
    name = "neotest-gradle";
    src = pkgs.fetchFromGitHub {
      owner = "olisikh";
      repo = "neotest-gradle";
      rev = "fix/no_tests_found";
      hash = "sha256-ZRI5fMGqKK5BaMPU38Dtl8A+XmWBzBI9af6wld/V0Q0=";
    };
    dependencies = with pkgs.vimPlugins; [ plenary-nvim nvim-nio neotest ];
  });
in
{
  plugins = {
    neotest = {
      enable = true;
      settings = {
        log_level = "debug"; # NOTE: show debug logs
        diagnostic = {
          enabled = true;
          severity = "error";
        };
        status = {
          enabled = true;
          signs = false;
          virtual_text = true;
        };
      };
      adapters = {
        python = {
          enable = true;
          settings = {
            args = [ "-s" ];
            pytest_discover_instances = true;
            is_test_file = lib.nixvim.mkRaw
              # lua
              ''
                function(file_path)
                  if not vim.endswith(file_path, ".py") then
                    return false
                  end

                  -- NOTE: check if there the file is starting or ending with test keyword
                  local path_segments = vim.split(file_path, "/")
                  local file_name = path_segments[#path_segments]
                  if vim.startswith(file_name, "test_") then
                    return true
                  elseif vim.endswith(file_name, "_test.py" ) then
                    return true
                  end

                  local file = io.open(file_path, "r")
                  if file == nil then
                    return false
                  end
                  local content = file:read("a")
                  file:close()

                  if content == nil then
                    return false
                  end

                  -- NOTE: check if there are functions that start with test_
                  if content:match("def test_") then
                    return true
                  end

                  return false
                end
              '';
          };
        };
        scala = {
          enable = true;
          package = neotest-scala; # NOTE: replace with my neotest-scala plugin
        };
        golang.enable = true;
        rust.enable = true; # NOTE: rustacean's neotest integration is used instead
        vitest.enable = true;
        jest.enable = true;
        gradle = {
          enable = true;
          package = neotest-gradle;
        };
      };
    };
  };
}
