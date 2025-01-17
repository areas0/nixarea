{ pkgs, pkgs-unstable, ... }:
{
  xdg.portal = {
    enable = true;
    #   config.common.default = "*";
    wlr.enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
