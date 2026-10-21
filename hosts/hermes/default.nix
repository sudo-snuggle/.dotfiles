# /etc/nixos/configuration.nix
# nixos home server — hermes / ganymede

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/nix-settings.nix
    ../../modules/users/yasiru.nix
    ../../modules/core/locale.nix
    ../../modules/server/cockpit.nix
    #../../modules/server/samba.nix
    ../../modules/server/firewall.nix
    ../../modules/server/ssh.nix
    ../../modules/boot/grub-default.nix
    ../../modules/server/lid-off.nix
    #../../modules/server/immich.nix
    #../../modules/server/nextcloud.nix
    #../../modules/server/ai.nix
  ];

  # ---------- boot & kernel ----------
  boot.kernelParams = [
    "consoleblank=60"          # Turns off screen after 60s of inactivity
    "button.lid_init_state=open" # Ignores lid close state on startup
  ];

  # ---------- networking ----------
  networking.hostName = "hermes";
  networking.networkmanager.enable = true;

  # ---------- tailscale (secure mesh VPN) ----------
  # Uncomment when ready for encrypted remote access:
  # services.tailscale.enable = true;

  # ---------- shell ----------
  programs.bash = {
    enable = true;
    shellAliases = {
      fih = "fish";
    };
  };

  # ---------- docker virtualisation ----------
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

services.displayManager.ly.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ---------- essential server packages ----------
  environment.systemPackages = with pkgs; [
    # Server Management & Hardware
    cockpit-machines
    brightnessctl
    
    # CLI Utilities & Downloaders
    curl
    wget
    git
    gh
    jq
    micro
    neovim
    
    # Media Extraction & Processing
    yt-dlp
    aria2
    ffmpeg
    cage
  moonlight-qt
  libcec

  jellyfin-media-player
  kdePackages.plasma-bigscreen
  kdePackages.plasma-desktop
   
# Kodi with Jellyfin plugin pre-packaged
  (kodi.passthru.withPackages (kodiPkgs: with kodiPkgs; [
    jellyfin
  ]))

  ];

  hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [
    intel-media-driver # For Broadwell (5th gen) and newer
    intel-vaapi-driver # For Haswell (4th gen HD 4400) / older Intel GPUs
    libvdpau-va-gl
  ];
};

# 1. Ensure the host kernel allows routing/forwarding
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # 2. Declare the OpenWrt container
  virtualisation.oci-containers.containers.openwrt = {
    image = "docker.io/openwrt/openwrt:latest";
    autoStart = true;
    extraOptions = [
      "--privileged"
      "--network=host" # Gives OpenWrt direct visibility into host network interfaces
    ];
  };

#kksdd 

  # ---------- swap setup ----------
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4096; # 4GB Swapfile
    }
  ];

  system.stateVersion = "26.05";
}