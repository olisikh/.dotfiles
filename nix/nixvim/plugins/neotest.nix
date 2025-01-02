{ pkgs, ... }:
let
  neotest-scala = (pkgs.vimUtils.buildVimPlugin {
    name = "neotest-scala";
    src = pkgs.fetchFromGitHub {
      owner = "olisikh";
      repo = "neotest-scala";
      rev = "main";
      hash = "sha256-RFEPtWPVHKehfc6PMF6ya0UaDpFIJDD8bFG8xwXPpsk=";
    };
  });
in
{
  neotest = {
    enable = true;
    settings = {
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
          is_test_file.__raw =
            # lua
            ''
              function(file_path)
                if not vim.endswith(file_path, ".py") then
                  return false
                end

                local file = io.open(file_path, 'r')
                if file == nil then
                  return false
                end
                local content = file:read('a')
                file:close()

                if content == nil then
                  return false
                end

                local has_tests = content:match('def test')

                -- NOTE: check if there are functions that start with test_
                if content:match('def test_') then
                  return true
                end

                -- NOTE: check if there are files starting or ending with test
                local path_segments = vim.split(file_path, "/")
                local file_name = elems[#path_segments]
                return vim.startswith(file_name, "test_") or vim.endswith(file_name, "_test.py")
              end
            '';
        };
      };
      scala = {
        enable = true;
        package = neotest-scala; # NOTE: replace with my neotest-scala plugin
      };
      golang.enable = true;
      rust.enable = true;
      java.enable = true;
      vitest.enable = true;
      jest.enable = true;
    };
  };
}
