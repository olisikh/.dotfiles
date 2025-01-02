{
  lint = {
    enable = true;
    lintersByFt = {
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
