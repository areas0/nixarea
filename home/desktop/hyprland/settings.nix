{ pkgs-unstable, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true; # enable Hyprland
    package = pkgs-unstable.hyprland;
    xwayland.enable = true;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      exec-once = [
      ];
    };
  };
}
