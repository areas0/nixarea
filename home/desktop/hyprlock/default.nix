{ ... }:
{
  imports = [
    ./settings.nix
  ];
  
  programs.hyprlock = {
    enable = true;
  };
}
