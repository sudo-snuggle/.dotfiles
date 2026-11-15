{ config, pkgs, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4"; # Super key

      # Start nwggrid on launch
      startup = [
        { command = "nwggrid"; }
      ];

      # Force every window fullscreen with zero borders
      window.commands = [
        {
          criteria = { app_id = ".*"; };
          command = "fullscreen enable, border none";
        }
        {
          criteria = { class = ".*"; };
          command = "fullscreen enable, border none";
        }
      ];

      keybindings = {
        # Volume down (Ctrl + < / comma)
        "ctrl+less" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "ctrl+comma" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";

        # Volume up (Ctrl + > / period)
        "ctrl+greater" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "ctrl+period" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
      };
    };
  };
}