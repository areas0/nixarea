{ additionalConfig, pkgs-unstable, ... }:
{
  services.hyprpaper = {
    enable = true;
    package = pkgs-unstable.hyprpaper;
    settings = {
      splash = false;

      wallpaper = {
        path = "${additionalConfig.wallpaper}";
      };
    };
  };
}
