{ config, lib, pkgs, ... }:

let
  wanIf = "wlp9s0"; # Upstream Wi-Fi client interface (SLT-Fiber-2.4G_e130)
  apIf = "ap0";     # Virtual AP interface created on wlp9s0
  apMac = "02:b5:7d:b5:d5:99"; # Locally administered unicast MAC for ap0
  rate = "600kbit";
in
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkDefault 1;
  boot.kernelModules = [ "ifb" ];

  environment.systemPackages = with pkgs; [
    iw
    iproute2
    hostapd
  ];

  # Create virtual AP interface ap0 on wlp9s0 with a non-colliding MAC address
  systemd.services.zoom-ap-iface = {
    description = "Create virtual AP interface ${apIf} on ${wanIf}";
    after = [ "network-online.target" "wpa_supplicant.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "create-ap-iface" ''
        set -euo pipefail
        ${pkgs.iw}/bin/iw dev ${apIf} del 2>/dev/null || true
        ${pkgs.iw}/bin/iw dev ${wanIf} interface add ${apIf} type __ap addr ${apMac}
        ${pkgs.iproute2}/bin/ip addr replace 10.42.0.1/24 dev ${apIf}
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
      channel = 11; # Matches wlp9s0 active channel (2462 MHz)
      networks.${apIf} = {
        ssid = "nix_acess_point";
        authentication = {
          mode = "wpa2-sha1";
          wpaPassword = "change-this-password";
        };
      };
    };
  };

  # Prevent auto-starting hostapd before manual testing of ap0 and channel 11
  systemd.services.hostapd = {
    wantedBy = lib.mkForce [ ];
    after = [ "zoom-ap-iface.service" ];
  };

  # NAT AP subnet (10.42.0.x) out through wlp9s0
  networking.nat = {
    enable = true;
    externalInterface = wanIf;
    internalInterfaces = [ apIf ];
  };

  networking.firewall = {
    enable = true;
    interfaces.${apIf}.allowedUDPPorts = [ 67 ];
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