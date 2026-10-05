{ pkgs, ... }:

{
  services.undervolt = {
    enable = true;
    
    # Start conservative, then tighten incrementally
    coreOffset = -90;
    gpuOffset = -40;
    uncoreOffset = -90;
    analogioOffset = 0;

    # Uncomment if your BIOS allows it (often doesn't on T480)
    # temp = -5;
  };

  environment.systemPackages = [ pkgs.undervolt ];
}