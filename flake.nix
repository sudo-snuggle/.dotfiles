{
  description = "NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NUR (Nix User Repository) for Firefox extensions
    nur.url = "github:nix-community/NUR";

    freesm.url = "github:FreesmTeam/FreesmLauncher";

    # Helium Browser flake
    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Betterfox
    betterfox = {
      url = "github:yokoffing/Betterfox";
      flake = false;
    };

    # iNiR shell for Niri
    inir = {
      url = "github:snowarch/inir";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Caelestia shell for Hyprland
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nur,
      helium,
      freesm,
      inir,
      caelestia-shell,
      ...
    }@inputs:
    {
      nixosConfigurations = {

        # =============== PROTEUS ===============
        proteus = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/proteus
            nur.modules.nixos.default
            home-manager.nixosModules.home-manager

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };
                users.yasiru = import ./hosts/proteus/home.nix;
              };
            }

            (
              { pkgs, ... }:
              {
                environment.systemPackages = [
                  inputs.freesm.packages.${pkgs.system}.freesmlauncher
                  inputs.helium.packages.${pkgs.system}.default
                ];
              }
            )
          ];
        };

        # =============== AENEAS ===============
        
        aeneas = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/aeneas
            home-manager.nixosModules.home-manager

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };
                users.yasiru = import ./hosts/aeneas/home.nix;
              };
            }

            (
              { pkgs, ... }:
              {
                environment.systemPackages = [
                  inputs.helium.packages.${pkgs.system}.default
                ];
              }
            )
          ];
        };

        # =============== HERMES  ===============
          
        hermes = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/hermes

            (
              { pkgs, ... }:
              {
                environment.systemPackages = [
                  inputs.freesm.packages.${pkgs.system}.freesmlauncher
                  inputs.helium.packages.${pkgs.system}.default
                ];
              }
            )
          ];
        };

      };
    };
}