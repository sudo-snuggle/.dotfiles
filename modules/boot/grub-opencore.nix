{ config, lib, pkgs, ... }:

{
boot.loader.timeout = 0;

  # Enable systemd-boot and disable GRUB
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
    
    extraEntries = {
      "macos.conf" = ''
        title macOS (OpenCore)
        efi /EFI/OC/OpenCore.efi
      '';
    };
  };

  boot.loader.efi.canTouchEfiVariables = true;
}