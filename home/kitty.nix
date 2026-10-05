{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    
    settings = {
      font_family = "monospace";
      font_size = 11.0;
      
      # Standard Linux terminal clipboard shortcuts
      map = ''
        ctrl+shift+c copy_to_clipboard
        ctrl+shift+v paste_from_clipboard
      '';

      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
    };
  };
}