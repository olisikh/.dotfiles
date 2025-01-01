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
          is_test_file = {
            __raw = ''
              function(path)
                local file = io.open(path, 'r')
                if file == nil then
                  return false
                end
                local content = file:read('a')

                if content == nil then
                  return false
                else
                  file:close()
                  return content:match('def test_')
                end
              end
            '';
          };
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
    };
  };
}
