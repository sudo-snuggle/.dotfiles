
{ config, pkgs, lib, ... }:

{
  wayland.windowManager.sway = {
    enable = true;

    wrapperFeatures.gtk = true;

    config = {
      output = {
        "eDP-1" = {
          mode = "1920x1080@47.999Hz";
        };
      };

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

      # Lock after 2 minutes.
      # Turn the display off after another 1 minute.
      # Wake the display when activity resumes.
      startup = [
        {
          command = "swayidle -w timeout 120 'swaylock -f -c 000000' timeout 180 'swaymsg \"output eDP-1 power off\"' resume 'swaymsg \"output eDP-1 power on\"' before-sleep 'swaylock -f -c 000000'";
        }
      ];

      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
      in lib.mkOptionDefault {
        "${mod}+Return"      = "exec ${config.wayland.windowManager.sway.config.terminal}";
        "${mod}+d"           = "exec ${config.wayland.windowManager.sway.config.menu}";
        "${mod}+q"           = "kill";
        "${mod}+f"           = "fullscreen toggle";
        "${mod}+Shift+space" = "floating toggle";

        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";

        "${mod}+Shift+h" = "move left";
        "${mod}+Shift+j" = "move down";
        "${mod}+Shift+k" = "move up";
        "${mod}+Shift+l" = "move right";

        "${mod}+Shift+r" = "reload";
        "${mod}+Shift+e" = "exit";

        # Screenshots
        "Print" = "exec grimshot savecopy area";
        "Shift+Print" = "exec grimshot savecopy screen";
        "Ctrl+Print" = "exec grimshot save active";

        # Audio
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

        # Brightness
        "XF86MonBrightnessDown" =
          "exec brightnessctl --device intel_backlight set 5%-";

        "XF86MonBrightnessUp" =
          "exec brightnessctl --device intel_backlight set 5%+";

        # Display/output switch
        "XF86Display" = "exec wdisplays";

        # Wi-Fi
        "XF86WLAN" =
          "exec nmcli radio wifi off && nmcli radio wifi on";

        
        # F10
        "XF86Search" = "exec firefox";

        # F11
        "XF86Launch1" = "exec foot";

        # F12
        "XF86Launch2" = "exec firefox";

        #---------------my custom keybinds --------------------------------

        "Ctrl+y" = "exec bash -c 'wtype -M ctrl l -m ctrl && wtype -M ctrl c -m ctrl && sleep 0.2 && mpv \"$(wl-paste)\"'";
          
          # F9: Toggle SLT Fiber / Dialog 4G
        "XF86Tools" =
          "exec sh -c 'if nmcli -t -f NAME,TYPE connection show --active | grep -q \"^SLT-Fiber-2.4G_e130:802-11-wireless$\"; then nmcli connection down \"SLT-Fiber-2.4G_e130\" && nmcli connection up \"Dialog 4G 454\"; else nmcli connection down \"Dialog 4G 454\" 2>/dev/null; nmcli connection up \"SLT-Fiber-2.4G_e130\"; fi'";

      };

      bars = [
        {
          position = "top";
          statusCommand =
            "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-top.toml";
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
    swaybg
    swayidle
    swaylock
  ];
}

