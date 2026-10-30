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
    # Note -  spaces separate elements in nix lists, NOt commas
    cmd = [
      "-v"
      "/w::rwm"
    ];
  };


virtualisation.oci-containers.containers.pinchflat = {
  image = "ghcr.io/kieraneglin/pinchflat:latest";
  ports = [ "190:8945" ];
 volumes = [
    "/home/yasiru/docker/pinchflat-config:/config"
    "/home/yasiru/pinchflat:/downloads"
  ];
  environment = {
    TZ = "Asia/Colombo";
  };
  # Use extraOptions to pass --dns, this is the correct way for NixOS OCI
  extraOptions = [
    "--dns=8.8.8.8"
    "--dns=1.1.1.1"
  ];
};

}