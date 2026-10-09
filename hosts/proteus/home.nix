
{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../home/fish.nix
    ../../home/sway.nix
    ../../home/kitty.nix
    ../../home/i3bar.nix
   # ../../home/stylix.nix
    #../../home/niri.nix
    ../../home/firefox.nix
  ];

  home.username = "yasiru";
  home.homeDirectory = "/home/yasiru";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # add user packages here later
  ];

  programs.home-manager.enable = true;
}