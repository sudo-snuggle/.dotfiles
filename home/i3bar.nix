{ config, pkgs, lib, ... }:

{
  programs.i3status-rust = {
    enable = true;

    bars = {
      top = {
        blocks = [

          # ============================================================
          # TIME
          # ============================================================

          {
            block = "time";
            interval = 1;
            format = " $timestamp.datetime(f:'%H:%M:%S') ";
          }

          # ============================================================
          # DATE
          # ============================================================

          {
            block = "time";
            interval = 3600;
            format = " $timestamp.datetime(f:'%Y-%m-%d') ";
          }

          # ============================================================
          # BATTERY
          # ============================================================

          {
            block = "battery";
            device = "BAT1";
            driver = "sysfs";
            interval = 10;
            format = " BAT1: $percentage ";
            charging_format = " BAT1: $percentage ⚡";
            full_format = " BAT1: $percentage ";
            missing_format = "";
          }

          {
            block = "battery";
            device = "BAT0";
            driver = "sysfs";
            interval = 10;
            format = " BAT0: $percentage ";
            charging_format = " BAT0: $percentage ⚡";
            full_format = " BAT0: $percentage ";
            missing_format = "";
          }

          # ============================================================
          # DISK
          # ============================================================

          {
            block = "disk_space";
            path = "/";
            info_type = "available";
            alert_unit = "GB";
            interval = 20;
            format = " Disk: $available.eng(w:2) ";
          }

          # ============================================================
          # RAM
          # ============================================================

          {
            block = "memory";
            interval = 5;

            # Current i3status-rust supports this placeholder.
            # This reports memory used excluding reclaimable cache/buffers.
            format = " RAM: $mem_used_percents.eng(w:2) ";

            warning_mem = 80;
            critical_mem = 95;
          }

          # ============================================================
          # CPU
          # ============================================================

          {
            block = "cpu";
            interval = 2;

            format = " CPU: $utilization ";
            info_cpu = 50;
            warning_cpu = 80;
            critical_cpu = 95;
          }

          # ============================================================
          # ETHERNET
          # ============================================================

          # Match normal Linux Ethernet interface names:
          # enp0s31f6, eno1, eth0, etc.
          {
            block = "net";
            device = "^en.*";
            interval = 2;

            format = " ETH: $ip ";
            inactive_format = " ETH: Down ";
            missing_format = " ETH: -- ";
          }

          # ============================================================
          # WIFI
          # ============================================================

          # Match:
          # wlan0
          # wlp2s0
          # wlp0s20f3
          # etc.
          {
            block = "net";
            device = "^wl.*";
            interval = 2;

            format = " WLAN: $ssid ";
            inactive_format = " WLAN: Down ";
            missing_format = " WLAN: -- ";
          }

          # ============================================================
          # POWER DRAW
          # ============================================================

              {
          block = "custom";
          shell = "sh";

          command = ''
            total=0
            found=0

            for bat in /sys/class/power_supply/BAT*; do
              [ -d "$bat" ] || continue

              if [ -r "$bat/power_now" ]; then
                value=$(cat "$bat/power_now" 2>/dev/null)

                if [ -n "$value" ]; then
                  total=$((total + value))
                  found=1
                  continue
                fi
              fi

              if [ -r "$bat/current_now" ] && [ -r "$bat/voltage_now" ]; then
                current=$(cat "$bat/current_now" 2>/dev/null)
                voltage=$(cat "$bat/voltage_now" 2>/dev/null)

                if [ -n "$current" ] && [ -n "$voltage" ]; then
                  value=$(awk \
                    -v c="$current" \
                    -v v="$voltage" \
                    'BEGIN { printf "%.0f", (c * v) / 1000000 }')

                  total=$((total + value))
                  found=1
                fi
              fi
            done

            if [ "$found" -eq 1 ]; then
              awk \
                -v power="$total" \
                'BEGIN { printf "%.1fW", power / 1000000 }'
            else
              printf "N/A"
            fi
          '';

          interval = 2;
          format = " Power: $text ";
        }
          # ============================================================
          # FAN RPM
          # ============================================================

          {
            block = "custom";
            shell = "sh";

            command = ''
              if [ -r /proc/acpi/ibm/fan ]; then
                rpm=$(awk '/^speed:/ {print $2; exit}' /proc/acpi/ibm/fan)

                if [ -n "$rpm" ]; then
                  printf "%s" "$rpm"
                else
                  printf -- "--"
                fi
              else
                printf -- "--"
              fi
            '';

            interval = 2;
            format = " Fan: $text RPM ";
          }

        ];
      };
    };
  };
}