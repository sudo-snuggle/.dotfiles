{ config, lib, pkgs, ... }:

{
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true;
    settings = {
      WebService = {
        AllowUnauthenticated = false;
        Origins = lib.mkForce "https://100.67.243.25:9090 https://192.168.1.9:9090 http://192.168.1.9:9090 https://nixos:9090 https://localhost:9090";
      };
    };
  };
  security.pam.services.cockpit = {};
}