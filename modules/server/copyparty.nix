{ config, pkgs, ... }:

{
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.copyparty = {
    image = "copyparty/ac:latest";
    containerName = "copyparty";
    restartPolicy = "unless-stopped";
    ports = [
      "130:3923"
    ];
    volumes = [
      "/home/yasiru:/w:rw"
      # Use string interpolation for the path so Nix can append the container path and mode
      "${./.}/../../config/copyparty.conf:/cfg/copyparty.conf:ro"
    ];
  };
}