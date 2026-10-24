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
      # Ensure this relative path points correctly to your config file 
      ./config/copyparty.conf:/cfg/copyparty.conf:ro
    ];
  };
}