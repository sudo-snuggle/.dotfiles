
{ ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      exec-once = [
        "caelestia shell -d"
      ];
    };
  };
}
