{ config, lib, pkgs, ... }:

{
  users.users.yasiru = {
    isNormalUser = true;
    description = "yasiru";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "wheel" "video" "input" "docker"];
  };


  services.seatd = {
  enable = true;
  user = "yasiru";
};
}