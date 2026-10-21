{ config, lib, pkgs, ... }:

{
  services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = true; # Set to true initially so we can send our SSH key over
  };
};
  }