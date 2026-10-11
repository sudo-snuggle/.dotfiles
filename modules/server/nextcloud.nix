{ config, pkgs, ... }:

{
services.nextcloud = {
  enable = true;
  package = pkgs.nextcloud35;
  hostName = "192.168.1.9"; # Replace  IP address
  https = false; # only lan
  autoUpdateApps = true;
  extraAppsEnable = true;
  
  config = {
    dbtype = "pgsql";
    adminuser = "admin";
    adminpassFile = "/etc/nixos/nextcloud-admin-pass";
  };

  configureRedis = true;
};}
