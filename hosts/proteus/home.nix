{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../home/fish.nix
    ../../home/sway.nix
    ../../home/kitty.nix

  ];

  home.username = "yasiru";
  home.homeDirectory = "/home/yasiru";
  home.stateVersion = "26.05";

  # User-level packages
  home.packages = with pkgs; [
    # add user packages here later
  ];

  # Programs
  programs.home-manager.enable = true;
}