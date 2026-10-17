
{
  description = "Nix flakes yay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    stylix.url = "github:nix-community/stylix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    freesm.url = "github:FreesmTeam/FreesmLauncher";

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

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {

      # =============== PROTEUS ===============

      proteus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs;
        };

       
        modules = [
          ./hosts/proteus

          home-manager.nixosModules.home-manager

          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";

              extraSpecialArgs = {
                inherit inputs;
              };

              users.yasiru = import ./hosts/proteus/home.nix;
            };
          }

          {
            environment.systemPackages = [
              inputs.freesm.packages.x86_64-linux.freesmlauncher
            ];
          }
        ];

      };

      # =============== HERMES ===============

      hermes = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs;
        };

        modules = [
          ./hosts/hermes
          home-manager.nixosModules.home-manager

          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              extraSpecialArgs = {
                inherit inputs;
              };

              users.yasiru = import ./hosts/hermes/home.nix;
            };
          }
        ];
      };
    };
  };
}
