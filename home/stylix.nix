{ config, pkgs, lib, ... }:

{
  stylix = {
    enable = true;

    # Pick one of these:
    base16Scheme = ../../themes/pink-light.yaml;
    # base16Scheme = ../../themes/pink-dark.yaml;

    polarity = "light";  # or "dark" to match the theme
  };
}