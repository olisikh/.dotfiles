{ lib, config, ... }:
with lib;
let
  cfg = config.which-key;

  neovimModes = types.enum [ "n" "v" "x" "s" "o" "!" "i" "l" "c" "t" ];

  whichKeyIcon = types.submodule {
    options = {
      icon = mkOption {
        type = types.str;
        description = "Icon glyph";
      };
      color = mkOption {
        type = types.nullOr types.str;
        description = "which-key icon color name";
      };
    };
  };

  whichKeySpec = types.submodule {
    options = {
      key = mkOption {
        type = types.str;
        description = "Key sequence represented by this which-key specification";
      };
      group = mkOption {
        type = types.nullOr types.str;
        description = "Group label";
      };
      desc = mkOption {
        type = types.nullOr types.str;
        description = "Key description";
      };
      icon = mkOption {
        type = types.nullOr (types.either types.str whichKeyIcon);
        description = "Icon glyph or which-key icon configuration";
      };
      mode = mkOption {
        type = types.nullOr (types.either neovimModes (types.listOf neovimModes));
        description = "Mode or modes in which this specification applies";
      };
      hidden = mkOption {
        type = types.nullOr types.bool;
        description = "Whether to hide this specification";
      };
      proxy = mkOption {
        type = types.nullOr types.str;
        description = "Key sequence whose mappings this specification proxies";
      };
    };
  };

  dropNulls = filterAttrs (_: value: value != null);

  toWhichKeySpec = spec:
    let
      whichKeySpec = dropNulls (removeAttrs spec [ "key" ]);
      icon = whichKeySpec.icon or null;
    in
    whichKeySpec
    // optionalAttrs (builtins.isAttrs icon) { icon = dropNulls icon; }
    // { __unkeyed-1 = spec.key; };
in
{
  options.which-key.spec = mkOption {
    type = types.listOf whichKeySpec;
    default = [ ];
    description = "which-key spec contributed by keymap-owning modules";
  };

  config = {
    plugins.which-key = {
      enable = true;
      settings = {
        spec = map toWhichKeySpec (unique cfg.spec);
        spelling = {
          enabled = false;
        };
        win = {
          border = "rounded";
        };
      };
    };
  };
}
