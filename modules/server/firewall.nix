{ config, lib, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 80 5050 6060 7070 8080 8443 22 9090 5000 445 5984];
}