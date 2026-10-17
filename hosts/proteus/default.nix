# /etc/nixos/configuration.nix — proteus (main device)

{ config, lib, pkgs, inputs, ... }:

{
    imports = [
    ./hardware-configuration.nix
    ../../modules/core/nix-settings.nix
    ../../modules/core/locale.nix
    ../../modules/desktop/wm.nix
    ../../modules/desktop/graphics.nix
    ../../modules/laptop/tlp.nix
    ../../modules/laptop/thinkfan.nix
    ../../modules/laptop/undervolt.nix
    ../../modules/boot/grub-opencore.nix
    ../../modules/desktop/steam.nix
    ../../modules/server/ai.nix
    ../../modules/desktop/appimage.nix
    ../../modules/desktop/virt.nix
    #../../modules/desktop/polkit.nix
  ];

  # ---------- boot ----------
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ---------- networking ----------
  networking.hostName = "proteus";
  networking.networkmanager.enable = true;

  # ---------- users (host-specific packages) ----------
  users.users.yasiru = {
    isNormalUser = true;
    description = "yasiru";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
    packages = with pkgs; [
      tree
      vscodium
      btop
      intel-gpu-tools
      stress-ng
      brave-origin
      
      librewolf

    ];
  };


  # ---------- shell ----------
  programs.bash = {
    enable = true;
    shellAliases = {
      fih = "fish";
    };
  };

  # ---------- VM writeback ----------
  boot.kernel.sysctl = {
    "vm.dirty_writeback_centisecs" = 1500;
    "vm.dirty_expire_centisecs" = 3000;
  };

  # ---------- packages ----------
  environment.systemPackages = with pkgs; [
    linuxPackages.cpupower
    linuxPackages.turbostat
    git
  #  tailscale
    powertop
    qbittorrent
    bottles
    lutris
    pcmanfm-qt
    gh
  ];

  # ---------- gamemode (proteus only in original) ----------
  programs.gamemode.enable = true;

  networking.firewall.allowedTCPPorts = [ 7070];

  # ---------- tailscale ----------
  #services.tailscale.enable = true;

  system.stateVersion = "26.05";
}