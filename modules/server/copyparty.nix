{ config, pkgs, ... }:

{

virtualisation.oci-containers.backend = "docker";

virtualisation.oci-containers.containers.copyparty = {
image = "docker.io/copyparty/ac:latest";    ports = [
      "130:3923"
    ];
    volumes = [
      "/home/yasiru/Documents:/w/Documents:rw"
      "/home/yasiru/Downloads:/w/Downloads:rw"
      "/home/yasiru/Music:/w/Music:rw"
      "/home/yasiru/Pictures:/w/Pictures:rw"
      "/home/yasiru/Videos:/w/Videos:rw"
      "/home/yasiru/.dotfiles:/w/.dotfiles:rw"
    ];
    cmd = [
      "-v"
      "/w::rwmd"
    ];
  };


virtualisation.oci-containers.containers.pinchflat = {
  image = "ghcr.io/kieraneglin/pinchflat:latest";
  ports = [ "190:8945" ];
 volumes = [
    "/home/yasiru/docker/pinchflat-config:/config"
    "/home/yasiru/Videos/channels:/downloads"
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
    "/home/yasiru/Videos/avg:/media:rw"
    "/home/yasiru/Videos/360:/360:rw"
    "/home/yasiru/Videos/channels:/channels:rw"
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
      "/home/yasiru/Videos/avg:/downloads"
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
      NET_ADMIN = true;
      NET_RAW = true;
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


virtualisation.oci-containers.containers.silverbullet = {
    image = "ghcr.io/silverbulletmd/silverbullet:latest"; #
    ports = [
      "250:3000" #
    ];
    volumes = [
      "/home/yasiru/docker/silverbullet/space:/space" #
    ];
    #  uncomment to require a login
    # environment = {
    #   SB_USER = "yasiru:-password";
    # };
  };


virtualisation.oci-containers.containers.lidarr = {
    image = "lscr.io/linuxserver/lidarr:latest";
    autoStart = true;
    ports = [ "8686:8686" ];
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "Asia/Colombo";
    };
    volumes = [
      "/var/lib/lidarr/config:/config"
      "/home/yasiru/Downloads:/Downloads"
      "/home/yasiru/Music:/Music"
      
    ];
  };

virtualisation.oci-containers.containers.siyuan = {
    image = "b3log/siyuan:latest";
    autoStart = true;
    ports = [ "6806:6806" ];
    environment = {
      TZ = "Asia/Colombo";
      PUID = "1000";
      PGID = "1000";
      # Pass configuration via environment variables instead of command-line flags
      SIYUAN_ACCESS_AUTH_CODE = "change-this-to-your-password";
      SIYUAN_WORKSPACE = "/siyuan/workspace";
    };
    volumes = [
      "/var/lib/siyuan/workspace:/siyuan/workspace"
    ];
  };

  
  virtualisation.oci-containers.containers.qbittorrent = {
    image = "lscr.io/linuxserver/qbittorrent:latest";
    autoStart = true;
    ports = [
      "260:8080"
      "6881:6881"
      "6881:6881/udp"
    ];
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "Asia/Colombo";
      WEBUI_PORT = "8080";
    };
    volumes = [
      "/var/lib/qbittorrent/config:/config"
      "/home/yasiru/Downloads:/Downloads"
      "/home/yasiru/Music:/Music"
      
    ];
  };

  networking.firewall.allowedTCPPorts = [ 8080 6881 ];
  networking.firewall.allowedUDPPorts = [ 6881 ];



  systemd.services.init-nextcloud-network = {
    description = "Create Docker network for Nextcloud";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect nextcloud-net >/dev/null 2>&1 || \
      ${pkgs.docker}/bin/docker network create nextcloud-net
    '';
  };

  virtualisation.oci-containers.containers = {
    nextcloud_db = {
      image = "postgres:15-alpine";
      extraOptions = [ "--network=nextcloud-net" ];
      environment = {
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        POSTGRES_PASSWORD = "local_database_password_change_me";
      };
      volumes = [
        "/var/lib/nextcloud/db:/var/lib/postgresql/data"
      ];
    };

    nextcloud = {
      image = "nextcloud:apache";
      ports = [ "6060:80" ];
      extraOptions = [ "--network=nextcloud-net" ];
      environment = {
        POSTGRES_HOST = "nextcloud_db";
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        POSTGRES_PASSWORD = "local_database_password_change_me";
        OVERWRITEPROTOCOL = "http";
      };
      volumes = [
        "/var/lib/nextcloud/data:/var/www/html"
      ];
      dependsOn = [ "nextcloud_db" ];
    };
  };


virtualisation.oci-containers = {
    containers.obsidian = {
      image = "lscr.io/linuxserver/obsidian:latest";
      autoStart = true;
      ports = [
        "3000:3000"
        "3001:3001"
      ];
      volumes = [
        "/var/lib/obsidian-config:/config"
        "/home/yasiru/Documents/obsidian:/config/vault"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "Asia/Colombo";
        #LIBVA_DRIVER_NAME = "i965";
        #LIBGL_ALWAYS_SOFTWARE = "1";
        #DRINODE = "/dev/dri/renderD128";
      };
      extraOptions = [
        "--security-opt=seccomp=unconfined"
        "--shm-size=1gb"
        #"--device=/dev/dri/renderD128:/dev/dri/renderD128"
      ];
    };
  };

{
  virtualisation.oci-containers = {
    backend = "docker";
    containers.ytptube = {
      image = "ghcr.io/arabcoders/ytptube:latest";
      autoStart = true;
      user = "1000:1000"; # Matches yasiru's UID/GID so Jellyfin/host can read downloads
      ports = [ "270:8081" ];
      volumes = [
        "/var/lib/ytptube/config:/config:rw"
        "/home/yasiru/Videos/360:/downloads:rw"
      ];
      environment = {
        TZ = "Asia/Colombo";
      };
    };
  };

  # Ensure directories exist with 1000:1000 ownership so Docker doesn't create them as root
  systemd.tmpfiles.rules = [
    "d /var/lib/ytptube/config 0755 yasiru users -"
    "d /path/to/jellyfin/yt-queue 0755 yasiru users -"
  ];

  # Open port 270 on LAN so you can queue videos from your phone or main laptop
  networking.firewall.allowedTCPPorts = [ 270 ];
}

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