# Official Notion desktop app, vendored from tsrk's nix-flex (MIT). See
# pkgs/notion-app/README.md. Runs Notion's app.asar under nixpkgs' electron so
# we control the Electron version and get native Wayland.
final: prev: {
  notion-app = final.callPackage ../pkgs/notion-app { };
}
