{ config, pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    user = "yasiru";
    dataDir = "/home/yasiru/Documents"; # Or your preferred path
    configDir = "/home/yasiru/.config/syncthing";
  };
}