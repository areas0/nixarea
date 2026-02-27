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

    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    nix-citizen.url = "github:LovingMelody/nix-citizen";

    # Optional - updates underlying without waiting for nix-citizen to update
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.inputs.nix-gaming.follows = "nix-gaming";

    # temporary fix
    nixpkgs-nvidia.url = "github:NixOS/nixpkgs/ab9ad415916a0fb89d1f539a9291d9737e95148e";
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
      nix-citizen,
      nix-gaming,
      nixpkgs-nvidia,
      elephant,
      walker,
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
        retroarch-full
        ryubing
      ];

      workConfig = {
        wallpaper = "${./assets/xenoblade.jpg}";
        additionalPackages = [ ];
      };

      personalConfig = {
        wallpaper = "${./assets/oshinoko-2.png}";
        additionalPackages = [
          pkgs-unstable.wine64Packages.waylandFull
          pkgs-unstable.gamescope-wsi
          pkgs-unstable.gamescope
          pkgs-unstable.heroic
          # citra
          pkgs-unstable.azahar

          # nix-citizen.packages.${system}.rsi-launcher
          # nix-citizen.packages.${system}.star-citizen

          pkgs-unstable.feishin
        ];
      };
    in
    {
      nixosConfigurations = {
        areas-thinkpad-work = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit pkgs-unstable;
            extraGamingPackages = [ ];
          };
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
                  walker
                  ;
                additionalConfig = workConfig;
              };
            }
          ];
        };

        areas-workstation = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit pkgs-unstable extraGamingPackages nixpkgs-nvidia;
          };
          modules = [
            ./hosts/configuration.nix
            ./hosts/areas-workstation/configuration.nix
            ./hosts/areas-workstation/hardware-configuration.nix
            ./modules/docker.nix
            nix-citizen.nixosModules.default
            {
              # Cachix setup
              nix.settings = {
                substituters = [ "https://nix-citizen.cachix.org" ];
                trusted-public-keys = [ "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo=" ];
              };

              programs.rsi-launcher = {
                # Enables the star citizen module
                enable = true;
                # Additional commands before the game starts
                preCommands = ''
                  export DXVK_HUD=compiler;
                  export DXVK_HDR=1;
                  export ENABLE_HDR_WSI=1;
                  export PROTON_ENABLE_HDR=1;
                  export MANGO_HUD=0;
                '';
                enforceWaylandDrv = false;
                includeOverlay = true;

                # location = "$HOME/Games/new-citizens";

                enableNTsync = true;
              };
            }
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
                  walker
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
                  walker
                  ;
              };
            }
          ];
        };
      };
    };
}
