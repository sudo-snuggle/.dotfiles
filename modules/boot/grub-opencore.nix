{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = false;

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;

    extraEntries = ''
      menuentry "Macos" {
        insmod part_gpt
        insmod fat
        insmod search
        insmod chain
        search --no-floppy --file --set=root /EFI/OC/OpenCore.efi
        chainloader /EFI/OC/OpenCore.efi
      }
    '';
  };

  boot.loader.efi.canTouchEfiVariables = true;
}