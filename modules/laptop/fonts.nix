{ config, pkgs, ... }:

{
fonts.packages = with pkgs; [
  noto-fonts
  lklug-sinhala
];

fonts.fontconfig = {
  enable = true;

  defaultFonts = {
    sansSerif = [ "Noto Sans Sinhala" ];
    serif = [ "Noto Serif Sinhala" ];
  };
};
}