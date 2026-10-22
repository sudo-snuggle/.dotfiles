{ config, pkgs, ... }:

{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "monospace:size=11";
      };
      key-bindings = {
        # 'Control+c' maps to physical Alt+C with your XKB swap
        clipboard-copy = "Control+c Control+Shift+c";
        clipboard-paste = "Control+v Control+Shift+v";
      };
    };
  };
}