{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../home/fish.nix  
  ];

  home.username = "yasiru";
  home.homeDirectory = "/home/yasiru";
  home.stateVersion = "26.05";

  # ---------- home manager essential packages ----------
  home.packages = with pkgs; [
    # Terminal & System Info
    kitty
    fastfetch
    ripgrep
    fd
    jq

    # Audio & Display Quick Controls
    pamixer
    brightnessctl
    wl-clipboard

    # Document & Image Viewing
    zathura
    imv
  ];

  # ---------- environment variables ----------
  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "kitty";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}