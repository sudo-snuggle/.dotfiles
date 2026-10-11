# /etc/nixos/immich.nix
{ config, ... }:

{
  services.immich = {
    enable = true;

    # Reachable from other devices on your LAN.
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;

    #  path 
    mediaLocation = "/var/lib/immich";
  };
}
