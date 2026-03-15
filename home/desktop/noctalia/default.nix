{ config, lib, ... }:
let
  c = config.lib.stylix.colors.withHashtag;
in
{
  imports = [
    ./bar.nix
    ./burn-in.nix
    ./plugins.nix
    ./settings.nix
  ];

  programs.noctalia-shell = {
    enable = true;

    colors = {
      mPrimary = lib.mkForce c.base0D;
      mSecondary = lib.mkForce c.base0A;
      mTertiary = lib.mkForce c.base0E;
      mOnSurfaceVariant = lib.mkForce c.base04;
      mOutline = lib.mkForce c.base03;
      mHover = lib.mkForce c.base02;
    };
  };
}
