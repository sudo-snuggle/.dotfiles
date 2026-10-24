{ inputs, pkgs, ... }:

{
  imports = [
    inputs.ryoku.homeManagerModules.default
  ];

  programs.ryoku = {
    enable = true;
  };
}