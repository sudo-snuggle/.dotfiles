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
  #home.file.".config/pegasus-frontend/themes/Clean-Covers".source = ./themes/Clean-Covers;

  # 2. Configure Pegasus to use Clean Covers and scan ~/.local/share/tv-apps
  home.file.".config/pegasus-frontend/settings.txt".text = ''
    general.theme: themes/Clean-Covers
    general.fullscreen: true
  '';

  home.file.".config/pegasus-frontend/game_dirs.txt".text = ''
    ${tvAppsDir}
  '';

# Dummy trigger files (required by Pegasus so the tiles show up)
  home.file."${tvAppsDir}/yt.sh".text = "";
  home.file."${tvAppsDir}/kitty.sh".text = "";
  home.file."${tvAppsDir}/feishin.sh".text = "";
  home.file."${tvAppsDir}/steam.sh".text = "";

  # Pegasus collection metadata
home.file."${tvAppsDir}/metadata.pegasus.txt".text = ''
    collection: Apps
    launch: {file.path}

    game: YouTube
    file: yt.sh
    launch: flatpak run rocks.shy.VacuumTube --fullscreen
    assets.boxFront: ${iconsDir}/yt.png
    assets.tile: ${iconsDir}/yt.png
    assets.logo: ${iconsDir}/yt.png
    assets.background: ${iconsDir}/yt-bg.jpg

    game: Terminal
    file: kitty.sh
    launch: kitty
    assets.boxFront: ${iconsDir}/kitty.jpg
    assets.tile: ${iconsDir}/kitty.jpg
    assets.logo: ${iconsDir}/kitty.jpg
    assets.background: ${iconsDir}/kitty-bg.jpg

    game: Feishin
    file: feishin.sh
    launch: feishin
    assets.boxFront: ${iconsDir}/feishin.jpg
    assets.tile: ${iconsDir}/feishin.jpg
    assets.logo: ${iconsDir}/feishin.jpg
    assets.background: ${iconsDir}/feishin-bg.jpg

    game: Steam
    file: steam.sh
    launch: steam -tenfoot
    assets.boxFront: ${iconsDir}/steam.png
    assets.tile: ${iconsDir}/steam.png
    assets.logo: ${iconsDir}/steam.png
    assets.background: ${iconsDir}/steam-bg.jpg
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