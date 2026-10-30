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
  ports = [
    "190:8945"  # Host port 190 → Container default port 8945 (Pinchflat's default)
  ];
  volumes = [
    "/home/yasiru/docker/pinchflat-config:/config"
    "/home/yasiru/tubesync/others:/downloads/others"
    "/home/yasiru/tubesync/main:/downloads/main"
  ];
  environment = {
    TZ = "Asia/Colombo";
    # Note: Pinchflat does NOT use PUID/PGID. It runs as the user that executes the container.
    # You might need to ensure the host folders are writable by your user (yasiru).
  
  
  };

  dns = [ "8.8.8.8" "1.1.1.1" ];
};

}