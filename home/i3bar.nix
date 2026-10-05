{ config, pkgs, lib, ... }:

{
  programs.i3status-rust = {
    enable = true;
    bars = {
      top = {
        blocks = [
          # --- Left side (appears first, leftmost) ---
          # ThinkFan Status (custom command)
          {
            block = "custom";
            command = "grep '^level:' /proc/acpi/ibm/fan | awk '{print $2}' | sed 's/^/L/'";
            interval = 2;
            format = " Fan: $text ";
          }

          # Power Now (BAT0 or BAT1)
          {
            block = "custom";
            command = "P0=$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null); P1=$(cat /sys/class/power_supply/BAT1/power_now 2>/dev/null); if [ \"${P0:-0}\" -gt 0 ]; then echo \"$(echo \"scale=1; $P0 / 1000000\" | bc)W\"; elif [ \"${P1:-0}\" -gt 0 ]; then echo \"$(echo \"scale=1; $P1 / 1000000\" | bc)W\"; else echo \"0W\"; fi";
            interval = 2;
            format = " Power: $text ";
          }

          # --- Right side (appears last, rightmost) ---
          # Time (rightmost)
          {
            block = "time";
            interval = 60;
            format = " $timestamp.datetime(f:'%H:%M') ";
          }

          # Date
          {
            block = "time";
            interval = 3600;
            format = " $timestamp.datetime(f:'%Y-%m-%d') ";
          }

          # Disk Usage
          {
            block = "disk_space";
            path = "/";
            info_type = "available";
            alert_unit = "GB";
            format = " Disk: $available ";
          }

          # RAM Usage
          {
            block = "memory";
            format = " RAM: $used ";
          }

          # CPU Usage
          {
            block = "cpu";
            format = " CPU: $utilization ";
          }

          # BAT1 Charge Level
          {
            block = "battery";
            device = "BAT1";
            driver = "sysfs";
            format = " BAT1: $percentage ";
            missing_format = "";
          }

          # BAT0 Charge Level
          {
            block = "battery";
            device = "BAT0";
            driver = "sysfs";
            format = " BAT0: $percentage ";
            missing_format = "";
          }

          # Ethernet
          {
            block = "net";
            device = "enp0s31f6"; # Replace with your actual ethernet interface if different
            format = " ETH: $ip ";
            missing_format = "";
          }

          # WLAN
          {
            block = "net";
            device = "wlan0"; # Replace with your actual wireless interface if different
            format = " WLAN: $ssid ";
            missing_format = "";
          }
        ];
      };
    };
  };

  # Ensure fonts for icons are available
  home.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
  ];
}