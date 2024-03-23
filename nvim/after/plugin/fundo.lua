local fundo = require('fundo')
fundo.setup({
  archives_dir = os.getenv('HOME') .. '/.vim/fundo',
  limit_archives_size = 512,
})
