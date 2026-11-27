{ pkgs, ... }:

{
 

  # 2. 12:30 AM Start Timer & Service
  systemd.timers.docker-0030 = {
    description = "Start scheduled Docker containers at 12:30 AM";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 00:30:00";
      Persistent = false; # Never fire late if the server booted after 12:30 AM
      AccuracySec = "1s";
    };
  };

  systemd.services.docker-0030 = {
    description = "12:30 AM Docker start";
    after = [ "docker.service" ];
    wants = [ "docker.service" ];
    path = with pkgs; [ docker bash coreutils ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "docker-0030" ''
        set -euo pipefail

        sudo systemctl start docker-qbittorrent
        sudo systemctl start docker-pinchflat     
 '';
    };
  };

  # 3. 06:30 AM Stop Timer & Service
  systemd.timers.docker-0630 = {
    description = "Stop scheduled Docker containers at 06:30 AM";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 06:30:00";
      Persistent = false;
      AccuracySec = "1s";
    };
  };

  systemd.services.docker-0630 = {
    description = "06:30 AM Docker stop";
    after = [ "docker.service" ];
    wants = [ "docker.service" ];
    path = with pkgs; [ docker bash coreutils ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "docker-0630" ''
        set -euo pipefail

        sudo systemctl stop docker-qbittorrent
        sudo systemctl stop docker-pinchflat    
        # Add any other containers to stop at 06:30 AM
      '';
    };
  };
}