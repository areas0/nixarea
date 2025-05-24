{ pkgs, ... }:
{
  imports = [
    ./bindings.nix
    ./settings.nix
  ];

  gtk = {
    enable = true;

    theme = {
      package = pkgs.adapta-gtk-theme;
      name = "Adapta-Nokto-Eta";
    };
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

  };
}
