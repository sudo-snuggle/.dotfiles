{ config, pkgs, lib, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = {
      modifier = "Mod1";

      terminal = "${pkgs.kitty}/bin/kitty";
      menu = "${pkgs.fuzzel}/bin/fuzzel";

      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          repeat_delay = "300";
          repeat_rate = "50";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
        };
      };

      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
      in lib.mkOptionDefault {
        "${mod}+Return"      = "exec ${config.wayland.windowManager.sway.config.terminal}";
        "${mod}+d"           = "exec ${config.wayland.windowManager.sway.config.menu}";
        "${mod}+q"           = "kill";
        "${mod}+f"           = "fullscreen toggle";
        "${mod}+Shift+space" = "floating toggle";

        "${mod}+h"           = "focus left";
        "${mod}+j"           = "focus down";
        "${mod}+k"           = "focus up";
        "${mod}+l"           = "focus right";

        "${mod}+Shift+h"     = "move left";
        "${mod}+Shift+j"     = "move down";
        "${mod}+Shift+k"     = "move up";
        "${mod}+Shift+l"     = "move right";

        "${mod}+Shift+r"     = "reload";
        "${mod}+Shift+e"     = "exit";

        # --- Screenshots (grimshot) ---
        "Print"              = "exec grimshot save area";
        "Shift+Print"        = "exec grimshot save screen";
        "Ctrl+Print"         = "exec grimshot save active";

        # --- ThinkPad F1/F2 Keys ---
        # F1: Mute/unmute speakers
        "XF86AudioMute"      = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        # F2: Volume down
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        # F3 (optional, same row): Volume up
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
      };

        bars = [
      {
        position = "top";
        # Point directly at the Home Manager-generated config
        statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-top.toml";
        # ...
      }
    ];
      gaps = {
        inner = 6;
        outer = 3;
      };

      window = {
        border = 2;
        titlebar = false;
      };
    };
  };

  home.packages = with pkgs; [
    i3status
    wl-clipboard
    sway-contrib.grimshot   
  ];
}