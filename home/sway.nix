{ config, pkgs, lib, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = {
      modifier = "Control";

      terminal = "${pkgs.foot}/bin/kitty";
      menu = "${pkgs.fuzzel}/bin/fuzzel";

      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          xkb_options = "ctrl:swap_lalt_lctl";
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
          colors = {
            background = "#1a1b26";
            statusline = "#a9b1d6";
            separator  = "#414868";
            focusedWorkspace  = { background = "#7aa2f7"; border = "#7aa2f7"; text = "#15161e"; };
            activeWorkspace   = { background = "#3b4261"; border = "#3b4261"; text = "#a9b1d6"; };
            inactiveWorkspace = { background = "#1a1b26"; border = "#1a1b26"; text = "#565f89"; };
            urgentWorkspace   = { background = "#f7768e"; border = "#f7768e"; text = "#15161e"; };
          };
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