{ config, lib, pkgs, ... }:

{
  # Force TTY boot, no display manager
  services.xserver.enable = false;
  services.desktopManager.plasma6.enable = lib.mkForce false;
  services.displayManager.sddm.enable = lib.mkForce false;
  systemd.defaultUnit = lib.mkForce "multi-user.target";

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    LidSwitchIgnoreInhibited = "yes";
  };

  systemd.services.turn-off-screen = {
    description = "Turn off laptop display backlight on boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-user-sessions.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.brightnessctl}/bin/brightnessctl set 0";
    };
  };
}