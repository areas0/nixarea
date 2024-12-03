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
        "eDP-1,${../../../assets/xenoblade.jpg}"
        "DP-7,${../../../assets/xenoblade.jpg}"
      ];
    };
  };
}
