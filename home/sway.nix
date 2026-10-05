{ config, pkgs, lib, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = {
      # Use Alt (Mod1) or Super (Mod4) for Sway window management
      modifier = "Mod1";

      terminal = "${pkgs.kitty}/bin/kitty";
      menu = "${pkgs.fuzzel}/bin/fuzzel";

      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          # Removed xkb_options swap
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
      };

      bars = [
        {
          position = "top";
          statusCommand = "${pkgs.i3status}/bin/i3status";
         
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
  ];
}