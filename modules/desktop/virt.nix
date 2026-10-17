{ config, pkgs, ... }:

{
virtualisation.libvirtd = {
  enable = true;
  qemu = {
    package = pkgs.qemu_kvm;
    runAsRoot = true;
    # Ensures QEMU has access to host OpenGL / VirGL backend
    swtpm.enable = true;
  };
};

# Make sure hardware graphics permissions are open for virtualization groups
hardware.opengl.enable = true;
users.users.yasiru.extraGroups = [  "video" "render" ];
}