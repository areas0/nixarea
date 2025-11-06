{ inputs }:
let

in
self: super:
let
  pkgs = import inputs.nixpkgs_teleport_14 {
    system = super.system;
    config.allowUnfree = true;
  };
in
{
  teleport_15 = pkgs.teleport_15;
}
