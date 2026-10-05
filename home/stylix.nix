{ inputs, ... }:

{
  imports = [
  inputs.stylix.homeModules.stylix
  ];

  stylix = {
  enable = true;
  base16Scheme = ./themes/pinky.nix;
  };
}
