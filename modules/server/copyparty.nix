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
  # Use extraOptions to pass --dns, 
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
    TZ = "Asia/Colombo"; #
  };
};

virtualisation.oci-containers.containers.odysseus = {
  image = "ghcr.io/pewdiepie-archdaemon/odysseus:latest";
  ports = [
    "230:7000"
  ];
  volumes = [
    "/home/yasiru/docker/odysseus/data:/app/data"
    "/home/yasiru/docker/odysseus/config:/app/config"
  ];
  environment = {
    TZ = "Asia/Colombo";
    AUTH_ENABLED = "true";
    # Point to your local Ollama instance
    # OLLAMA_BASE_URL = "http://127.0.0.1:11434";
  };
  extraOptions = [
    "--dns=8.8.8.8"
    "--dns=1.1.1.1"
  ];
};






  virtualisation.oci-containers.containers.syncthing = {
    image = "syncthing/syncthing:latest";
    hostname = "server-syncthing";
    ports = [
      "160:8384"
      "22000:22000/tcp"
      "22000:22000/udp"
      "21027:21027/udp"
    ];
    volumes = [
      "/home/yasiru/docker/syncthing/config:/var/syncthing/config"
      "/home/yasiru/Documents:/home/yasiru/Documents"
    ];
    environment = {
      PUID = "1000";
      PGID = "1000";
    };
  };

  virtualisation.oci-containers.containers.navidrome = {
    image = "deluan/navidrome:latest";
    ports = [
      "120:4533"
    ];
    volumes = [
      "/home/yasiru/docker/navidrome/data:/data"
      "/home/yasiru/Music:/music:ro"
    ];
    environment = {
      ND_LASTFM_ENABLED = "true";
      ND_LASTFM_APIKEY = "956a19b94112e184f4dca4a0dd015980";
      ND_LASTFM_SECRET = "6bfc4969f1942cb838e45c68feef40ca";
      ND_SCANINTERVAL = "1h";
      ND_MUSICFOLDER = "/music";
    };
  };

  virtualisation.oci-containers.containers.n8n = {
    image = "docker.n8n.io/n8nio/n8n";
    ports = [
      "150:5678"
    ];
    volumes = [
      "/home/yasiru/docker/n8n/n8n_data:/home/node/.n8n"
      "/home/yasiru/docker/n8n/data_files:/files"
      "/home/yasiru/Documents:/documents"
    ];
    environment = {
      N8N_HOST = "192.168.1.9";
      N8N_PORT = "5678";
      N8N_PROTOCOL = "http";
      NODE_ENV = "production";
      WEBHOOK_URL = "http://192.168.1.9:150/";
      N8N_SECURE_COOKIE = "false";
      NODE_FUNCTION_ALLOW_BUILTIN = "*";
      GENERIC_TIMEZONE = "Asia/Colombo";
      TZ = "Asia/Colombo";
      N8N_RESTRICT_FILE_ACCESS_TO = "/metube_data:/documents";
      N8N_DIAGNOSTICS_ENABLED = "false";
      N8N_PERSONALIZATION_ENABLED = "false";
      N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
    };
  };

  virtualisation.oci-containers.containers.metube = {
    image = "ghcr.io/alexta69/metube";
    ports = [
      "140:8081"
    ];
    volumes = [
      "/home/yasiru/Videos:/downloads"
    ];
    environment = {
      DEFAULT_OPTION_AUTO_START = "false";
      DOWNLOAD_MODE = "active";
    };
  };

  virtualisation.oci-containers.containers.homeassistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    volumes = [
      "/home/yasiru/docker/homeassistant/data:/config"
      "/etc/localtime:/etc/localtime:ro"
      "/var/run/dbus:/var/run/dbus:ro"
    ];
    extraOptions = [
      "--network=host"
      "--privileged"
      "--dns=8.8.8.8"
      "--dns=1.1.1.1"
    ];
    capabilities = {
      NET_ADMIN = "true";
      NET_RAW = "true";
    };
  };

  virtualisation.oci-containers.containers.freshrss = {
    image = "freshrss/freshrss:latest";
    ports = [
      "200:80"
    ];
    volumes = [
      "/home/yasiru/docker/freshrss/data:/var/www/FreshRSS/data"
      "/home/yasiru/docker/freshrss/extensions:/var/www/FreshRSS/extensions"
    ];
    environment = {
      TZ = "Asia/Colombo";
      CRON_MIN = "1,31";
    };
  };

  virtualisation.oci-containers.containers.dockhand = {
    image = "fnsys/dockhand:latest";
    ports = [
      "8080:3000"
    ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "/home/yasiru/docker/dockhand/data:/app/data"
    ];
  };



















#--------auto start thing ----------------------

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