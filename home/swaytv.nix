{ config, pkgs, ... }:

let
  # Define your TV apps cleanly in one place
  tvApps = {
    youtube = {
      name = "YouTube";
      exec = "flatpak run rocks.shy.VacuumTube --fullscreen";
      icon = "youtube";
    };
    music = {
      name = "Music";
      exec = "appimage-run /home/yasiru/Downloads/NaviBeat-linux-x86_64.AppImage";
      icon = "multimedia-audio-player";
    };
    terminal = {
      name = "Terminal";
      exec = "foot";
      icon = "utilities-terminal";
    };
  };

  # Command to launch nwggrid with no search bar, no favs, large icons, and only our custom folder
  gridDir = "${config.home.homeDirectory}/.local/share/tv-apps";
  gridCmd = "nwggrid -f -g -s 128 -n 4 -d ${gridDir}";
in
{
  # 1. Install nwg-launchers and the Papirus icon theme
  home.packages = with pkgs; [
    nwg-launchers
    papirus-icon-theme
  ];

  # 2. Set GTK icon theme so icons always resolve
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # 3. Generate the custom .desktop files in ~/.local/share/tv-apps/
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
    # 4. Hide text labels and style the tiles so ONLY icons show
    ".config/nwg-launchers/nwggrid/style.css".text = ''
      window {
        background-color: #0b0f17;
      }
      button {
        background: transparent;
        border: 2px solid transparent;
        border-radius: 20px;
        padding: 28px;
        margin: 12px;
      }
      button:focus, button:hover {
        background-color: rgba(255, 255, 255, 0.1);
        border: 2px solid #38bdf8;
      }
      button label {
        font-size: 0px;
        opacity: 0;
      }
    '';
  };

  # 5. Sway Kiosk & Launcher Configuration
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";

      # Start nwggrid-server with the exact flags, then open the grid immediately
      startup = [
        { command = "nwggrid-server -f -g -s 128 -n 4 -d ${gridDir}"; }
        { command = gridCmd; }
      ];

      # Force all app windows fullscreen with zero borders
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
        # Smart TV "Home" button (Super key or remote Home button) -> closes app & returns to grid
        "Mod4" = "kill; exec ${gridCmd}";
        "XF86HomePage" = "kill; exec ${gridCmd}";
        "XF86Back" = "kill; exec ${gridCmd}";

        # Volume controls
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