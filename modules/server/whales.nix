{ ... }:

{
  virtualisation.docker.enable = true;

  virtualisation.oci-containers = {
    backend = "docker";
    containers.wolf = {
      image = "ghcr.io/games-on-whales/wolf:stable";
      extraOptions = [
        "--network=host"
        "--device=/dev/dri"
      ];
      volumes = [
        "/etc/wolf:/etc/wolf:rw"
        "/var/run/docker.sock:/var/run/docker.sock:rw"
      ];
    };
  };
}