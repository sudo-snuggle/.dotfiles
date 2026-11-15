{ pkgs, ... }:

{
  # 1. Network Printing (CUPS + Avahi)
  services.printing = {
    enable = true;
    drivers = [ pkgs.epson-escpr ];
    listenAddresses = [ "*:631" ];
    allowFrom = [
      "localhost"
      "@LOCAL"
      "192.168.8.0/24"
      "192.168.1.0/24"
    ];
    extraConf = ''
      ServerAlias *
      DefaultEncryption Never
    '';
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  # 2. Network Scanning (SANE + saned)
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.epsonscan2 ];
  };

  services.saned = {
    enable = true;
    extraConfig = ''
      data_portrange = 10000 - 10100
      192.168.8.0/24
      192.168.1.0/24
      100.64.0.0/10
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 6566 ];
    allowedTCPPortRanges = [
      { from = 10000; to = 10100; }
    ];
  };
}