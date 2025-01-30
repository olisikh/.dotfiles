{ nixvimLib }: {
  codecompanion = {
    enable = true;

    settings = {
      adapters = {
        ollama = nixvimLib.mkRaw
          ''
            function()
              return require('codecompanion.adapters').extend('ollama', {
                  env = {
                      url = "http://127.0.0.1:11434",
                  },
                  schema = {
                      model = {
                          -- default = 'deepseek-r1:8b',
                        default = 'codellama:7b'
                      },
                      num_ctx = {
                          default = 32768,
                      },
                  },
              })
            end
          '';
      };
      strategies = {
        agent.adapter = "ollama";
        chat.adapter = "ollama";
        inline.adapter = "ollama";
      };
      display = {
        action_palette = {
          provider = "telescope";
        };
      };
    };
  };
}
