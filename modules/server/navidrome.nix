{ ... }:

{
  services.navidrome = {
    enable = true;

    settings = {
      MusicFolder = "/mnt/music";
      Address = "0.0.0.0";
      Port = 4533;
    };

    openFirewall = true;
  };
}
