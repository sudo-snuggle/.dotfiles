
{ config, lib, pkgs, inputs, ... }:

{
  # Display manager
  services.displayManager.ly.enable = true;

  services.displayManager.defaultSession = lib.mkForce "sway";

  # Desktop environments
  services.desktopManager.cosmic.enable = true;
  services.desktopManager.pantheon.enable = true;

  # X11 infrastructure for desktop environments
  services.xserver = {
    enable = true;
    windowManager.i3.enable = true;
    windowManager.dwm.enable = true;
  };

  # Sway 
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # Niri + iNiR
  programs.niri.enable = true;

  # Hyprland + Caelestia
  programs.hyprland.enable = true;
}
