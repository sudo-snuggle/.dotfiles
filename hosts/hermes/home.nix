{ config, pkgs, inputs, ... }:

{

imports = [
    ../../home/fish.nix  
    ../../home/swaytv.nix 
  ];


  home.username = "yasiru";
  home.homeDirectory = "/home/yasiru";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  custom.swayTv = {
    enable = true;
    # Optional overrides if your HDMI port or resolution differs:
    # tvOutput = "HDMI-A-1";
    # tvMode = "1920x1080@60Hz";
    # internalOutput = "LVDS-1";
  };
}
