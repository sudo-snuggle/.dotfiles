{ pkgs, ... }:

let
  navidromeAddon = pkgs.kodiPackages.buildKodiAddon {
    pname = "navidrome";
    namespace = "plugin.kodi.navidrome";
    version = "0.2.3"; # Update to match the tag you fetch

    src = pkgs.fetchFromGitHub {
      owner = "mickael-k";
      repo = "plugin.kodi.navidrome";
      rev = "v0.2.3"; # Or commit hash
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual hash after first build
    };

    propagatedBuildInputs = with pkgs.kodiPackages; [
      requests
      routing
    ];
  };
in
{
  environment.systemPackages = [
    (pkgs.kodi-wayland.withPackages (kodiPkgs: [
      kodiPkgs.jellyfin
      navidromeAddon
    ]))
  ];
}