{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    
    settings = {
      font_family = "monospace";
      font_size = 11.0;
      
      # Map physical Alt (Control after swap) to copy and paste
      map = ''
        ctrl+c copy_or_interrupt
        ctrl+v paste_from_clipboard
        ctrl+shift+c copy_to_clipboard
        ctrl+shift+v paste_from_clipboard
      '';

      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
    };
  };
}