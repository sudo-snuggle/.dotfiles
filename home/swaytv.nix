{ config, pkgs, ... }:

let
  iconsDir = "${config.home.homeDirectory}/Downloads/icons";

  # Point each app to an exact image file inside ~/Downloads/icons/
  tvApps = {
    youtube = {
      name = "YouTube";
      exec = "flatpak run rocks.shy.VacuumTube --fullscreen";
      icon = "${iconsDir}/youtube.png";
    };
    music = {
      name = "Music";
      exec = "foot -e appimage-run /home/yasiru/Downloads/NaviBeat-linux-x86_64.AppImage-tui";      
      icon = "${iconsDir}/music.png";
    };
    terminal = {
      name = "Terminal";
      exec = "foot";
      icon = "${iconsDir}/terminal.png";
    };
  };

  gridDir = "${config.home.homeDirectory}/.local/share/tv-apps";
  gridCmd = "nwggrid -f -g -s 128 -n 4 -d ${gridDir}";
in
{
  home.packages = with pkgs; [
    nwg-launchers
  ];

  # Generate the custom .desktop files in ~/.local/share/tv-apps/
  home.file = (pkgs.lib.mapAttrs' (id: app: {
    name = ".local/share/tv-apps/${id}.desktop";
    value.text = ''
      [Desktop Entry]
      Name=${app.name}
      Exec=${app.exec}
      Icon=${app.icon}
      Type=Application
      Terminal=false
    '';
  }) tvApps) // {
    # Style the tiles and keep the app names visible & readable
    ".config/nwg-launchers/nwggrid/style.css".text = ''
      window {
        background-color: #0b0f17;
      }
      button {
        background: rgba(255, 255, 255, 0.04);
        border: 2px solid transparent;
        border-radius: 20px;
        padding: 24px;
        margin: 12px;
      }
      button:focus, button:hover {
        background-color: rgba(255, 255, 255, 0.12);
        border: 2px solid #38bdf8;
      }
      button label {
        color: #f8fafc;
        font-size: 18px;
        font-weight: bold;
        margin-top: 10px;
      }
    '';
  };

  # Sway Kiosk & Launcher Configuration
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";

      startup = [
        { command = "nwggrid-server -f -g -s 128 -n 4 -d ${gridDir}"; }
        { command = gridCmd; }
      ];

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
        "Mod4" = "kill; exec ${gridCmd}";
        "XF86HomePage" = "kill; exec ${gridCmd}";
        "XF86Back" = "kill; exec ${gridCmd}";

        "ctrl+less" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "ctrl+comma" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";

        "ctrl+greater" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "ctrl+period" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };
    };
  };
}