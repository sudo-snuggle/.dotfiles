# /etc/nixos/immich.nix
{ ... }:

{
  services.immich = {
    enable = true;

    # Reachable from other devices on your LAN.
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;

    # Keep photos and videos here.
    mediaLocation = "/var/lib/immich";

    # Give the ML service a writable model cache.
    machine-learning.environment.HF_XET_CACHE =
      "/var/cache/immich/huggingface-xet";
  };

  # Avoid using the unwritable /var/empty as the immich user's home.
  users.users.immich = {
    home = "/var/lib/immich-home";
    createHome = true;
  };

  # Create the ML cache directory with permissions for Immich.
  systemd.tmpfiles.settings."immich-ml-cache"."/var/cache/immich/huggingface-xet".d = {
    user = "immich";
    group = "immich";
    mode = "0750";
  };
}
