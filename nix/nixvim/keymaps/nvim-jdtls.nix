[
  # nmap('<leader>jv', function() jdtls.extract_variable() end, { desc = 'jdtls: extract [v]ariable' })
  {
    key = "<leader>cev";
    action = ":lua require('jdtls').extract_variable()<cr>";
    mode = "n";
    options = {
      desc = "jdtls: extract [v]ariable";
    };
  }
  # nmap('<leader>jm', function() jdtls.extract_method() end, { desc = 'jdtls: extract [m]ethod' })
  {
    key = "<leader>cem";
    action = ":lua require('jdtls').extract_method()<cr>";
    mode = "n";
    options = {
      desc = "jdtls: extract [m]ethod";
    };
  }
  # nmap('<leader>jc', function() jdtls.extract_constant() end, { desc = 'jdtls: extract [c]onstant' })
  {
    key = "<leader>cec";
    action = ":lua require('jdtls').extract_constant()<cr>";
    mode = "n";
    options = {
      desc = "jdtls: extract [c]onstant";
    };
  }
  # nmap('<leader>jt', function() jdtls.pick_test() end, { desc = 'jdtls: run [t]est' })
  {
    key = "<leader>cjt";
    action = ":lua require('jdtls').pick_test()<cr>";
    mode = "n";
    options = {
      desc = "jdtls: run [t]est";
    };
  }
  # nmap('<leader>co', function() jdtls.organize_imports() end, { desc = 'jdtls: [o]rganize imports' })
  {
    key = "<leader>co";
    action = ":lua require('jdtls').organize_imports()<cr>";
    mode = "n";
    options = {
      desc = "jdtls: [o]rganize imports";
    };
  }
]
