{ lib, ... }:
{
  plugins.snacks = {
    enable = true;
    settings = {
      bigfile.enabled = true;

      dashboard = {
        enabled = true;
        sections = [
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
                  title = "Issues",
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
}
