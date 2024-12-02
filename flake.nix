{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs_teleport_12.url =
      "github:nixos/nixpkgs?rev=857636b0327ad7e092ec6cbd71a7735c885cbebd";
    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs_zen.url = "github:matthewpi/nixpkgs?ref=zen-browser";
  };

  outputs = inputs@{ nixpkgs, home-manager, nixpkgs-unstable, nixpkgs_teleport_12, nixpkgs_zen, nvchad4nix, ... }:
    let
      system = "x86_64-linux";

      lib = nixpkgs.lib;

      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          # (import ./overlays/discord.nix)
          (import ./overlays/teleport.nix { inherit inputs; })
          (import ./overlays/zen.nix { inherit inputs; })
          (final: prev: { inherit nixpkgs-unstable; })
        ];
      };
    in
    {
      nixosConfigurations = {
        vm-test = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/configuration.nix
            ./hosts/vm-test/configuration.nix
            ./hosts/vm-test/hardware-configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.areas = import ./home;

              home-manager.extraSpecialArgs = {
                inherit pkgs pkgs-unstable nvchad4nix;
              };
            }
          ];
        };

        areas-thinkpad-work = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/configuration.nix
            ./hosts/areas-thinkpad-work/configuration.nix
            ./hosts/areas-thinkpad-work/hardware-configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.areas = import ./home;

              home-manager.extraSpecialArgs = {
                inherit pkgs pkgs-unstable nvchad4nix;
              };
            }
          ];
        };

        areas-thinkpad-home = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit pkgs-unstable; };
          system = "x86_64-linux";
          modules = [
            ./hosts/configuration.nix
            ./hosts/areas-thinkpad-home/configuration.nix
            ./hosts/areas-thinkpad-home/hardware-configuration.nix
           home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.areas = import ./home;
              home-manager.backupFileExtension = "backup";

              home-manager.extraSpecialArgs = {
                inherit pkgs pkgs-unstable nvchad4nix;
              };
            }
          ];
        };
      };
    };
}
