
{ inputs, ... }:

{
  imports = [
    inputs.stylix.homeManagerModules.stylix
  ];

  stylix = {
    enable = true;
    image = ./wallpaper.jpg;
  };
}
