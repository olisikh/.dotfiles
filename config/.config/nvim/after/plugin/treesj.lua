local treesj = require('treesj')
local lang_utils = require('treesj.langs.utils')

treesj.setup({
  use_default_keymaps = false,
  langs = {
    scala = {
      argument_list = lang_utils.set_preset_for_args(),
      formal_parameters = lang_utils.set_preset_for_args(),
      block = lang_utils.set_preset_for_statement(),
      constructor_body = lang_utils.set_preset_for_statement(),
      array_initializer = lang_utils.set_preset_for_list(),
      annotation_argument_list = lang_utils.set_preset_for_args(),
      enum_body = lang_utils.set_preset_for_dict(),
      enum_declaration = {
        target_nodes = { 'enum_body' },
      },
      if_statement = {
        target_nodes = { 'block' },
      },
      annotation = {
        target_nodes = { 'annotation_argument_list' },
      },
      method_declaration = {
        target_nodes = { 'block' },
      },
      variable_declarator = {
        target_nodes = { 'array_initializer' },
      },
      constructor_declaration = {
        target_nodes = { 'constructor_body' },
      },
    },
  },
})

local nmap = require('helpers').nmap

nmap('U', treesj.toggle, { desc = 'treesj: toggle block' })
