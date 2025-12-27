{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs_teleport_14.url = "github:nixos/nixpkgs?rev=8125d74e21449e7ba702af890297a8bb9dc5f273";
    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen.url = "github:0xc000022070/zen-browser-flake";
    anyrun = {
      url = "github:anyrun-org/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprshell.url = "github:H3rmt/hyprshell?ref=hyprshell-release";
    hyprshell.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      nixpkgs-unstable,
      nixpkgs_teleport_14,
      zen,
      nvchad4nix,
      anyrun,
      hyprshell,
      ...
    }:
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
          # (import ./overlays/zen.nix { inherit inputs; })
          (import ./overlays/fladder.nix)
          (final: prev: { inherit nixpkgs-unstable; })
        ];
      };

      extraGamingPackages = with pkgs; [
        mangohud
        protonup-qt
        lutris
        bottles
        heroic
      ];

      workConfig = {
        wallpaper = "${./assets/xenoblade.jpg}";
        additionalPackages = [ ];
      };

      personalConfig = {
        wallpaper = "${./assets/oshinoko.png}";
        additionalPackages = [
          pkgs-unstable.wine64Packages.waylandFull
          pkgs-unstable.gamescope-wsi
          pkgs-unstable.gamescope
          pkgs-unstable.heroic
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
              home-manager.useUserPackages = true;
              home-manager.users.areas = import ./home;

              home-manager.extraSpecialArgs = {
                inherit
                  pkgs
                  pkgs-unstable
                  nvchad4nix
                  zen
                  anyrun
                  hyprshell
                  ;
              };
            }
          ];
        };

        areas-thinkpad-work = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit pkgs-unstable; };
          modules = [
            ./hosts/configuration.nix
            ./hosts/areas-thinkpad-work/configuration.nix
            ./hosts/areas-thinkpad-work/hardware-configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.users.areas = import ./home;

              home-manager.extraSpecialArgs = {
                inherit
                  pkgs
                  pkgs-unstable
                  nvchad4nix
                  zen
                  anyrun
                  hyprshell
                  ;
                additionalConfig = workConfig;
              };
            }
          ];
        };

        areas-workstation = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit pkgs-unstable extraGamingPackages;
          };
          modules = [
            ./hosts/configuration.nix
            ./hosts/areas-workstation/configuration.nix
            ./hosts/areas-workstation/hardware-configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.users.areas = import ./home;

              home-manager.extraSpecialArgs = {
                inherit
                  pkgs
                  pkgs-unstable
                  nvchad4nix
                  zen
                  anyrun
                  hyprshell
                  ;
                additionalConfig = personalConfig;
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
              home-manager.useUserPackages = true;
              home-manager.users.areas = import ./home;
              home-manager.backupFileExtension = "backup";

              home-manager.extraSpecialArgs = {
                inherit
                  pkgs
                  pkgs-unstable
                  nvchad4nix
                  zen
                  anyrun
                  hyprshell
                  ;
              };
            }
          ];
        };
      };
    };
}
