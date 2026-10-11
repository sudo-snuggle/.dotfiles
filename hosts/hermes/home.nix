{ config, pkgs, inputs, ... }:

{

imports = [
    ../../home/fish.nix  
  ];


  home.username = "yasiru";
  home.homeDirectory = "/home/yasiru";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
