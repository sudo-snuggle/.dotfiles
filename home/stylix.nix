
{ inputs, ... }:

{
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  stylix = {
    enable = true;

    base16Scheme = {
      base00 = "#000000";
      base01 = "#111111";
      base02 = "#222222";
      base03 = "#444444";
      base04 = "#888888";
      base05 = "#cccccc";
      base06 = "#eeeeee";
      base07 = "#ffffff";
      base08 = "#ff5555";
      base09 = "#ffb86c";
      base0A = "#f1fa8c";
      base0B = "#50fa7b";
      base0C = "#8be9fd";
      base0D = "#6272a4";
      base0E = "#bd93f9";
      base0F = "#ff79c6";
    };
  };
}

