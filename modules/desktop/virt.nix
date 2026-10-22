{ config, pkgs, ... }:

{
  # Enable Libvirtd
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

  # Enable Virt-Manager GUI
  programs.virt-manager.enable = true;

  # Enable Hardware Acceleration / Graphics
  hardware.graphics.enable = true;

  # Add user to required groups for VM management and graphics access
  users.users.yasiru.extraGroups = [ "libvirtd" "video" "render" ];
}