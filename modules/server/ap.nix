{ config, pkgs, ... }:

let
  wanIf = "wlp9s0"; # Upstream Wi-Fi (already connected)
  apIf = "ap0";     # Virtual AP interface created on wlp9s0
  rate = "600kbit";
in
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernelModules = [ "ifb" ];

  environment.systemPackages = with pkgs; [
    iw
    iproute2
    hostapd
    dnsmasq
  ];

  # Create virtual AP interface ap0 on wlp9s0 before hostapd starts
  systemd.services.zoom-ap-iface = {
    description = "Create virtual AP interface ${apIf} on ${wanIf}";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [ "hostapd.service" "dnsmasq.service" "AP.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "create-ap-iface" ''
        set -euo pipefail
        ${pkgs.iw}/bin/iw dev ${apIf} del 2>/dev/null || true
        ${pkgs.iw}/bin/iw dev ${wanIf} interface add ${apIf} type __ap
        ${pkgs.iproute2}/bin/ip addr add 10.42.0.1/24 dev ${apIf} 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link set dev ${apIf} up
      '';
      ExecStop = pkgs.writeShellScript "remove-ap-iface" ''
        ${pkgs.iproute2}/bin/ip link set dev ${apIf} down 2>/dev/null || true
        ${pkgs.iw}/bin/iw dev ${apIf} del 2>/dev/null || true
      '';
    };
  };

  services.hostapd = {
  enable = true;
  radios.${apIf} = {
    band = "2g";
    channel = 6;
    networks.${apIf} = {
      ssid = "nix_acess_point";
      authentication = {
        mode = "wpa2-sha1";
        wpaPassword = "change-this-password";
      };
    };
  };
};

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = apIf;
      bind-interfaces = true;
      dhcp-range = "10.42.0.10,10.42.0.100,255.255.255.0,12h";
      dhcp-option = [ "option:router,10.42.0.1" "option:dns-server,10.42.0.1" ];
    };
  };

  # NAT AP subnet (10.42.0.x) out through wlp9s0
  networking.nat = {
    enable = true;
    externalInterface = wanIf;
    internalInterfaces = [ apIf ];
  };

  networking.firewall = {
    enable = true;
    interfaces.${apIf}.allowedUDPPorts = [ 53 67 ];
    interfaces.${apIf}.allowedTCPPorts = [ 53 ];
  };

  # Toggleable 600kbit cap on ap0 (unit: AP.service)
  systemd.services.AP = {
    description = "Limit nix_acess_point (${apIf}) traffic to ${rate}";
    after = [ "zoom-ap-iface.service" "hostapd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ap-limit-start" ''
        set -euo pipefail
        ${pkgs.iproute2}/bin/ip link add ifb-zoom type ifb 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link set dev ifb-zoom up

        # Egress on ap0 = traffic sent to Zoom client (download)
        ${pkgs.iproute2}/bin/tc qdisc replace dev ${apIf} root cake bandwidth ${rate} nat

        # Ingress on ap0 = traffic sent by Zoom client (upload)
        ${pkgs.iproute2}/bin/tc qdisc replace dev ${apIf} ingress
        ${pkgs.iproute2}/bin/tc filter add dev ${apIf} parent ffff: protocol all u32 match u32 0 0 action mirred egress redirect dev ifb-zoom
        ${pkgs.iproute2}/bin/tc qdisc replace dev ifb-zoom root cake bandwidth ${rate} nat
      '';
      ExecStop = pkgs.writeShellScript "ap-limit-stop" ''
        ${pkgs.iproute2}/bin/tc qdisc del dev ${apIf} root 2>/dev/null || true
        ${pkgs.iproute2}/bin/tc qdisc del dev ${apIf} ingress 2>/dev/null || true
        ${pkgs.iproute2}/bin/tc qdisc del dev ifb-zoom root 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link del dev ifb-zoom 2>/dev/null || true
      '';
    };
  };
}