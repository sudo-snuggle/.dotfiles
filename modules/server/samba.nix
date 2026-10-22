{ config, lib, pkgs, ... }:

{
  services.samba = {
    enable = true;

    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "NixServer Storage";
        security = "user";
      };

      storage = {
        path = "/mnt/storage";
        "read only" = "no";
        "guest ok" = "no";
        browseable = "yes";
      };

      home = {
        path = "/home/yasiru";
        "read only" = "no";
        "guest ok" = "no";
        browseable = "yes";
      };

      videos = {
        path = "/media/videos";
        "read only" = "no";
        "guest ok" = "no";
        browseable = "yes";
      };
    };
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;
}