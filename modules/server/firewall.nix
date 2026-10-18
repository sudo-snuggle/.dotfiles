{ config, lib, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 100 110 120 130 140 150 160 170 180 190 200 9090 8080 7070 6060 ];
}