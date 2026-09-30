{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.aerospace;
  sketchybar = "${pkgs.sketchybar}/bin/sketchybar";

  # Keep the existing exact-match defaults, including Settings and emulator variants.
  defaultFloatingAppPatterns = [
    "System (Preferences|Settings)"
    "Finder"
    "Activity Monitor"
    "Archive Utility"
    "Creative Cloud"
    "Login Options"
    "ClearVPN"
    "balenaEtcher"
    "Transmission"
    "PSI Bridge Secure Browser"
    "Android Emulator.*"
  ];
  floatingAppsRegex = "^(${lib.concatStringsSep "|" (
    defaultFloatingAppPatterns
    ++ map (app: ".*${lib.escapeRegex app}.*") cfg.extra-floating-apps
  )})$";

  # Dock assignments target macOS Spaces, not AeroSpace workspaces.
  appWorkspaceRules = lib.concatLists (
    lib.imap1 (
      workspace: apps:
      lib.optional (apps != []) {
        "if".app-name-regex-substring = lib.concatStringsSep "|" (map lib.escapeRegex apps);
        check-further-callbacks = true;
        run = "move-node-to-workspace ${toString workspace}";
      }
    ) cfg.app-workspaces
  );

  workspaceBindings = lib.listToAttrs (lib.concatMap (index:
    let
      key = if index == 10 then "0" else toString index;
      workspace = toString index;
    in
    [
      { name = "ctrl-${key}"; value = "workspace ${workspace}"; }
      { name = "alt-shift-${key}"; value = "move-node-to-workspace --focus-follows-window ${workspace}"; }
    ]) (lib.range 1 10));
in
{
  options.${namespace}.apps.aerospace = {
    enable = mkBoolOpt false "Enable AeroSpace window manager";
    app-workspaces = lib.mkOption {
      type = lib.types.listOf (lib.types.listOf lib.types.nonEmptyStr);
      default = [];
      description = "One-based workspace lists of app-name substrings, escaped and combined into AeroSpace match rules.";
    };
    extra-floating-apps = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [];
      description = "Additional app-name substrings to float alongside the default floating apps.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = !config.${namespace}.apps.yabai.enable && !config.${namespace}.apps.skhd.enable;
      message = "AeroSpace must not run alongside yabai or skhd's yabai keybindings";
    }];

    services.aerospace = {
      enable = true;
      settings = {
        config-version = 2;
        # In config version 2, workspaces are not persistent unless listed explicitly.
        persistent-workspaces = map toString (lib.range 1 10);

        start-at-login = false; # nix-darwin's launch agent starts AeroSpace
        default-root-container-layout = "tiles";
        default-root-container-orientation = "auto";
        focus-follows-mouse.enabled = false;
        gaps = {
          inner.horizontal = 20;
          inner.vertical = 20;
          outer.left = 12;
          outer.right = 12;
          outer.bottom = 12;
          outer.top = 12; # Match the other edges; don't reserve yabai's external bar again.
        };

        exec-on-workspace-change = [ "/bin/bash" "-c" "${sketchybar} --trigger space_update" ];
        on-focus-changed = [ "exec-and-forget ${sketchybar} --trigger space_update" ];
        on-window-detected =
          [
            {
              "if".app-name-regex-substring = floatingAppsRegex;
              check-further-callbacks = true;
              run = "layout floating";
            }
          ]
          ++ appWorkspaceRules
          ++ [
            { run = "exec-and-forget ${sketchybar} --trigger space_update"; }
          ];

        mode.main.binding = workspaceBindings // {
          ctrl-shift-h = "focus left";
          ctrl-shift-j = "focus down";
          ctrl-shift-k = "focus up";
          ctrl-shift-l = "focus right";

          alt-shift-h = "move left";
          alt-shift-j = "move down";
          alt-shift-k = "move up";
          alt-shift-l = "move right";

          alt-shift-r = "layout --root horizontal vertical";
          alt-shift-e = "layout horizontal vertical";
          alt-shift-t = "layout floating tiling";
          ctrl-alt-shift-0 = "balance-sizes"; # alt-shift-0 moves to workspace 10
          alt-shift-f = "fullscreen";

          # The old skhd config bound alt-shift-n twice. Retain its monitor action;
          # numbered AeroSpace workspaces are created on first use.
          alt-shift-n = "move-node-to-monitor --focus-follows-window next";
          alt-shift-p = "move-node-to-monitor --focus-follows-window prev";

          alt-shift-w = "resize height +20";
          alt-shift-d = "resize width +20";
          alt-shift-s = "resize height -20";
          alt-shift-a = "resize width -20";
        };
      };
    };
  };
}
