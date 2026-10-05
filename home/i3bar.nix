{ config, pkgs, lib, ... }:

{
  programs.i3status-rust = {
    enable = true;
    bars = {
      top = {
        blocks = [
          # --- Rightmost items appear first in the list ---
          # Time with seconds (rightmost)
          {
            block = "time";
            interval = 1;
            format = " $timestamp.datetime(f:'%H:%M:%S') ";
          }

          # Date
          {
            block = "time";
            interval = 3600;
            format = " $timestamp.datetime(f:'%Y-%m-%d') ";
          }

          # BAT1 charge level
          {
            block = "battery";
            device = "BAT1";
            driver = "sysfs";
            format = " BAT1: $percentage ";
          }

          # BAT0 charge level
          {
            block = "battery";
            device = "BAT0";
            driver = "sysfs";
            format = " BAT0: $percentage ";
          }

          # Disk usage
          {
            block = "disk_space";
            path = "/";
            info_type = "available";
            alert_unit = "GB";
            format = " Disk: $available ";
          }

          # RAM usage
          {
            block = "memory";
            format = " RAM: $used_percents ";
          }

          # CPU usage
          {
            block = "cpu";
            format = " CPU: $utilization ";
          }

          # Ethernet - always visible
          {
            block = "net";
            device = "enp0s31f6"; # Replace with your actual ethernet interface
            format = " ETH: $ip ";
            inactive_format = " ETH: Down ";
            missing_format = " ETH: -- ";
          }

          # WLAN - always visible
          {
            block = "net";
            device = "wlan0"; # Replace with your actual wireless interface
            format = " WLAN: $ssid ";
            inactive_format = " WLAN: Down ";
            missing_format = " WLAN: -- ";
          }

          # Power draw (custom block from BAT0 or BAT1)
          {
            block = "custom";
            command = "P0=$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null); P1=$(cat /sys/class/power_supply/BAT1/power_now 2>/dev/null); if [ \"${P0:-0}\" -gt 0 ]; then echo \"$(echo \"scale=1; $P0 / 1000000\" | bc)W\"; elif [ \"${P1:-0}\" -gt 0 ]; then echo \"$(echo \"scale=1; $P1 / 1000000\" | bc)W\"; else echo \"0W\"; fi";
            interval = 2;
            format = " Power: $text ";
          }

          # Fan RPM (leftmost) - reads from thinkpad_acpi
          {
            block = "custom";
            command = "awk '/^speed:/ {print $2}' /proc/acpi/ibm/fan 2>/dev/null || echo '--'";
            interval = 2;
            format = " Fan: $text RPM ";
          }
        ];
      };
    };
  };
}