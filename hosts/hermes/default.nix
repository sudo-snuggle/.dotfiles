# /etc/nixos/configuration.nix
# nixos home server — hermes

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/nix-settings.nix
    ../../modules/core/locale.nix
    ../../modules/users/yasiru.nix
    ../../modules/boot/grub-default.nix
    ../../modules/server/cockpit.nix
    ../../modules/server/firewall.nix
    ../../modules/server/ssh.nix
    ../../modules/server/lid-off.nix
    ../../modules/server/copyparty.nix
    ../../modules/server/printing.nix
    #../../modules/server/timer.nix
    ../../modules/laptop/tlp-server.nix
    ../../modules/desktop/wm.nix
    ../../modules/desktop/appimage.nix
    ../../modules/desktop/steam.nix

  ];

  # ---------- boot & kernel ----------
  boot.kernelParams = [
    "consoleblank=60"             # Turns off screen after 60s of inactivity
    "button.lid_init_state=open"  # Ignores lid close state on startup
    "video=eDP-1:d"
    "video=HDMI-A-1:1920x1080@60"
  ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # ---------- networking ----------
  networking.hostName = "hermes";
  networking.networkmanager.enable = true;

  networking.networkmanager.ensureProfiles.profiles = {
    "Dialog 4G 454" = {
      connection = {
        id = "Dialog 4G 454";
        type = "wifi";
      };
      wifi = {
        ssid = "Dialog 4G 454";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "2fB5740B";
      };
      ipv4 = {
        method = "manual";
        address1 = "192.168.8.9/24,192.168.8.1";
        dns = "127.0.0.1;";
        ignore-auto-dns = "true";
      };
    };

    "SLT-Fiber-2.4G_e130" = {
      connection = {
        id = "SLT-Fiber-2.4G_e130";
        type = "wifi";
      };
      wifi = {
        ssid = "SLT-Fiber-2.4G_e130";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "calm6946";
      };
      ipv4 = {
        method = "manual";
        address1 = "192.168.1.9/24,192.168.1.1";
        dns = "127.0.0.1;";
        ignore-auto-dns = "true";
      };
    };
  };

  # ---------- shell & autologin ----------
  services.getty.autologinUser = "yasiru";

  programs.bash = {
    enable = true;
    shellAliases.fih = "fish";
  };

  programs.fish = {
    enable = true;
    loginShellInit = ''
      if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY" -a "$XDG_VTNR" = "1"
        exec sway
      end
    '';
  };

  users.users.yasiru.shell = pkgs.fish;

  # ---------- audio & graphics (Haswell i5-4210U) ----------
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # ---------- docker virtualisation ----------
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # ---------- packages ----------
  environment.systemPackages = with pkgs; [
    # System & hardware
    brightnessctl
    udiskie

    # CLI utilities
    curl
    wget
    git
    gh
    jq
    neovim
    kitty
    yazi
    p7zip
    unzip
    btop

    # Media & 10-foot HDMI frontend
    yt-dlp
    aria2
    ffmpeg
    cage
    moonlight-qt
    libcec
    feishin
    vacuum-tube
    jellyfin-media-player
    nwg-launchers
    distrobox
  ];

  virtualisation.podman.enable = true;

  # ---------- pi-hole dns ----------
  services.pihole-ftl = {
    enable = true;
    settings = {
      dns = {
        upstreams = [ "9.9.9.9" "1.1.1.1" ];
        listeningMode = "BIND";
        interface = "wlp9s0";
      };
    };
    lists = [
      {
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        type = "block";
        enabled = true;
        description = "StevenBlack unified";
      }
      {
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
        type = "block";
        enabled = true;
        description = "hagezi pro";
      }
    ];
  };

  services.pihole-web = {
    enable = true;
    ports = [ "7070" ];
  };

  systemd.services.pihole-ftl = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 50; # Allows up to 2 GB of compressed swap space on a 4 GB system
};



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


security.sudo.extraRules = [
    {
      users = [ "yasiru" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl start docker.service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop docker.service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  system.stateVersion = "26.05";
}