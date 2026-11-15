{ config, pkgs, ... }:

let
  iconsDir = "${config.home.homeDirectory}/Downloads/icons";
  tvAppsDir = "${config.home.homeDirectory}/.local/share/tv-apps";
in
{
  home.packages = with pkgs; [
    pegasus-frontend
  ];

  # 1. Link your local Clean-Covers folder directly (no hash or flake input needed)
  home.file.".config/pegasus-frontend/themes/Clean-Covers".source = ./themes/Clean-Covers;

  # 2. Configure Pegasus to use Clean Covers and scan ~/.local/share/tv-apps
  home.file.".config/pegasus-frontend/settings.txt".text = ''
    general.theme: themes/Clean-Covers
    general.fullscreen: true
  '';

  home.file.".config/pegasus-frontend/game_dirs.txt".text = ''
    ${tvAppsDir}
  '';

  # 3. Define your TV apps list + dummy trigger files (required by Pegasus)
  home.file."${tvAppsDir}/youtube.sh".text = "";
  home.file."${tvAppsDir}/music.sh".text = "";
  home.file."${tvAppsDir}/terminal.sh".text = "";

  home.file."${tvAppsDir}/metadata.pegasus.txt".text = ''
    collection: Apps
    launch: {file.path}

    game: YouTube
    file: youtube.sh
    launch: flatpak run rocks.shy.VacuumTube --fullscreen
    assets.boxFront: ${iconsDir}/youtube.png

    game: Music
    file: music.sh
    launch: foot -e /home/yasiru/Downloads/NaviBeat-linux-x86_64.AppImage-tui
    assets.boxFront: ${iconsDir}/music.png

    game: Terminal
    file: terminal.sh
    launch: foot
    assets.boxFront: ${iconsDir}/terminal.png
  '';

  # 4. Sway Config (handles fullscreen windows & single-key app closing)
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";

      startup = [
        { command = "pegasus-fe"; }
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
        # Smart TV Home button: kills active app, revealing Pegasus underneath
        "Mod4" = "[app_id=\"^(?!pegasus-fe).*$\"] kill";
        "XF86HomePage" = "[app_id=\"^(?!pegasus-fe).*$\"] kill";
        "XF86Back" = "[app_id=\"^(?!pegasus-fe).*$\"] kill";

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