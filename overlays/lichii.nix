# Lichii Switch emulator, wrapped from the Superbuild GitHub release AppImage.
# See pkgs/lichii/default.nix.
final: prev: {
  lichii = final.callPackage ../pkgs/lichii { };
}
