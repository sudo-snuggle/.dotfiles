{ pkgs, ... }:

let
  # Adjust these to match your network setup
  lanSubnet = "192.168.1.0/24"; 
  wanInterface = "enp3s0"; 
in
{
  # Ensure nftables is enabled
  networking.nftables.enable = true;

  # --- BLOCK WAN SERVICE & TIMER ---
  systemd.services.wan-block = {
    description = "Block outbound WAN traffic while preserving local LAN access";
    script = ''
      # Clear existing rules in our custom table if present
      ${pkgs.nftables}/bin/nft delete table inet wan_block 2>/dev/null || true
      
      # Create table and output hook
      ${pkgs.nftables}/bin/nft add table inet wan_block
      ${pkgs.nftables}/bin/nft add chain inet wan_block output { type filter hook output priority 0 \; }
      
      # Allow local loopback traffic
      ${pkgs.nftables}/bin/nft add rule inet wan_block output oifname "lo" accept
      
      # Allow local LAN traffic
      ${pkgs.nftables}/bin/nft add rule inet wan_block output ip daddr ${lanSubnet} accept
      
      # Drop all other outbound internet traffic on physical interface
      ${pkgs.nftables}/bin/nft add rule inet wan_block output oifname "${wanInterface}" drop
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.wan-block = {
    description = "Timer to block WAN at 7:00 AM";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 07:00:00";
      Persistent = true;
    };
  };

  # --- UNBLOCK WAN SERVICE & TIMER ---
  systemd.services.wan-unblock = {
    description = "Restore full outbound internet access";
    script = ''
      # Remove the custom nftables rule table to unblock WAN
      ${pkgs.nftables}/bin/nft delete table inet wan_block 2>/dev/null || true
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.wan-unblock = {
    description = "Timer to unblock WAN at 12:10 AM";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 00:10:00";
      Persistent = true;
    };
  };
}