{ config, pkgs, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud35;
    hostName = "192.168.1.9";
    https = false; # only lan
    extraAppsEnable = true;
    
    config = {
      dbtype = "pgsql";
      dbhost = "localhost:/run/postgresql"; # Fixes PostgreSQL password authentication
      adminuser = "admin";
      adminpassFile = "/etc/nixos/nextcloud-admin-pass";
    };

    configureRedis = true;
  };
}