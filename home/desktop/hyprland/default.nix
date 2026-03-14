{ pkgs, ... }:
{
  imports = [
    ./bindings.nix
    ./settings.nix
  ];

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  qt.enable = true;
}
