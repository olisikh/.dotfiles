<<<<<<< HEAD
=======
{ lib, config, namespace, ... }:
let
  inherit (lib) mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;
in
{
  options.${namespace}.nixvim.plugins = {
    # AI plugins
    avante = {
      enable = mkBoolOpt true "Enable Avante plugin";
      useAI = mkBoolOpt true "Enable AI features in Avante (Claude)";
      provider = mkOption {
        type = types.enum [ "claude" "openai" "ollama" ];
        default = "claude";
        description = "AI provider to use with Avante";
      };
    };
    
    codecompanion = {
      enable = mkBoolOpt true "Enable CodeCompanion plugin";
    };
    
    copilot = {
      enable = mkBoolOpt true "Enable GitHub Copilot";
    };
    
    # LSP and completion
    lsp = {
      enable = mkBoolOpt true "Enable LSP configuration";
    };
    
    # UI plugins
    nvimTree = {
      enable = mkBoolOpt true "Enable nvim-tree file explorer";
    };
    
    telescope = {
      enable = mkBoolOpt true "Enable telescope fuzzy finder";
    };
    
    # Language specific
    rust = {
      enable = mkBoolOpt true "Enable Rust support";
    };
    
    scala = {
      enable = mkBoolOpt true "Enable Scala support";
      zioQuickfix = mkBoolOpt true "Enable ZIO quickfix plugin";
    };
    
    java = {
      enable = mkBoolOpt true "Enable Java support";
    };
  };
}
>>>>>>> Snippet

