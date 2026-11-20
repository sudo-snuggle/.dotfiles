{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "02:30";
    options = "--delete-older-than 7d";
  };

  system.autoUpgrade = {
    enable = true;
    flake = "/home/yasiru/.dotfiles";
    flags = [
      "--update-input"
      "nixpkgs"
      "--update-input"
      "home-manager"
      "--commit-lock-file"
    ];
    dates = "01:30";
    randomizedDelaySec = "30min"; # Runs randomly between 01:30 and 02:00
    persistent = false;            # Never catch up on missed runs outside the window
    allowReboot = config.networking.hostName == "hermes";
    rebootWindow = {
      lower = "01:30";
      upper = "04:45";
    };  };

  programs.nix-ld.enable = true;
}