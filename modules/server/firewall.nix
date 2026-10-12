{ config, lib, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 22 9090 5000 445 5984];
}