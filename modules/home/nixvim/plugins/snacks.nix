{ lib, ... }:
{
  extraConfigLuaPre = ''
    local function format_duration_ms(ms)
      if ms < 1000 then
        return string.format("%d ms", math.floor(ms + 0.5))
      end

      local seconds = math.floor(ms / 1000)
      local millis = math.floor((ms % 1000) + 0.5)

      if millis == 1000 then
        seconds = seconds + 1
        millis = 0
      end

      return string.format("%d.%03d s", seconds, millis)
    end

    vim.g.start_time = vim.uv.hrtime()
    vim.g.startup_time_text = "…"

    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        local ms = (vim.uv.hrtime() - vim.g.start_time) / 1e6
        vim.g.startup_time_text = format_duration_ms(ms)

        pcall(function() Snacks.dashboard.update() end)
      end,
    })
  '';

  plugins.snacks = {
    enable = true;
    settings = {
      bigfile.enabled = true;
      image.enabled = true;
      input.enabled = true;

      lazygit = {
        configure = true;
      };

      dashboard = {
        enabled = true;
        sections = [
          (lib.nixvim.mkRaw ''
            function()
              return {
                icon = "⚡",
                title = "Startup",
                desc = " " .. vim.g.startup_time_text or "…",
                padding = 1
              }
            end
          '')

          {
            section = "keys";
            padding = 1;
          }

          {
            icon = " ";
            desc = "Browse Repo";
            padding = 1;
            key = "b";
            action = lib.nixvim.mkRaw '' function() Snacks.gitbrowse() end '';
          }

          (lib.nixvim.mkRaw ''
            (function()
              local in_git = Snacks.git.get_root() ~= nil
              local cmds = {
                {
                  icon = " ",
                  title = "Pull Requests",
                  cmd = "gh pr list -L 5",
                  key = "P",
                  action = function()
                    vim.fn.jobstart("gh pr list --web", { detach = true })
                  end,
                  height = 10,
                },
                {
                  icon = " ",
                  title = "Open Issues",
                  cmd = "gh issue list -L 5",
                  key = "i",
                  action = function()
                    vim.fn.jobstart("gh issue list --web", { detach = true })
                  end,
                  height = 10,
                },
              }

              return vim.tbl_map(function(cmd)
                return vim.tbl_extend("force", {
                  section = "terminal",
                  enabled = in_git,
                  padding = 1,
                  ttl = 5 * 60,
                  indent = 3,
                }, cmd)
              end, cmds)
            end)()
          '')
        ];
      };
    };
  };

  keymaps = [
    {
      key = "<leader>gg";
      action = '':lua require("snacks").lazygit.open()<cr>'';
      mode = "n";
      options = {
        desc = "snacks: lazygit open";
      };
    }
    {
      key = "<leader>gl";
      action = '':lua require("snacks").lazygit.log()<cr>'';
      mode = "n";
      options = {
        desc = "snacks: lazygit log";
      };
    }
    {
      key = "<leader>gL";
      action = '':lua require("snacks").lazygit.log_file()<cr>'';
      mode = "n";
      options = {
        desc = "snacks: lazygit current file";
      };
    }
    {
      key = "<leader>gb";
      action = '':lua require("snacks").git.blame_line()<cr>'';
      mode = "n";
      options = {
        desc = "snacks: git blame";
      };
    }
  ];


}
