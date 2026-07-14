{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
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
      # Pinned to the 26.05 release branch to match nixpkgs. master tracks
      # unstable, and its kmscon target expects the structured
      # `services.kmscon.config` option that only exists on unstable.
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    noctalia-v5 = {
      url = "github:noctalia-dev/noctalia-shell";
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

    # Tracks padoa/stack-info main. Bump with: nix flake update stack-info.
    # Private repo — fetched over SSH using the host's git credentials.
    stack-info = {
      url = "git+ssh://git@github.com/padoa/stack-info?ref=main";
      flake = false;
    };

    # hammer (lives in sre-toolchain's hammer/) — pinned to the latest published
    # semver tag rather than main. Bump by pointing ref at the new tag. Private
    # repo — fetched over SSH using the host's git credentials.
    sre-toolchain = {
      url = "git+ssh://git@github.com/padoa/sre-toolchain?ref=refs/tags/hammer-1.1.1";
      flake = false;
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
      noctalia-v5,
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
          (import ./overlays/hammer.nix { inherit inputs; })
          (import ./overlays/kubectl-stack.nix { inherit inputs; })
          (import ./overlays/notion-app.nix)
          (final: prev: { inherit nixpkgs-unstable; })
        ];
      };

      mkMatugenScheme = import ./lib/matugen.nix { inherit pkgs pkgs-unstable; };

      defaultTheme = {
        schemeType = "scheme-tonal-spot";
        contrast = 0.3;
        lightnessDark = -0.3;
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
          noctalia-v5
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
        additionalPackages = [
          pkgs.notion-app
        ];
      };

      personalConfig = {
        wallpaper = "${./assets/oshinoko-2.png}";
        theme = {
          schemeType = "scheme-vibrant";
          contrast = 0.3;
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
          pkgs-unstable.protonplus
        ];
      };
    in
    {
      formatter.${system} = pkgs.nixfmt;

      checks.${system} = {
        pre-commit = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
            # nixfmt-rfc-style's default package is the deprecated pkgs.nixfmt-rfc-style
            # alias (warns on access); pkgs.nixfmt is now identical.
            nixfmt-rfc-style.package = pkgs.nixfmt;
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
          additionalConfig = personalConfig // {
            isNvidia = true;
            enableLocalLLM = true;
          };
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
