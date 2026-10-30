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


  virtualisation.oci-containers.containers.tubesync = {
    image = "ghcr.io/meeb/tubesync:latest";
    ports = [
      "190:4848"  # Host port 190 → Container default port 4848
    ];
    volumes = [
  "/home/yasiru/docker/tubesync-config:/config"
  "/home/yasiru/tubesync/others:/downloads/others"
  "/home/yasiru/tubesync/main:/downloads/main"
];
    environment = {
      TZ = "Asia/Colombo";  # Adjust according to your timezone
      PUID = "1000";
      PGID = "1000";
    };
  };


}