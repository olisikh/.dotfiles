{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.yabai;
  yabaiPkg = pkgs.yabai;
in
{
  options.${namespace}.services.yabai = {
    enable = mkBoolOpt false "Enable yabai module";
  };

  config = mkIf cfg.enable {
    services.yabai = {
      enable = true;
      config = {
        mouse_follows_focus = "off";
        window_origin_display = "default";
        window_placement = "second_child";
        window_opacity = "off";
        window_shadow = "on";
        window_opacity_duration = 0.0;
        active_window_opacity = 1.0;
        normal_window_opacity = 0.9;
        window_border = "off";
        window_border_width = 6;
        active_window_border_color = "0xff775759";
        normal_window_border_color = "0xff555555";
        insert_feedback_color = "0xffd75f5f";
        split_ratio = 0.5;
        auto_balance = "off";
        mouse_modifier = "fn";
        mouse_action1 = "move";
        mouse_action2 = "resize";
        mouse_drop_action = "swap";
        external_bar = "all:35:0";
        top_padding = 12;
        bottom_padding = 12;
        left_padding = 12;
        right_padding = 12;
        window_gap = 20;
        layout = "bsp"; # default "float" (windows are not managed)
      };

      # WARN: Yabai scription addition requires Security Integration Protection to be partially disabled.
      # 1. In OSX Recovery mode terminal (long press power button during boot) run the following command:
      # > csrutil enable --without fs --without debug --without nvram
      # 2. In normal mode enable non-Apple signed binaries:
      # > sudo nvram boot-args=-arm64e_preview_abi
      # 3. Reboot again
      enableScriptingAddition = true;
      extraConfig = ''
        sudo yabai --load-sa
        echo "yabai scripting addition loaded..."

        # apps to ignore
        yabai -m rule --add app="^System Preferences$" manage=off
        yabai -m rule --add app="^Archive Utility$" manage=off
        yabai -m rule --add app="^Creative Cloud$" manage=off
        yabai -m rule --add app="^Login Options$" manage=off
        yabai -m rule --add app="^ClearVPN$" manage=off
        yabai -m rule --add app="^balenaEtcher$" manage=off

        echo "yabai configuration loaded..."
      '';
    };

    environment.systemPath = [ "${yabaiPkg}/bin" ];
  };
}
