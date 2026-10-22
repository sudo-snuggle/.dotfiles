{ pkgs, ... }:

{
  services.undervolt = {
    enable = true;
    
    # Snjn jh jh yf
    coreOffset = -90;
    gpuOffset = -40;
    uncoreOffset = -90;
    analogioOffset = 0;

  };

  environment.systemPackages = [ pkgs.undervolt ];
}