{ config, pkgs, ... }:

{

i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      m17n # Provides Wijesekera, Singlish, Sayura Sinhala layouts
    ];
  };

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