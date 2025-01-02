{
  lint = {
    enable = true;
    lintersByFt = {
      javascript = [ "eslint_d" ];
      typescript = [ "eslint_d" ];
      json = [ "jsonlint" ];
      yaml = [ "yamllint" ];
      markdown = [ "vale" ];
      dockerfile = [ "hadolint" ];
      terraform = [ "tflint" ];
      python = [ "pylint" ];
      java = [ "checkstyle" ];
    };
  };
}
