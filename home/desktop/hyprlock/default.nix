# Deprecated: lock screen is now handled by Noctalia shell
{ pkgs-unstable, ... }:
{
  imports = [ ./settings.nix ];

  programs.hyprlock = {
    enable = false;
    package = pkgs-unstable.hyprlock;
  };
}
