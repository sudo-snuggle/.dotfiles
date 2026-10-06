{ config, pkgs, ... }:

{
  programs.niri = {
    enable = true;

    settings = {
      input = {
        keyboard.xkb.layout = "us";

        touchpad = {
          tap = true;
          natural-scroll = true;
        };
      };

      layout = {
        gaps = 8;
        center-focused-column = "never";
      };

      prefer-no-csd = true;

      binds = {
        "Mod+Return".action.spawn = "kitty";
        "Mod+D".action.spawn = "fuzzel";

        "Mod+Q".action.close-window = { };

        "Mod+Left".action.focus-column-left = { };
        "Mod+Right".action.focus-column-right = { };
        "Mod+Up".action.focus-window-up = { };
        "Mod+Down".action.focus-window-down = { };

        "Mod+Shift+Left".action.move-column-left = { };
        "Mod+Shift+Right".action.move-column-right = { };

        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;

        "Mod+Shift+E".action.quit = { };
      };
    };
  };
}