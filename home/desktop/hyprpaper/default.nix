{ additionalConfig, ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "true";
      splash = false;

      preload = [ "${additionalConfig.wallpaper}" ];

      wallpaper = [ ",${additionalConfig.wallpaper}" ];
    };
  };
}
