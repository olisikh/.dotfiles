{
  lint = {
    enable = true;
    lintersByFt = {
      javascript = [ "eslint_d" ];
      typescript = [ "eslint_d" ];
      javascriptreact = [ "eslint_d" ];
      typescriptreach = [ "eslint_d" ];
      json = [ "jsonlint" ];
      yaml = [ "yamllint" ];
      dockerfile = [ "hadolint" ];
      terraform = [ "tflint" ];
      python = [ "pylint" ];
      java = [ "checkstyle" ];
    };
  };
}
