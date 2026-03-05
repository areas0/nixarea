{ pkgs-unstable, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland;
    xwayland.enable = true;
    systemd.enable = true;
    systemd.variables = [ "--all" ];
    systemd.enableXdgAutostart = true;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$fileManager" = "thunar";
      "$menu" = "walker";
      exec-once = [
        "code"
        "hyprpanel"
        "wl-paste --watch cliphist store"
        "sleep 2 && pkill -x swww-daemon; sleep 0.5; systemctl --user restart hyprpaper.service"
      ];
      env = [
        "NIXOS_OZONE_WL,1"
        "MOZ_ENABLE_WAYLAND,1"
        "MOZ_WEBRENDER,1"
        "_JAVA_AWT_WM_NONREPARENTING,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QPA_PLATFORM,wayland"
        "SDL_VIDEODRIVER,wayland"
        "GDK_BACKEND,wayland"
      ];

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };
    };
  };
}
