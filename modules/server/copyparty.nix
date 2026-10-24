{ config, pkgs, ... }:

{
  services.copyparty = {
    enable = true;
    # You can configure port bindings, users, and volumes natively here:
    settings = {
      i = "0.0.0.0";
      p = [ 130 ]; # Adjust port as needed
    };
    # Alternatively, if you want to load your existing configuration file:
    # extraConfigPath = ./config/copyparty.conf;
  };
}