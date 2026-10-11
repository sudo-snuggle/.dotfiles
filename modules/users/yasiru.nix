{ config, lib, pkgs, ... }:

{
  users.users.yasiru = {
    isNormalUser = true;
    description = "yasiru";
    extraGroups = [ "networkmanager" "wheel" ];
  };
}