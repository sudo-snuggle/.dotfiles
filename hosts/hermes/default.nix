# /etc/nixos/configuration.nix
# nixos home server — hermes / ganymede

{ config, pkgs, lib, ... }:

let
  ganymedePython = pkgs.python3.withPackages (ps: with ps; [
    flask
    python-dotenv
  ]);
in


{
  imports = [
    ./hardware-configuration.nix
  ];

  # ---------- boot ----------
  boot.kernelParams = [
    "consoleblank=60"
    "button.lid_init_state=open"
  ];

  # GRUB — dual boot 
  boot.loader.grub = {
    enable = true;
    device = "nodev";            # EFI install, so no raw device
    efiSupport = true;
    useOSProber = true;          # finds Windows automatically
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # ---------- networking ----------
  networking.hostName = "hermes";
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

  # ---------- locale ----------
  time.timeZone = "Asia/Colombo";
  i18n.defaultLocale = "en_US.UTF-8";

 #------------- external hdd ----------

  fileSystems."/mnt/storage" = {
  device = "/dev/disk/by-uuid/a819b421-d355-4c1c-9220-521a3c9f919c";
  fsType = "ext4";
  options = [ "nofail" ];
  };

  # ---------- headless ----------
  services.xserver.enable = false;
  systemd.defaultUnit = lib.mkForce "multi-user.target";

  # ---------- users ----------
  users.users.yasiru = {
    isNormalUser = true;
    description = "yasiru";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # ---------- packages ----------
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    cockpit-machines
    yt-dlp
    aria2
    ffmpeg
    git
    wget
    curl
    micro
    jq
    brightnessctl
    ganymedePython
  ];

  #------------- samba -----------
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

  # ---------- screen off on boot (untouched) ----------
  systemd.services.turn-off-screen = {
     description = "Turn off laptop display backlight on boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-user-sessions.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.brightnessctl}/bin/brightnessctl set 0";
    };
  };


  # ---------- ganymede viewer ----------
  systemd.services.ganymede-viewer = {
    description = "Ganymede LAN video viewer";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      PYTHONUNBUFFERED = "1";
      VIDEO_ROOT = "/media/videos";
    };
    serviceConfig = {
      Type = "simple";
      User = "yasiru";
      Group = "users";
      WorkingDirectory = "/home/yasiru/ganymede/viewer";
      ExecStart = "${ganymedePython}/bin/python3 /home/yasiru/ganymede/viewer/app.py";
      Restart = "always";
      RestartSec = "5s";
    };
  };

  # ---------- sleep disabled (untouched) ----------
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # ---------- lid handling (FIXED) ----------
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    LidSwitchIgnoreInhibited = "yes";
  };

  # ---------- cockpit ----------
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true;
    settings = {
      WebService = {
        AllowUnauthenticated = false;
        Origins = lib.mkForce "https://100.67.243.25:9090 https://192.168.1.5:9090 http://192.168.1.4:9090 https://nixos:9090 https://localhost:9090";
      };
    };
  };
  security.pam.services.cockpit = {};

  # ---------- ssh ----------
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };
  programs.nix-ld.enable = true;

  # ---------- tailscale ----------
  services.tailscale.enable = true;

  # ---------- firewall ----------
  networking.firewall.allowedTCPPorts = [ 22 9090 5000 445 ];

  # ---------- media dirs ----------
  systemd.tmpfiles.rules = [
    "d /media/videos 0775 yasiru users -"
  ];

  # ---------- ganymede (scripts land later) ----------
  # we add the service + timer once the scripts exist

  system.stateVersion = "26.05";
}