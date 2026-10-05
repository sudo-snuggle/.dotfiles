{ config, pkgs, ... }:

{
  programs.foot = {
    enable = true;
    settings = {
      key-bindings = {
        clipboard-copy = "Control+c Control+Shift+c";
        clipboard-paste = "Control+v Control+Shift+v";
      };
    };
  };
}