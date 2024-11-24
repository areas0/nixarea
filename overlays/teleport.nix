{ inputs }:
let

in self: super:
let
  pkgs = import inputs.nixpkgs_teleport_12 {
    system = super.system;
    config.allowUnfree = true;
  };
in { teleport = pkgs.teleport; }