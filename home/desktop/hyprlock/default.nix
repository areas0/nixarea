{ pkgs-unstable, ... }:
{
  imports = [
    ./settings.nix
  ];

  programs.hyprlock = {
    enable = true;
    package = pkgs-unstable.hyprlock;
  };
}
