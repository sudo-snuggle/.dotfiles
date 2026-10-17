
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
    ../../home/inir.nix
    ../../home/caelestia.nix
    ../../home/hyprland.nix
  ];

  home.username = "yasiru";
  home.homeDirectory = "/home/yasiru";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    wtype
    freetube
    obsidian
    alacritty
    fuzzel
  ];

  programs.home-manager.enable = true;
}
