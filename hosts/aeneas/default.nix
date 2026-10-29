{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/nix-settings.nix
    ../../modules/core/locale.nix
    ../../modules/desktop/wm.nix
    ../../modules/desktop/graphics.nix
    ../../modules/laptop/tlp.nix
    ../../modules/desktop/appimage.nix
    ../../modules/laptop/fonts.nix
  ];

  # ---------- boot ----------
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ---------- networking ----------
  networking.hostName = "aeneas";
  networking.networkmanager.enable = true;

  # ---------- audio ----------
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # ---------- users ----------
  users.users.yasiru = {
    isNormalUser = true;
    description = "yasiru";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      btop
      pavucontrol
    ];
  };

  # ---------- waydroid ----------
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;

  # ---------- shell ----------
  programs.bash = {
    enable = true;
    shellAliases = {
      fih = "fish";
    };
  };

  # ---------- power / writeback ----------
  boot.kernel.sysctl = {
    "vm.dirty_writeback_centisecs" = 1500;
    "vm.dirty_expire_centisecs" = 3000;
  };

  # ---------- essential system packages ----------
  environment.systemPackages = with pkgs; [
    git
    gh
    powertop
    pcmanfm-qt
    wlr-randr
  ];

  system.stateVersion = "26.05";
}