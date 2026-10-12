{ config, pkgs, ... }:

{
  services.nextcloud = {
    enable = true;
    # Use standard stable package (or pkgs.nextcloud30 / pkgs.nextcloud31 depending on channel)
    package = pkgs.nextcloud; 
    hostName = "192.168.1.9";
    https = false; # LAN only

    # Enable extra default apps like Contacts and Calendar
    extraAppsEnable = true;

    # PostgreSQL configuration
    database.createLocally = true;
    
    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/etc/nixos/nextcloud-admin-pass";
    };

    # Redis caching for high performance
    configureRedis = true;

    # Fix trusted domains for local Wi-Fi IP access
    settings = {
      trusted_domains = [ "192.168.1.9" ];
    };
  };

  # Open HTTP port in Firewall for LAN access
  networking.firewall.allowedTCPPorts = [ 80 ];
}