{ config, pkgs, ... }:

let
  iconsDir = "${config.home.homeDirectory}/Downloads/icons";
  tvAppsDir = "${config.home.homeDirectory}/.local/share/tv-apps";
  factorioLaunchCmd = ''distrobox enter gaming -- "$HOME/.local/share/distrobox/gaming/GOG Games/Factorio/start.sh"'';
in
{
  home.packages = with pkgs; [
    pegasus-frontend
    swaybg # Required by Sway to render image backgrounds
    gamemode # Optional wrapper if you want gamemoderun inside launch scripts
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

  # Dummy / launcher trigger files required by Pegasus so tiles appear
  home.file."${tvAppsDir}/yt.sh".text = "";
  home.file."${tvAppsDir}/kitty.sh".text = "";
  home.file."${tvAppsDir}/feishin.sh".text = "";
  home.file."${tvAppsDir}/steam.sh".text = "";

  # Factorio wrapper: stops heavy Docker services if running, launches Distrobox Factorio,
  # and restores Docker when you exit back to Pegasus.
  home.file."${tvAppsDir}/factorio.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      DOCKER_WAS_ACTIVE=0
      if systemctl is-active --quiet docker.service; then
        DOCKER_WAS_ACTIVE=1
        sudo systemctl stop docker.service || true
      fi

      # Drop clean page cache so Factorio gets contiguous free RAM on a 4 GB box
      sync
      echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true

      cleanup() {
        if [ "$DOCKER_WAS_ACTIVE" -eq 1 ]; then
          sudo systemctl start docker.service || true
        fi
      }
      trap cleanup EXIT

      ${factorioLaunchCmd}
    '';
  };

  # Pegasus collection metadata
  home.file."${tvAppsDir}/metadata.pegasus.txt".text = ''
    collection: Apps
    launch: {file.path}

    game: YouTube
    file: yt.sh
    launch: VacuumTube --fullscreen
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
    assets.boxFront: ${iconsDir}/navidrome.jpg
    assets.tile: ${iconsDir}/navidrome.jpg
    assets.logo: ${iconsDir}/navidrome.jpg
    assets.background: ${iconsDir}/navidrome-bg.jpg

    game: Steam
    file: steam.sh
    launch: steam -tenfoot
    assets.boxFront: ${iconsDir}/steam.png
    assets.tile: ${iconsDir}/steam.png
    assets.logo: ${iconsDir}/steam.png
    assets.background: ${iconsDir}/steam-bg.jpg

    game: Factorio
    file: factorio.sh
    launch: ${tvAppsDir}/factorio.sh
    assets.boxFront: ${iconsDir}/factorio.jpg
    assets.tile: ${iconsDir}/factorio.jpg
    assets.logo: ${iconsDir}/factorio.jpg
    assets.background: ${iconsDir}/factorio-bg.jpg
  '';

  # 4. Sway Config (handles fullscreen windows & single-key app closing)
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false; # Skip sandbox validation so runtime ~/Downloads/icons/wall.jpg doesn't fail the build
    extraSessionCommands = ''
      export WLR_DRM_DEVICES=/dev/dri/card1
      export WLR_DRM_NO_ATOMIC=1
      # Avoid unnecessary XWayland overhead when running native Wayland apps/games
      export SDL_VIDEODRIVER=wayland
      export CLUTTER_BACKEND=wayland
    '';
    config = {
      modifier = "Mod4";

      # Completely disable swaybar
      bars = [];

      # Set wallpaper across all outputs with pitch-black fallback
      output."*" = {
        bg = "${iconsDir}/wall.jpg fill #000000";
      };

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