{ pkgs, nixvimLib, ... }:
{
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
          is_test_file = nixvimLib.mkRaw
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
        package = pkgs.vimPlugins.neotest-scala; # NOTE: replace with my neotest-scala plugin
      };
      golang.enable = true;
      rust.enable = true; # NOTE: rustacean's neotest integration is used instead
      vitest.enable = true;
      jest.enable = true;
      gradle = {
        enable = true;
        package = pkgs.vimPlugins.neotest-gradle;
      };
    };
  };
}
