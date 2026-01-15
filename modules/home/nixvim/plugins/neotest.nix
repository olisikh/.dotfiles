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
            is_test_file = lib.nixvim.mkRaw ''
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

  keymaps =
    [
      # NOTE: NeoTest
      # nmap('<leader>tr', neotest.run.run, { desc = 'neotest: run nearest test' })
      {
        key = "<leader>tr";
        action = ":lua require('neotest').run.run()<cr>";
        mode = "n";
        options = {
          desc = "neotest: run nearest test";
        };
      }
      # nmap('<leader>td', function() neotest.run.run({ strategy = 'dap' }) end, { desc = 'neotest: debug nearest test' })
      {
        key = "<leader>td";
        action = ":lua require('neotest').run.run({strategy = 'dap' })<cr>";
        mode = "n";
        options = {
          desc = "neotest: debug nearest test";
        };
      }
      # nmap('<leader>tR', function() neotest.run.run(vim.fn.expand('%')) end, { desc = 'neotest: run current file' })
      {
        key = "<leader>tR";
        action = ":lua require('neotest').run.run(vim.fn.expand('%'))<cr>";
        mode = "n";
        options = {
          desc = "neotest: run tests in buffer";
        };
      }
      # nmap('<leader>tD', function() neotest.run.run({ vim.fn.expand('%'), strategy = 'dap' }) end, { desc = 'neotest: debug current file' })
      {
        key = "<leader>tD";
        action = ":lua require('neotest').run.run({ vim.fn.expand('%'), strategy = 'dap' })<cr>";
        mode = "n";
        options = {
          desc = "neotest: debug tests in buffer";
        };
      }
      # nmap('<leader>ta', neotest.run.attach, { desc = 'neotest: attach to nearest test' })
      {
        key = "<leader>ta";
        action = ":lua require('neotest').run.attach()<cr>";
        mode = "n";
        options = {
          desc = "neotest: attach to nearest test";
        };
      }
      # nmap('<leader>tS', neotest.summary.toggle, { desc = 'neotest: toggle test summary' })
      {
        key = "<leader>ti";
        action = ":lua require('neotest').summary.toggle()<cr>";
        mode = "n";
        options = {
          desc = "neotest: toggle test info";
        };
      }
      # nmap('<leader>ts', neotest.run.stop, { desc = 'neotest: stop nearest test' })
      {
        key = "<leader>ts";
        action = ":lua require('neotest').run.stop()<cr>";
        mode = "n";
        options = {
          desc = "neotest: stop nearest test";
        };
      }
      # nmap('<leader>to', neotest.output_panel.toggle, { desc = 'neotest: open output panel' })
      {
        key = "<leader>to";
        action = ":lua require('neotest').output_panel.toggle()<cr>";
        mode = "n";
        options = {
          desc = "neotest: toggle test output";
        };
      }
      # nmap('<leader>tO', function() neotest.output.open({ enter = true }) end, { desc = 'neotest: open output floating window' })
      {
        key = "<leader>tO";
        action = ":lua require('neotest').output.panel({ enter = true })<cr>";
        mode = "n";
        options = {
          desc = "neotest: toggle test output (floating window)";
        };
      }
      # nmap('[t', function() neotest.jump.prev({ status = 'failed' }) end, { desc = 'neotest: jump to prev failed test' })
      {
        key = "[t";
        action = ":lua require('neotest').jump.prev({ status = 'failed' })<cr>";
        mode = "n";
        options = {
          desc = "neotest: jump to prev failed test";
        };
      }
      # nmap(']t', function() neotest.jump.next({ status = 'failed' }) end, { desc = 'neotest: jump to prev failed test' })
      {
        key = "]t";
        action = ":lua require('neotest').jump.next({ stauts = 'failed' })<cr>";
        mode = "n";
        options = {
          desc = "neotest: jump to next failed test";
        };
      }
      {
        key = "<leader>tS";
        action = ":lua require('neotest').summary.toggle()<cr>";
        mode = "n";
        options = {
          desc = "neotest: [t]est [S]ummary";
        };
      }
    ];
}
