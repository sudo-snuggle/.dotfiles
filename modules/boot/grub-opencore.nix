{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = false;

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;

    extraEntries = ''
      menuentry "OpenCore" {
        insmod part_gpt
        insmod fat
        insmod search_fs_uuid
        insmod chain
        search --fs-uuid --no-floppy --set=root 0CC4-CC35
        chainloader /EFI/OC/OpenCore.efi
      }
    '';
  };

  boot.loader.efi.canTouchEfiVariables = true;
}