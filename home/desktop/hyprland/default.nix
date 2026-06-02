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
    # Pin the legacy default; 26.05 flips gtk4.theme's default to null for
    # stateVersion >= 26.05. Keep matching gtk3 (stylix-managed) for now.
    gtk4.theme = config.gtk.theme;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  qt.enable = true;

  # Hyprland is the primary session. Override stylix's followSystem default,
  # which picks up "kde" from Plasma 6 on the workstation — stylix's
  # home-manager Qt theming only supports "qtct".
  stylix.targets.qt.platform = lib.mkForce "qtct";
}
