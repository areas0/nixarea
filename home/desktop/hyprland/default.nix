{ pkgs, ... }:
{
  imports = [
    ./bindings.nix
    ./settings.nix
  ];

  # Hyprland 0.55+: if hyprland.lua exists, it is loaded INSTEAD of
  # hyprland.conf. The hyprlang config generated from settings.nix/bindings.nix
  # stays on disk as a fallback — delete the lua file to revert.
  xdg.configFile."hypr/hyprland.lua".source = ./hyprland.lua;

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  qt.enable = true;
}
