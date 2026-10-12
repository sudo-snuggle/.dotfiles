# /etc/nixos/configuration.nix
# nixos home server — hermes / ganymede

{ config, pkgs, lib, ... }:

#let
#  ganymedePython = pkgs.python3.withPackages (ps: with ps; [
#    flask
#    python-dotenv
#  ]);
#in

{
     imports = [
    ./hardware-configuration.nix
    ../../modules/core/nix-settings.nix
    ../../modules/users/yasiru.nix
    ../../modules/core/locale.nix
    ../../modules/server/cockpit.nix
    ../../modules/server/samba.nix
    ../../modules/server/firewall.nix
    ../../modules/server/ssh.nix
    ../../modules/desktop/steam.nix
    ../../modules/boot/grub-default.nix
    ../../modules/server/lid-off.nix
    ../../modules/server/immich.nix
    ../../modules/server/navidrome.nix
    ../../modules/server/couchdb.nix
    .#./../modules/server/nextcloud.nix

  ];

  # ---------- boot ----------
  boot.kernelParams = [
    "consoleblank=60"
    "button.lid_init_state=open"
  ];

  # ---------- networking ----------
  networking.hostName = "hermes";
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

# ---------- shell ----------
  programs.bash = {
    enable = true;
    shellAliases = {
      fih = "fish";
    };
  };



  #------------- external hdd ----------
  #fileSystems."/mnt/storage" = {
  #device = "/dev/disk/by-uuid/a819b421-d355-4c1c-9220-521a3c9f919c";
  #fsType = "ext4";
  #options = [ "nofail" ];
  #};

  # ---------- packages ----------
  environment.systemPackages = with pkgs; [
    cockpit-machines
    yt-dlp
    aria2
    ffmpeg
    git
    wget
    curl
    micro
    jq
    brightnessctl
   # ganymedePython

    qbittorrent
    lutris
    neovim
    vscodium
    xfce.thunar
    xfce.thunar-volman
    gh
  ];

  # ---------- ganymede viewer ----------
  #systemd.services.ganymede-viewer = {
  #  description = "Ganymede LAN video viewer";
  #  wantedBy = [ "multi-user.target" ];
  #  after = [ "network.target" ];
  #  environment = {
  #    PYTHONUNBUFFERED = "1";
  #    VIDEO_ROOT = "/media/videos";
  #  };
  #  serviceConfig = {
  #    Type = "simple";
  #    User = "yasiru";
  #    Group = "users";
  #    WorkingDirectory = "/home/yasiru/ganymede/viewer";
  #    ExecStart = "${ganymedePython}/bin/python3 /home/yasiru/ganymede/viewer/app.py";
  #    Restart = "always";
  #    RestartSec = "5s";
  #  };
  #};

  # ---------- tailscale ----------
  #services.tailscale.enable = true;

  # ---------- ganymede (scripts land later) ----------
  # we add the service + timer once the scripts exist

  system.stateVersion = "26.05";
}