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

    nix-citizen.url = "github:LovingMelody/nix-citizen";

    # Optional - updates underlying without waiting for nix-citizen to update
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.inputs.nix-gaming.follows = "nix-gaming";

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixpkgs-unstable,
      nixpkgs_teleport_14,
      zen,
      nvchad4nix,
      nix-citizen,
      nix-gaming,
      stylix,
      noctalia,
      noctalia-qs,
      git-hooks,
      claude-code,
      ...
    }:
    let
      system = "x86_64-linux";

      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (import ./overlays/teleport.nix { inherit inputs; })
          (import ./overlays/fladder.nix)
          (import ./overlays/hammer.nix)
          (final: prev: { inherit nixpkgs-unstable; })
        ];
      };

      mkMatugenScheme = import ./lib/matugen.nix { inherit pkgs pkgs-unstable; };

      defaultTheme = {
        schemeType = "scheme-tonal-spot";
        contrast = 0.0;
        lightnessDark = -0.5;
        amoled = false;
      };

      mkHost = import ./lib/mkHost.nix {
        inherit
          nixpkgs
          stylix
          home-manager
          pkgs
          pkgs-unstable
          nvchad4nix
          zen
          noctalia
          claude-code
          mkMatugenScheme
          ;
      };

      extraGamingPackages = with pkgs; [
        mangohud
        protonup-qt
        lutris
        bottles
        heroic
        ryubing
      ];

      workConfig = {
        wallpaper = "${./assets/oshinoko-2.png}";
        theme = defaultTheme;
        isLaptop = true;
        additionalPackages = [ ];
      };

      personalConfig = {
        wallpaper = "${./assets/oshinoko-2.png}";
        theme = {
          schemeType = "scheme-vibrant";
          contrast = 0.0;
          lightnessDark = 0.0;
          amoled = true;
        };
        isLaptop = false;
        additionalPackages = [
          pkgs-unstable.wine64Packages.waylandFull
          pkgs-unstable.gamescope-wsi
          pkgs-unstable.gamescope
          pkgs-unstable.heroic
          pkgs-unstable.azahar
          pkgs-unstable.feishin
        ];
      };
    in
    {
      formatter.${system} = pkgs.nixfmt-rfc-style;

      checks.${system} = {
        pre-commit = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
            commitizen.enable = true;
          };
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        shellHook = self.checks.${system}.pre-commit.shellHook;
      };

      nixosConfigurations = {
        areas-thinkpad-work = mkHost {
          hostConfig = ./hosts/areas-thinkpad-work/configuration.nix;
          hardwareConfig = ./hosts/areas-thinkpad-work/hardware-configuration.nix;
          extraSpecialArgs = {
            extraGamingPackages = [ ];
          };
          additionalConfig = workConfig;
        };

        areas-workstation = mkHost {
          hostConfig = ./hosts/areas-workstation/configuration.nix;
          hardwareConfig = ./hosts/areas-workstation/hardware-configuration.nix;
          extraSpecialArgs = { inherit extraGamingPackages; };
          extraModules = [
            ./modules/docker.nix
            nix-citizen.nixosModules.default
            ./hosts/areas-workstation/star-citizen.nix
          ];
          additionalConfig = personalConfig;
        };

        areas-thinkpad-home = mkHost {
          hostConfig = ./hosts/areas-thinkpad-home/configuration.nix;
          hardwareConfig = ./hosts/areas-thinkpad-home/hardware-configuration.nix;
          extraSpecialArgs = {
            extraGamingPackages = [ ];
          };
          additionalConfig = personalConfig // {
            isLaptop = true;
          };
        };
      };
    };
}
