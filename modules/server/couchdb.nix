{ config, lib, pkgs, ... }:

{
  services.couchdb = {
  enable = true;
  bindAddress = "0.0.0.0"; # Allow local network access
  adminParty = false;      # Secure with credentials
  port = 5984;
};
}