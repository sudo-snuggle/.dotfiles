{ pkgs, ... }:

let
  lanSubnet = "192.168.1.0/24"; 
  wanInterface = "wlp9s0"; # <--- Correct Wi-Fi interface name
in
{
  systemd.services.wan-block = {
    description = "Block outbound WAN traffic for host and Docker over wlp9s0";
    script = ''
      /run/current-system/sw/bin/iptables -F OUTPUT
      /run/current-system/sw/bin/iptables -F FORWARD

      # Host Outbound Rules
      /run/current-system/sw/bin/iptables -A OUTPUT -o lo -j ACCEPT
      /run/current-system/sw/bin/iptables -A OUTPUT -d ${lanSubnet} -j ACCEPT
      /run/current-system/sw/bin/iptables -A OUTPUT -o ${wanInterface} -j DROP

      # Docker Container Forward Rules
      /run/current-system/sw/bin/iptables -A FORWARD -d ${lanSubnet} -j ACCEPT
      /run/current-system/sw/bin/iptables -A FORWARD -o ${wanInterface} -j DROP
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.wan-block = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 07:00:00";
      Persistent = true;
    };
  };

  systemd.services.wan-unblock = {
    description = "Restore full outbound internet access";
    script = ''
      /run/current-system/sw/bin/iptables -F OUTPUT
      /run/current-system/sw/bin/iptables -F FORWARD
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.wan-unblock = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 00:10:00";
      Persistent = true;
    };
  };
}