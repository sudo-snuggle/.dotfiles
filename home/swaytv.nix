{ config, pkgs, ... }:

let
  iconsDir = "${config.home.homeDirectory}/Downloads/icons";
  tvAppsDir = "${config.home.homeDirectory}/.local/share/tv-apps";
in
{
  home.packages = with pkgs; [
    pegasus-frontend
  ];

  home.file.".config/pegasus-frontend/settings.txt".text = ''
    general.theme: themes/Clean-Covers
    general.fullscreen: true
  '';

  home.file.".config/pegasus-frontend/game_dirs.txt".text = ''
    ${tvAppsDir}
  '';

  # Dummy trigger files
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
    launch: flatpak run --socket=wayland rocks.shy.VacuumTube --fullscreen --ozone-platform=wayland --enable-features=UseOzonePlatform
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

  # Sway Config
  wayland.windowManager.sway = {
    enable = true;
    extraSessionCommands = ''
      export WLR_DRM_DEVICES=/dev/dri/card1
      export WLR_DRM_NO_ATOMIC=1
    '';
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
        # Win+Q (and TV Back/Home buttons): close active app (Wayland or XWayland) unless it's Pegasus
        "Mod4+q" = "[app_id=\"^(?!pegasus-fe).*$\"] kill; [class=\".*\"] kill";
        "XF86HomePage" = "[app_id=\"^(?!pegasus-fe).*$\"] kill; [class=\".*\"] kill";
        "XF86Back" = "[app_id=\"^(?!pegasus-fe).*$\"] kill; [class=\".*\"] kill";

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