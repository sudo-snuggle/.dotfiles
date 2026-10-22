{ pkgs, ... }:

{
  services.undervolt = {
    enable = true;
    
    # Snjn jh jh yf
    coreOffset = -100;
    gpuOffset = -45;
    uncoreOffset = -100;
    analogioOffset = 0;

  };

  environment.systemPackages = [ pkgs.undervolt ];
}