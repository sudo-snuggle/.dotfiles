{ config, pkgs, lib, ... }:

{
  programs.i3status-rust = {
    enable = true;

    bars = {
      top = {
        blocks = [
          # TIME: no seconds
          {
            block = "time";
            interval = 60;
            format = " $timestamp.datetime(f:'%H:%M') ";
          }

          # DATE
          {
            block = "time";
            interval = 3600;
            format = " $timestamp.datetime(f:'%Y-%m-%d') ";
          }

          # BATTERY: internal — $power shows live draw in Watts
          {
            block = "battery";
            device = "BAT0";
            driver = "sysfs";
            interval = 10;
            format = " BAT0: $percentage $power ";
            charging_format = " BAT0: $percentage $power ⚡";
            full_format = " BAT0: $percentage ";
            missing_format = "";
          }

          # BATTERY: removable — $power shows live draw in Watts
          {
            block = "battery";
            device = "BAT1";
            driver = "sysfs";
            interval = 10;
            format = " BAT1: $percentage $power ";
            charging_format = " BAT1: $percentage $power ⚡";
            full_format = " BAT1: $percentage ";
            missing_format = "";
          }

          # DISK
          {
            block = "disk_space";
            path = "/";
            info_type = "available";
            alert_unit = "GB";
            interval = 60;
            format = " Disk: $available.eng(w:2) ";
          }

          # RAM: used memory in MiB, not percentage
          {
            block = "memory";
            interval = 10;
            format = " RAM: $mem_used ";
            warning_mem = 80;
            critical_mem = 95;
          }

          # CPU
          {
            block = "cpu";
            interval = 10;
            format = " CPU: $utilization ";
            info_cpu = 50;
            warning_cpu = 80;
            critical_cpu = 95;
          }

          # ETHERNET
          {
            block = "net";
            device = "^en.*";
            interval = 10;
            format = " ETH: $ip ";
            inactive_format = " ETH: Down ";
            missing_format = " ETH: -- ";
          }

          # WIFI
          {
            block = "net";
            device = "^wl.*";
            interval = 10;
            format = " WLAN: $ssid ";
            inactive_format = " WLAN: Down ";
            missing_format = " WLAN: -- ";
          }

          # FAN RPM — 60s is plenty, fan never runs anyway
          {
            block = "custom";
            shell = "sh";
            command = ''
              if [ -r /proc/acpi/ibm/fan ]; then
                while read -r k v _; do
                  [ "$k" = "speed:" ] && { printf "%s" "$v"; exit; }
                done < /proc/acpi/ibm/fan
              fi
              printf -- "--"
            '';
            interval = 60;
            format = " Fan: $text RPM ";
          }
        ];
      };
    };
  };
}