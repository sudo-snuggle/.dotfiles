
{ inputs, pkgs, ... }:

{
  imports = [
    inputs.inir.homeModules.inir
  ];

  programs.inir = {
    enable = true;
    service.compositor = "niri";
    extraPackages = [
      pkgs.niri
    ];
  };
}
