{ ... }:
{
  nix.settings = {
    substituters = [ "https://nix-citizen.cachix.org" ];
    trusted-public-keys = [ "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo=" ];
  };

  programs.rsi-launcher = {
    enable = true;
    preCommands = ''
      export DXVK_HUD=compiler;
      export DXVK_HDR=1;
      export ENABLE_HDR_WSI=1;
      export PROTON_ENABLE_HDR=1;
      export MANGO_HUD=0;

      # wine-astral's wineboot default reports Windows XP 64-bit, which the
      # game's renderer refuses ("Failed to open render library: Newer
      # Windows version needed"). wineprefix-preparer's `wineboot -u` resets
      # this any time nix-citizen's derivation changes, so pin it back to
      # win10 on every launch instead of relying on a one-off manual fix.
      wine winecfg -v win10 >/dev/null 2>&1 || true
    '';
    enforceWaylandDrv = false;
    includeOverlay = true;
    enableNTsync = true;
  };
}
