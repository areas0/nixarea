{ inputs }:
let

in self: super:
let
  pkgs = import inputs.nixpkgs_zen {
    system = super.system;
    config.allowUnfree = true;
  };
in
{ zen-browser = pkgs.zen-browser; }
