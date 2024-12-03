{ ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "off";
      splash = false;

      preload = [
        "${../../../assets/xenoblade.jpg}"
      ];

      wallpaper = [
        "eDP-1,${../../../assets/xenoblade.jpg}"
        "DP-7,${../../../assets/xenoblade.jpg}"
      ];
    };
  };
}
