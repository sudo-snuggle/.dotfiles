{ config, pkgs, inputs, ... }:

{
  imports = [
    # Existing modules
    ../../home/fish.nix
    ../../home/sway.nix
    ../../home/kitty.nix
    ../../home/i3bar.nix
    # ../../home/stylix.nix
    #../../home/niri.nix
    ../../home/firefox.nix
    ../../home/mpv.nix
    #../../home/inir.nix
    #../../home/caelestia.nix
    #../../home/hyprland.nix
    #../../home/ryoku.nix
  ];

  home.username = "yasiru";
  home.homeDirectory = "/home/yasiru";
  home.stateVersion = "26.05";

  # Permanent fix: automatically backup clobbered files instead of throwing exit code 1
  home.backupFileExtension = "hm-backup";

  home.packages = with pkgs; [
    wtype
    freetube
    obsidian
    alacritty
    fuzzel

    gnome-tweaks           # Modify themes, fonts, cursor, window buttons, & startup apps
    gnome-extension-manager # Browse, search, install, and update extensions directly via GUI
    dconf-editor           # Detailed registry editing for hidden GNOME & GTK settings

  ];

  programs.home-manager.enable = true;
}