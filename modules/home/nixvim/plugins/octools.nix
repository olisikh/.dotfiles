{ pkgs, ... }:
let

  octools-nvim = (pkgs.vimUtils.buildVimPlugin {
    name = "octools.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "olisikh";
      repo = "octools.nvim";
      rev = "v0.0.1";
      hash = "sha256-WPUg24z0pcRRCzgWN8aGeEbUqxgAyQzeENF+FOGWbmg=";
    };
  });
in
{
  extraPlugins = [
    octools-nvim
  ];

  extraConfigLua = ''
    require("octools").setup({
      opencode_cmd = "opencode",
      model = "opencode/gpt-5.1-codex-mini",
      notify = false,
      show_fidget = true,
    })

    vim.keymap.set({ "n", "v" }, "<leader>oi", ":OcTools implement<CR>", { desc = "octools: implement at cursor" })
    vim.keymap.set({ "n", "v" }, "<leader>oC", ":OcTools cancel<CR>", { desc = "octools: cancel generation" })
  '';
}
