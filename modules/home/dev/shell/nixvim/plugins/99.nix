{ pkgs, ... }:
{
  extraPlugins = [ pkgs.vimPlugins."99" ];

  extraConfigLua = ''
    local _99 = require("99")
    local opencode = vim.fn.executable("opencode2") == 1 and "opencode2" or "opencode"

    local OpenCodeProvider = setmetatable({}, { __index = _99.Providers.OpenCodeProvider })

    function OpenCodeProvider._build_command(_, query, context)
      return {
        opencode,
        "run",
        "--auto",
        "--agent",
        "build",
        "--model",
        context.model,
        query,
      }
    end

    function OpenCodeProvider._get_provider_name()
      return "OpenCodeProvider"
    end

    function OpenCodeProvider._get_default_model()
      return "openai/gpt-5.6-luna"
    end

    function OpenCodeProvider.fetch_models(callback)
      vim.system({ opencode, "models" }, { text = true }, function(obj)
        vim.schedule(function()
          if obj.code ~= 0 then
            callback(nil, "Failed to fetch models from " .. opencode)
            return
          end
          callback(vim.split(obj.stdout, "\n", { trimempty = true }), nil)
        end)
      end)
    end

    -- For logging that is to a file if you wish to trace through requests
    -- for reporting bugs, i would not rely on this, but instead the provided
    -- logging mechanisms within 99.  This is for more debugging purposes
    local cwd = vim.uv.cwd()
    local basename = vim.fs.basename(cwd)

    _99.setup({
      provider = OpenCodeProvider,
      model = "openai/gpt-5.6-luna",
      logger = {
            level = _99.DEBUG,
            path = "/tmp/" .. basename .. ".99.debug",
            print_on_error = true,
      },
      md_files = { "AGENTS.md" },
    })

    local function opts(desc)
      return { desc = desc, silent = true, remap = false }
    end

    vim.keymap.set("n", "<leader>9s", function() _99.search() end, opts("99: search"))
    vim.keymap.set("n", "<leader>9v", function() _99.vibe() end, opts("99: vibe"))
    vim.keymap.set("n", "<leader>9o", function() _99.open() end, opts("99: open last result"))
    vim.keymap.set("n", "<leader>9l", function() _99.view_logs() end, opts("99: view logs"))
    vim.keymap.set("n", "<leader>9x", function() _99.stop_all_requests() end, opts("99: stop all requests"))
    vim.keymap.set("n", "<leader>9c", function() _99.clear_previous_requests() end, opts("99: clear previous requests"))
    vim.keymap.set("v", "<leader>9v", function() _99.visual() end, opts("99: visual"))
  '';
}
