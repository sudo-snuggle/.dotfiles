{ config, pkgs, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud35;
    hostName = "192.168.1.9";
    https = false; # LAN only
    extraAppsEnable = true;

    database.createLocally = true;

    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/etc/nixos/nextcloud-admin-pass";
    };

    configureRedis = true;
  };
}
