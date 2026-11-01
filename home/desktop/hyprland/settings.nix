{ pkgs-unstable, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    # HM writes hypr/hyprland.lua; our own lua is appended via extraConfig (see
    # default.nix).
    configType = "lua";
    package = pkgs-unstable.hyprland;
    # HM 26.05 calls `portalPackage.override { hyprland = ...; }`, but unstable
    # xdph no longer takes a `hyprland` argument; make that override a no-op.
    portalPackage =
      let
        xdph = pkgs-unstable.xdg-desktop-portal-hyprland;
      in
      xdph // { override = _: xdph; };
    xwayland.enable = true;
    systemd.enable = true;
    systemd.variables = [ "--all" ];
    systemd.enableXdgAutostart = true;
  };
}
