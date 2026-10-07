{ pkgs-unstable, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    # The runtime config is hyprland.lua (see default.nix); this only pins the
    # legacy default that 26.05 would otherwise flip to "lua".
    configType = "hyprlang";
    package = pkgs-unstable.hyprland;
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
    systemd.enable = true;
    systemd.variables = [ "--all" ];
    systemd.enableXdgAutostart = true;
  };
}
