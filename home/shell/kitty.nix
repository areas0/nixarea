{ lib, ... }:
{
  programs.kitty = {
    enable = true;

    settings = {
      background_opacity = lib.mkForce "0.3";
      background_blur = lib.mkForce "0";
    };
  };
}
