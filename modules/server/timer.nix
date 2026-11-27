{ pkgs, ... }:

{
  systemd.timers.docker-0030 = {
    description = "Start scheduled Docker containers at 12:30 AM";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 00:30:00";
      Persistent = false;
      AccuracySec = "1s";
    };
  };

  systemd.services.docker-0030 = {
    description = "12:30 AM Docker start";
    after = [ "docker.service" ];
    wants = [ "docker.service" ];
    path = with pkgs; [ docker systemd bash coreutils ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "docker-0030" ''
        set -euo pipefail

        systemctl start docker-pinchflat
      '';
    };
  };

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
    path = with pkgs; [ docker systemd bash coreutils ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "docker-0630" ''
        set -euo pipefail

        systemctl stop docker-pinchflat
      '';
    };
  };
}