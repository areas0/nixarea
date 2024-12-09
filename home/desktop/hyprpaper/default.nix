{ ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "true";
      splash = false;

      preload = [
        "${../../../assets/xenoblade.jpg}"
      ];

      wallpaper = [
        ",${../../../assets/xenoblade.jpg}"
      ];
    };
  };
}
