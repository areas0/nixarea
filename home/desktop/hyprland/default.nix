{
  pkgs,
  config,
  lib,
  ...
}:
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
    # gtk4.theme is managed by stylix's gtk target (it mirrors gtk.theme), so
    # we no longer pin it here — doing so collides with stylix's definition.
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  qt.enable = true;

  # Hyprland is the primary session. Override stylix's followSystem default,
  # which picks up "kde" from Plasma 6 on the workstation — stylix's
  # home-manager Qt theming only supports "qtct".
  stylix.targets.qt.platform = lib.mkForce "qtct";
}
