{ pkgs, ... }:

{
  services.couchdb = {
    enable = true;
    bindAddress = "0.0.0.0"; # Allow local network access
    port = 5984;
    adminUser = "admin";
    adminPass = "adminpw"; # password
  };

  # Open port in firewall for local network access
  networking.firewall.allowedTCPPorts = [ 5984 ];
}