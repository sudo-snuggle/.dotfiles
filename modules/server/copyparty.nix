{ config, pkgs, ... }:

{
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.copyparty = {
    image = "copyparty/ac:latest";
    ports = [
      "130:3923"
    ];
    volumes = [
      "/home/yasiru:/w:rw"
    ];
    # Note -  spaces separate elements in nix lists, NOt commas
    cmd = [
      "-v"
      "/w::rwm"
    ];
  };


virtualisation.oci-containers.containers.pinchflat = {
  image = "ghcr.io/kieraneglin/pinchflat:latest";
  ports = [ "190:8945" ];
 volumes = [
    "/home/yasiru/docker/pinchflat-config:/config"
    "/home/yasiru/pinchflat:/downloads"
  ];
  environment = {
    TZ = "Asia/Colombo";
  };
  # Use extraOptions to pass --dns, this is the correct way for NixOS OCI
  extraOptions = [
    "--dns=8.8.8.8"
    "--dns=1.1.1.1"
  ];
};


virtualisation.oci-containers.containers.jellyfin = {
  image = "jellyfin/jellyfin:latest";
  ports = [
    "170:8096"
  ];
  volumes = [
    # 1. Config and Cache (Inside ~/docker/jellyfin)
    "/home/yasiru/docker/jellyfin/config:/config"
    "/home/yasiru/docker/jellyfin/cache:/cache"
    
    # 2. Media Folders (Read-Write)
    "/home/yasiru/Videos:/media:rw"
    "/home/yasiru/pinchflat:/pinchflat:rw"
  ];
  environment = {
    PUID = "1000";
    PGID = "1000";
    TZ = "Asia/Colombo"; # Changed from UTC to your local time
  };
};








  # 1. Tell NixOS NOT to start Pinchflat automatically on boot/rebuild
  virtualisation.oci-containers.containers.pinchflat.autoStart = false;

  # 2. Timer to START Pinchflat at 12:30 AM
  systemd.timers."pinchflat-night-start" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 00:30:00"; # Every day at 12:30 AM
      Unit = "docker-pinchflat.service";
    };
  };

  # 3. Timer to STOP Pinchflat at 7:00 AM
  systemd.timers."pinchflat-morning-stop" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 07:00:00"; # Every day at 7:00 AM
      Unit = "pinchflat-stop.service";
    };
  };

  # 4. The helper service that actually stops the container
  systemd.services."pinchflat-stop" = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.docker}/bin/docker stop pinchflat";
    };
  };


}