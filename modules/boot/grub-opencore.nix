{ config, lib, pkgs, ... }:

{
  boot.loader.timeout = 0;

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

  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"
    "8250.nr_uarts=0"
  ];

  # Lean stage-1 initrd tuned for speed
  boot.initrd = {
    systemd.enable = true;
    includeDefaultModules = false;
    availableKernelModules = [ 
      "ahci"         
      "libahci"      
      "libata"       
      "sd_mod"       
      "xhci_pci"     
      "i915"         
      "ext4"         
      "atkbd"        
      "hid_generic"  
      "usbhid"       
    ];
  };

  # Bypass heavy udev UUID lookup safely without modifying hardware-configuration.nix
  fileSystems."/".device = lib.mkForce "/dev/disk/by-partlabel/nixos";

  # Asynchronous network bring-up
  systemd.services.NetworkManager-wait-online.enable = false;

  # Parallelize or streamline firewall startup
  networking.firewall.allowPing = true;
}