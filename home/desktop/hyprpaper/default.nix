{ additionalConfig, pkgs-unstable, ... }:
{
  services.hyprpaper = {
    enable = true;
    package = pkgs-unstable.hyprpaper;
    settings = {
      ipc = "true";
      splash = false;

      preload = [ "${additionalConfig.wallpaper}" ];

      wallpaper = [ ",${additionalConfig.wallpaper}" ];
    };
  };
}
