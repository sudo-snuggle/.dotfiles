{ config, pkgs, ... }:

{
  fileSystems."/mnt/ext" = {
    device = "/dev/disk/by-uuid/7528885a-e4a8-4f29-a515-ceed08c00a87";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=10min"
    ];
  };

  virtualisation.oci-containers.backend = "docker";

  systemd.tmpfiles.rules = [
    "d /home/yasiru/docker 0755 yasiru users -"
    "d /home/yasiru/Music 0755 yasiru users -"
    "d /home/yasiru/Documents 0755 yasiru users -"
    "d /home/yasiru/Videos 0755 1000 1000 -"
    "d /home/yasiru/docker/navidrome/data 0755 yasiru users -"
    "d /home/yasiru/docker/syncthing/config 0755 yasiru users -"
    "d /home/yasiru/docker/open-webui/data 0755 yasiru users -"
    "d /home/yasiru/docker/ytptube/config 0755 1000 1000 -"
    "d /home/yasiru/docker/lidarr/config 0755 1000 1000 -"
    "d /home/yasiru/docker/siyuan/workspace 0755 1000 1000 -"
    "d /home/yasiru/docker/qbittorrent/config 0755 1000 1000 -"
    "d /home/yasiru/docker/nextcloud/db 0755 yasiru users -"
    "d /home/yasiru/docker/nextcloud/data 0755 yasiru users -"
    "d /home/yasiru/docker/selkies-config 0755 1000 1000 -"
    "d /mnt/ext/Documents 0755 yasiru users -"
    "d /mnt/ext/Documents/kiwix 0755 yasiru users -"
    "d /home/yasiru/docker/pinchtube/config 0755 1000 1000 -"
"d /home/yasiru/docker/pinchtube/cache 0755 1000 1000 -"
"d /home/yasiru/Downloads/metube 0755 1000 1000 -"
"d /home/yasiru/Music 0755 yasiru users -"
"d /home/yasiru/docker/qbittorrent/config 0755 1000 1000 -"
  "d /home/yasiru/Downloads 0755 1000 1000 -"
  "d /home/yasiru/Music 0755 1000 1000 -"
  "d /mnt/ext/torrents 0755 1000 1000 -"
  ];

  # Dedicated Docker network for media containers
  systemd.services.init-media-network = {
    description = "Create Docker network for media containers";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.docker}/bin/docker network inspect media-net >/dev/null 2>&1 || \
      ${pkgs.docker}/bin/docker network create media-net
    '';
  };

  # Dedicated Docker network for Nextcloud
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

  systemd.services.docker-navidrome.after = [ "init-media-network.service" ];

  systemd.services.docker-ytptube.preStart = ''
    mkdir -p /home/yasiru/docker/ytptube/config /home/yasiru/Videos
    chown -R 1000:1000 /home/yasiru/docker/ytptube /home/yasiru/Videos
  '';

  systemd.services.docker-kiwix = {
    after = [ "mnt-ext.mount" "mnt-ext.automount" ];
    requires = [ "mnt-ext.mount" ];
  };

  systemd.services.docker-qbittorrent = {
    after = [ "mnt-ext.mount" "mnt-ext.automount" ];
    requires = [ "mnt-ext.mount" ];
    preStart = ''
      CONF="/home/yasiru/docker/qbittorrent/config/qBittorrent/qBittorrent.conf"
      if [ -f "$CONF" ]; then
        ${pkgs.gnused}/bin/sed -i \
          -e '/^WebUI\\HostHeaderValidation=/d' \
          -e '/^WebUI\\CSRFProtection=/d' \
          -e '/^WebUI\\AuthSubnetWhitelist=/d' \
          -e '/^WebUI\\AuthSubnetWhitelistEnabled=/d' \
          -e '/^HostHeaderValidation=/d' \
          -e '/^CSRFProtection=/d' \
          -e '/^AuthSubnetWhitelist=/d' \
          -e '/^AuthSubnetWhitelistEnabled=/d' \
          -e '/^LocalHostAuth=/d' \
          "$CONF"
        if ${pkgs.gnugrep}/bin/grep -q '^\[WebUI\]' "$CONF"; then
          ${pkgs.gnused}/bin/sed -i '/^\[WebUI\]/a HostHeaderValidation=false\nCSRFProtection=false\nLocalHostAuth=false\nAuthSubnetWhitelist=192.168.1.0/24\nAuthSubnetWhitelistEnabled=true' "$CONF"
        else
          printf '\n[WebUI]\nHostHeaderValidation=false\nCSRFProtection=false\nLocalHostAuth=false\nAuthSubnetWhitelist=192.168.1.0/24\nAuthSubnetWhitelistEnabled=true\n' >> "$CONF"
        fi
      fi
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8080 6881 ];
  networking.firewall.allowedUDPPorts = [ 6881 ];

  virtualisation.oci-containers.containers = {
    copyparty = {
      image = "docker.io/copyparty/ac:latest";
      ports = [
        "130:3923"
      ];
      volumes = [
"/home/yasiru/Documents:/w/Documents:rw"
        "/home/yasiru/Downloads:/w/Downloads:rw"
        "/home/yasiru/Music:/w/Music:rw"
        "/home/yasiru/Pictures:/w/Pictures:rw"
        "/home/yasiru/Videos:/w/Videos:rw"
        "/home/yasiru/.dotfiles:/w/dotfiles:rw"
        "/mnt/ext:/w/hdd:rw"
      ];
      cmd = [
        "-v"
        "/w::rwmd"
      ];
    };

    pinchflat = {
      autoStart = false;
      image = "ghcr.io/kieraneglin/pinchflat:latest";
      ports = [ "190:8945" ];
      volumes = [
        "/home/yasiru/docker/pinchflat/config:/config"
        "/home/yasiru/Videos/channels:/downloads"
      ];
      environment = {
        TZ = "Asia/Colombo";
      };
      extraOptions = [
        "--dns=8.8.8.8"
        "--dns=1.1.1.1"
      ];
    };

    jellyfin = {
      image = "jellyfin/jellyfin:latest";
      ports = [
        "170:8096"
      ];
      volumes = [
        "/home/yasiru/docker/jellyfin/config:/config"
        "/home/yasiru/docker/jellyfin/cache:/cache"
        "/home/yasiru/Videos/avg:/media:rw"
        "/home/yasiru/Videos/360:/360:rw"
        "/home/yasiru/Videos/channels:/channels:rw"
        "/mnt/ext/movies:/movies:rw"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "Asia/Colombo";
      };
    };

    syncthing = {
      image = "syncthing/syncthing:latest";
      hostname = "server-syncthing";
      autoStart = false;
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
        PGID = "100";
      };
    };

    navidrome = {
      image = "deluan/navidrome:latest";
      ports = [ "120:4533" ];
      extraOptions = [ "--network=media-net" ];
      volumes = [
        "/home/yasiru/docker/navidrome/data:/data"
        "/home/yasiru/Music/navidrome:/navidrome"
        "/home/yasiru/Music/yasindu:/yasindu"
      ];
      environment = {
        ND_LASTFM_ENABLED = "true";
        ND_LASTFM_APIKEY = "956a19b94112e184f4dca4a0dd015980";
        ND_LASTFM_SECRET = "6bfc4969f1942cb838e45c68feef40ca";
        ND_SCANINTERVAL = "1h";
        ND_MUSICFOLDER = "/music";
        ND_ENABLEMEDIAFILECOVERART = "false";
        ND_PLUGINS_ENABLED = "true";
        ND_PLUGINS_FOLDER = "/data/plugins";
        ND_LYRICSPRIORITY = ".ttml,.elrc,.lrc,.srt,.txt,embedded,nd-lyrics";
      };
    };

    n8n = {
      autoStart = false;
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

    metube = {
      image = "ghcr.io/alexta69/metube";
      ports = [
        "140:8081"
      ];
      volumes = [
        "/home/yasiru/Downloads/metube:/downloads"
      ];
      environment = {
        DEFAULT_OPTION_AUTO_START = "false";
        DOWNLOAD_MODE = "active";
      };
    };

    homeassistant = {
      autoStart = false;
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

    freshrss = {
      image = "freshrss/freshrss:latest";
      autoStart = false;
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

    dockhand = {
      image = "fnsys/dockhand:latest";
      ports = [
        "8080:3000"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/home/yasiru/docker/dockhand/data:/app/data"
      ];
    };

    silverbullet = {
      image = "ghcr.io/silverbulletmd/silverbullet:latest";
      autoStart = false;
      ports = [
        "250:3000"
      ];
      volumes = [
        "/home/yasiru/docker/silverbullet/space:/space"
      ];
    };

    lidarr = {
      image = "lscr.io/linuxserver/lidarr:latest";
      autoStart = false;
      ports = [ "8686:8686" ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "Asia/Colombo";
      };
      volumes = [
        "/home/yasiru/docker/lidarr/config:/config"
        "/home/yasiru/Downloads:/Downloads"
        "/home/yasiru/Music:/Music"
      ];
    };

    siyuan = {
      image = "b3log/siyuan:latest";
      autoStart = false;
      ports = [ "6806:6806" ];
      environment = {
        TZ = "Asia/Colombo";
        PUID = "1000";
        PGID = "1000";
        SIYUAN_ACCESS_AUTH_CODE = "change-this-to-your-password";
        SIYUAN_WORKSPACE = "/siyuan/workspace";
      };
      volumes = [
        "/home/yasiru/docker/siyuan/workspace:/siyuan/workspace"
      ];
    };

    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      autoStart = false;
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
        "/home/yasiru/docker/qbittorrent/config:/config"
        "/home/yasiru/Downloads:/Downloads"
        "/home/yasiru/Music:/Music"
        "/mnt/ext:/hdd"
      ];
    };

    nextcloud_db = {
      image = "postgres:15-alpine";
      autoStart = false;
      extraOptions = [ "--network=nextcloud-net" ];
      environment = {
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        POSTGRES_PASSWORD = "local_database_password_change_me";
      };
      volumes = [
        "/home/yasiru/docker/nextcloud/db:/var/lib/postgresql/data"
      ];
    };

    nextcloud = {
      image = "nextcloud:apache";
      autoStart = false;
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
        "/home/yasiru/docker/nextcloud/data:/var/www/html"
      ];
      dependsOn = [ "nextcloud_db" ];
    };

    selkies = {
      image = "lscr.io/linuxserver/baseimage-selkies:ubuntunoble";
      autoStart = false;
      ports = [
        "3000:3000"
        "3001:3001"
      ];
      volumes = [
        "/home/yasiru/docker/selkies-config:/config"
        "/home/yasiru/Documents:/config/Documents"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "Asia/Colombo";
        TITLE = "Selkies";
      };
      extraOptions = [
        "--security-opt=seccomp=unconfined"
        "--shm-size=1gb"
      ];
    };

    ytptube = {
      image = "ghcr.io/arabcoders/ytptube:latest";
      autoStart = true;
      user = "1000:1000";
      ports = [ "270:8081" ];
      volumes = [
        "/home/yasiru/docker/ytptube/config:/config:rw"
        "/home/yasiru/Videos:/downloads:rw"
      ];
      environment = {
        TZ = "Asia/Colombo";
      };
      extraOptions = [
        "--dns=8.8.8.8"
        "--dns=1.1.1.1"
      ];
    };

    open-webui = {
      image = "ghcr.io/open-webui/open-webui:main";
      autoStart = true;
      ports = [ "320:8080" ];
      volumes = [
        "/home/yasiru/docker/open-webui/data:/app/backend/data"
      ];
      environment = {
        TZ = "Asia/Colombo";
        OLLAMA_BASE_URL = "http://host.docker.internal:11434";
      };
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
      ];
    };

    kiwix = {
      image = "ghcr.io/kiwix/kiwix-serve:latest";
      autoStart = true;
      ports = [ "330:8080" ];
      volumes = [
        "/mnt/ext/Documents/kiwix:/data:ro"
      ];
      cmd = [
        "*.zim"
      ];
      environment = {
        TZ = "Asia/Colombo";
      };
    };

    
pinchtube = {
  image = "ghcr.io/cosmicthing2/pinchtube:latest";
  autoStart = true;

  ports = [
    "360:8080"
  ];

  volumes = [
    "/home/yasiru/Videos/channels:/media:ro"
    "/home/yasiru/docker/pinchtube/config:/config:rw"
    "/home/yasiru/docker/pinchtube/cache:/cache:rw"
  ];

  environment = {
    PUID = "1000";
    PGID = "1000";
    TZ = "Asia/Colombo";
    SECURE_COOKIES = "auto";
    TRUST_PROXY = "false";
    LOG_LEVEL = "info";
  };
};


  };
}
