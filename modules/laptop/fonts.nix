{ config, pkgs, ... }:

{
 fonts.packages = with pkgs; [
  lklug-sinhala
  noto-fonts
];

fonts.fontconfig.enable = true;
}