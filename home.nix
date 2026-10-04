{ config, pkgs, inputs, ... }:

{
  home.username = "yasiru";
  home.homeDirectory = "/home/yasiru";
  home.stateVersion = "26.05";

  # User-level packages
  home.packages = with pkgs; [
    # add user packages here later
  ];

  # Programs (we'll add more later)
  programs.home-manager.enable = true;
}
