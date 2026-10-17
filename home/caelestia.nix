
{ inputs, ... }:

{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
  ];

  programs.caelestia = {
    enable = true;

    cli.enable = true;

    # Hyprland will launch the shell.
    systemd.enable = false;
  };
}
