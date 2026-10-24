{ config, pkgs, ... }:

{
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.copyparty = {
    image = "copyparty/ac:latest";
    ports = [
      "130:3923"
    ];
    volumes = [
      "/home/yasiru:/w:rw"
      "/home/yasiru/.dotfiles/config/copyparty.conf:/cfg/copyparty.conf:ro"
    ];
  };
}