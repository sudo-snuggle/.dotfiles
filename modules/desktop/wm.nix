{ config, lib, pkgs, inputs, ... }:

{
  # ==========================================
  # COMMENTED OUT PREVIOUS CONFIGURATION
  # ==========================================

  # # Display manager
  # 
  # 
  # services.displayManager.defaultSession = lib.mkForce "sway";
  # 
  # # Desktop environments
  # services.desktopManager.cosmic.enable = true;
  # services.desktopManager.pantheon.enable = true;
  # 
  # # X11 infrastructure for desktop environments
  # services.xserver = {
  #   enable = true;
  #   windowManager.i3.enable = true;
  #   windowManager.dwm.enable = true;
  # 
  # displayManager.lightdm.enable = true;
  # 
  # };
  # 
  # # Sway 
  # programs.sway = {
  #   enable = true;
  #   wrapperFeatures.gtk = true;
  # };
  # 
  # # Niri + iNiR
  # programs.niri.enable = true;
  # 
  # # Hyprland + Caelestia
  # programs.hyprland.enable = true;


  # ==========================================
  # ACTIVE CONFIGURATION (Sway, Ly, GNOME)
  # ==========================================

  # Display Manager
  services.displayManager.ly.enable = true;


  # X11 / Desktop Infrastructure for GNOME
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;

  # Sway Window Manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
}