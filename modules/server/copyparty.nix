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
    ];
    # Tell Copyparty to share /w directly via command line arguments since there's no config file
    cmd = [
      "-v", "/w::rwm"
    ];
  };
}