{ config, pkgs, lib, ... }:

{
  wayland.windowManager.sway = {
    enable = true;

    # Correct location for xwayland flag:
    xwayland = false;

    # Stripped GTK wrapper feature to save startup overhead / D-Bus hooks
    # wrapperFeatures.gtk = true;
    wrapperFeatures.gtk = false;

    config = {
      output = {
        "eDP-1" = {
          mode = "1920x1080@47.999Hz";
          scale = "1.0";
        };
        # Ditch swaybg (~8 MB RAM saved) by using solid pitch-black background
        "*" = {
          bg = "#000000 solid_color";
        };
      };

      # Physical Alt (Mod1) is your universal Command key
      modifier = "Mod1";
      terminal = "${pkgs.alacritty}/bin/alacritty";
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

      # Force nwg-displays into a centered, floating overlay window
      window.commands = [
        {
          command = "floating enable, resize set 960 640, move position center";
          criteria = { app_id = "nwg-displays"; };
        }
      ];

      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
      in lib.mkOptionDefault {
        "${mod}+Return"      = "exec ${config.wayland.windowManager.sway.config.terminal}";
        "${mod}+t"           = "exec ${config.wayland.windowManager.sway.config.terminal}";
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

        #--------------- macOS App Shortcut Equivalents (Alt + Key) ---------------
        # These map your physical Alt key to standard Ctrl actions in apps
        "${mod}+c" = "exec wtype -M ctrl c -m ctrl"; # Copy
        "${mod}+v" = "exec wtype -M ctrl v -m ctrl"; # Paste
        "${mod}+x" = "exec wtype -M ctrl x -m ctrl"; # Cut
        "${mod}+a" = "exec wtype -M ctrl a -m ctrl"; # Select All
        "${mod}+z" = "exec wtype -M ctrl z -m ctrl"; # Undo
        "${mod}+s" = "exec wtype -M ctrl s -m ctrl"; # Save

        # Screenshots
        "Print" = "exec grimshot savecopy area";
        "Shift+Print" = "exec grimshot savecopy screen";
        "Ctrl+Print" = "exec grimshot save active";

        # Audio (Pure ALSA amixer bindings if PipeWire is disabled)
        # "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        # "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        # "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        # "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        "XF86AudioMute" = "exec amixer set Master toggle";
        "XF86AudioLowerVolume" = "exec amixer set Master 5%-";
        "XF86AudioRaiseVolume" = "exec amixer set Master 5%+";
        "XF86AudioMicMute" = "exec amixer set Capture toggle";

        # Brightness
        "XF86MonBrightnessDown" =
          "exec brightnessctl --device intel_backlight set 5%-";

        "XF86MonBrightnessUp" =
          "exec brightnessctl --device intel_backlight set 5%+";

        # Display / Output Switch Overlay (F7 / XF86Display)
        "F7" = "exec nwg-displays";
        "XF86Display" = "exec nwg-displays";

        # Wi-Fi (Lightweight iwd / iwctl variant if NetworkManager is removed)
        # "XF86WLAN" = "exec nmcli radio wifi off && nmcli radio wifi on";
        "XF86WLAN" = "exec sh -c 'if iwctl device wlan0 show | grep -q \"Powered.*on\"; then iwctl device wlan0 set-property Powered off; else iwctl device wlan0 set-property Powered on; fi'";

        # F10
        "XF86Search" = "exec firefox";

        # F11
        "XF86Launch1" = "exec foot";

        # F12
        "XF86Launch2" = "exec firefox";

        #---------------my custom keybinds --------------------------------

        "Ctrl+y" = "exec bash -c 'wtype -M ctrl l -m ctrl && wtype -M ctrl c -m ctrl && sleep 0.2 && mpv \"$(wl-paste)\"'";

        # F9: Toggle SLT Fiber / Dialog 4G
        # (NetworkManager nmcli connection toggle kept for reference; iwctl variant below)
        # "XF86Tools" = "exec sh -c 'if nmcli -t -f NAME,TYPE connection show --active | grep -q \"^SLT-Fiber-2.4G_e130:802-11-wireless$\"; then nmcli connection down \"SLT-Fiber-2.4G_e130\" && nmcli connection up \"Dialog 4G 454\"; else nmcli connection down \"Dialog 4G 454\" 2>/dev/null; nmcli connection up \"SLT-Fiber-2.4G_e130\"; fi'";
"XF86Tools" = "exec sh -c 'if iwctl station wlan0 show | grep -q \"SLT-Fiber-2.4G_e130\"; then iwctl station wlan0 scan; for i in 1 2 3 4 5; do if iwctl station wlan0 get-networks | grep -q \"Dialog 4G 454\"; then break; fi; sleep 1; done; iwctl station wlan0 connect \"Dialog 4G 454\"; else iwctl station wlan0 scan; for i in 1 2 3 4 5; do if iwctl station wlan0 get-networks | grep -q \"SLT-Fiber-2.4G_e130\"; then break; fi; sleep 1; done; iwctl station wlan0 connect \"SLT-Fiber-2.4G_e130\"; fi'";      };

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
    # swaybg # Removed to save RAM (using output * bg #000000 solid_color)
    swayidle
    swaylock
    alacritty
    wtype
  ];
}
