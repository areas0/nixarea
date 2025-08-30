{ pkgs, anyrun, ... }:
{
  programs.anyrun = {
    enable = true;
    package = pkgs.anyrun;
    config = {
      closeOnClick = true;

      plugins = [
        # An array of all the plugins you want, which either can be paths to the .so files, or their packages
        anyrun.packages.${pkgs.system}.applications
        anyrun.packages.${pkgs.system}.shell
        anyrun.packages.${pkgs.system}.randr
        anyrun.packages.${pkgs.system}.rink
      ];

    };
    extraConfigFiles."randr.ron".text = ''
      Config(
        prefix: ":edp",
      )
    '';
  };
}
