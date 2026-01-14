{ ... }:
{
  plugins = {
    "conform-nvim" = {
      enable = true;

      settings = {
        notify_on_error = true;
        notify_no_formatters = true;
        log_level = "info";
        default_format_opts = {
          lsp_format = "fallback";
        };
        formatters = {
          scalafmt = {
            timeout_ms = 5000;
          };
        };
        formatters_by_ft = {
          # Use the "*" filetype to run formatters on all filetypes.
          "_" = [ "trim_whitespace" ];
          go = [ "goimports" "gofumpt" ];
          scala = [ "scalafmt" ];
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
  };
}
