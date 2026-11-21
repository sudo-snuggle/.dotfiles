{ pkgs, ... }:

{
  virtualisation.docker.enable = true;

  systemd.services.docker-volume-gow-games = {
    description = "Create gow-games Docker volume";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker volume inspect gow-games >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker volume create gow-games
    '';
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      wolf = {
        image = "ghcr.io/games-on-whales/wolf:stable";
        environment.WOLF_SOCKET_PATH = "/var/run/wolf/wolf.sock";
        extraOptions = [
          "--network=host"
          "--device=/dev/dri"
        ];
        volumes = [
          "/etc/wolf:/etc/wolf:rw"
          "/var/run/docker.sock:/var/run/docker.sock:rw"
          "/var/run/wolf:/var/run/wolf:rw"
        ];
      };

      wolf-den = {
        image = "ghcr.io/games-on-whales/wolf-den:stable";
        ports = [ "8080:8080" ];
        environment.WOLF_SOCKET_PATH = "/var/run/wolf/wolf.sock";
        volumes = [
          "/var/run/wolf:/var/run/wolf:rw"
          "/etc/wolf/wolf-den:/app/wolf-den:rw"
        ];
      };
    };
  };
}