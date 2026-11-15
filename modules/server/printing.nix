{ pkgs, ... }:

{
  # Network Printing (CUPS + Avahi)
  services.printing = {
    enable = true;
    drivers = [ pkgs.epson-escpr ];
    listenAddresses = [ "*:631" ];
    allowFrom = [
      "localhost"
      "192.168.8.*"   # EDIT: Change to match your local subnet (e.g. 192.168.1.0/24 range)
      #"100.*.*.*"     # Tailscale network
    ];
   extraConf = ''
      ServerAlias *
      DefaultEncryption Never
      <Location />
        Order allow,deny
        Allow localhost
        Allow 192.168.8.*
        Allow 192.168.1.*
      </Location>
      <Location /admin>
        Order allow,deny
        Allow localhost
        Allow 192.168.8.*
        Allow 192.168.1.*
      </Location>
      <Location /admin/conf>
        AuthType Default
        Require user @SYSTEM
        Order allow,deny
        Allow localhost
        Allow 192.168.8.*
        Allow 192.168.1.*
      </Location>
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
      192.168.8.0/24  # EDIT: Match your local subnet
      100.64.0.0/10   # Tailscale subnet
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 6566 ];
    allowedTCPPortRanges = [
      { from = 10000; to = 10100; }
    ];
  };
}