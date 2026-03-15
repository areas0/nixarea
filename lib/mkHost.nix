{
  nixpkgs,
  stylix,
  home-manager,
  pkgs,
  pkgs-unstable,
  nvchad4nix,
  zen,
  noctalia,
  mkMatugenScheme,
}:

{
  hostConfig,
  hardwareConfig,
  extraSpecialArgs ? { },
  extraModules ? [ ],
  additionalConfig,
}:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    inherit pkgs-unstable;
  }
  // extraSpecialArgs;
  modules = [
    ../hosts/configuration.nix
    hostConfig
    hardwareConfig
    stylix.nixosModules.stylix
    {
      stylix.image = additionalConfig.wallpaper;
      stylix.base16Scheme = mkMatugenScheme additionalConfig.theme additionalConfig.wallpaper;
    }
  ]
  ++ extraModules
  ++ [
    home-manager.nixosModules.home-manager
    {
      home-manager.useUserPackages = true;
      home-manager.users.areas = import ../home;
      home-manager.sharedModules = [
        zen.homeModules.default
        noctalia.homeModules.default
      ];
      home-manager.backupFileExtension = "backup";

      home-manager.extraSpecialArgs = {
        inherit
          pkgs
          pkgs-unstable
          nvchad4nix
          zen
          additionalConfig
          ;
      };
    }
  ];
}
