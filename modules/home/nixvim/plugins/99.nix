{ pkgs, ... }:
let
  p99 = (pkgs.vimUtils.buildVimPlugin {
    name = "99";
    src = pkgs.fetchFromGitHub {
      owner = "theprimeagen";
      repo = "99";
      rev = "0fb3b8b2d032289ea7088a37161e1c50bdfccfa9";
      hash = "sha256-7J3YYah5gDufub8fHmSwl4LkgFATJUan+3FsPHdz9zA=";
    };
    # TODO: uncomment if require check starts working again
    doCheck = false;
  });
in
{
  extraPlugins = [ p99 ];

  extraConfigLua = ''
    local _99 = require("99")

    -- For logging that is to a file if you wish to trace through requests
    -- for reporting bugs, i would not rely on this, but instead the provided
    -- logging mechanisms within 99.  This is for more debugging purposes
    local cwd = vim.uv.cwd()
    local basename = vim.fs.basename(cwd)

    _99.setup({
    	logger = {
            level = _99.DEBUG,
            path = "/tmp/" .. basename .. ".99.debug",
            print_on_error = true,
    	},

    	--- A new feature that is centered around tags
    	completion = {
            --- Defaults to .cursor/rules
            -- I am going to disable these until i understand the
            -- problem better.  Inside of cursor rules there is also
            -- application rules, which means i need to apply these
            -- differently
            -- cursor_rules = "<custom path to cursor rules>"

            --- A list of folders where you have your own SKILL.md
            --- Expected format:
            --- /path/to/dir/<skill_name>/SKILL.md
            ---
            --- Example:
            --- Input Path:
            --- "scratch/custom_rules/"
            ---
            --- Output Rules:
            --- {path = "scratch/custom_rules/vim/SKILL.md", name = "vim"},
            --- ... the other rules in that dir ...
            ---
            custom_rules = {
                "scratch/custom_rules/",
            },

            --- What autocomplete do you use.  We currently only
            --- support cmp right now
            -- source = "cmp",
    	},

    	--- WARNING: if you change cwd then this is likely broken
    	--- ill likely fix this in a later change
    	---
    	--- md_files is a list of files to look for and auto add based on the location
    	--- of the originating request.  That means if you are at /foo/bar/baz.lua
    	--- the system will automagically look for:
    	--- /foo/bar/AGENT.md
    	--- /foo/AGENT.md
    	--- assuming that /foo is project root (based on cwd)
    	md_files = {
            "AGENT.md",
            "AGENTS.md",
    	},
    })

    vim.keymap.set("n", "<leader>of", function() _99.fill_in_function() end)
    vim.keymap.set("n", "<leader>op", function() _99.fill_in_function_prompt() end)
    vim.keymap.set("v", "<leader>ov", function() _99.visual() end)
    vim.keymap.set("v", "<leader>ol", function() _99.view_logs() end)
    vim.keymap.set("v", "<leader>os", function() _99.stop_all_requests() end)
  '';
}
