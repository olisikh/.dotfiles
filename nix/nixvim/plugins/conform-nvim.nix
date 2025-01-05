{
  conform-nvim = {
    enable = true;

    settings = {
      default_format_opts = {
        lsp_format = "fallback";
      };
      formatters_by_ft = {
        "_" = [ "trim_whitespace" ];
        go = [ "goimports" "gofumpt" ];
        javascript = [ "prettierd" ];
        javascriptreact = [ "prettierd" ];
        typescript = [ "prettierd" ];
        typescriptreact = [ "prettierd" ];
        java = [ "google-java-format" ];
        json = [ "jq" ];
        lua = [ "stylua" ];
        python = [ "isort" "black" ];
        rust = [ "rustfmt" ];
        sh = [ "shfmt" ];
        terraform = [ "terraform_fmt" ];
        kotlin = [ "ktlint" ];
        nix = [ "nixpkgs_fmt" ];
      };
    };
  };
}
