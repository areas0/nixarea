{ pkgs, ... }:
{
  nix.settings = {
    substituters = [ "https://nix-citizen.cachix.org" ];
    trusted-public-keys = [ "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo=" ];
  };

  programs.rsi-launcher = {
    enable = true;
    # TEMPORARY (EAC 70003 bisect): LUG's own prebuilt runner instead of the
    # default wine-astral. Gamemode, HDR exports and NTsync were ruled out.
    wine = pkgs.lug-wine-bin;
    preCommands = ''
      export DXVK_HUD=compiler;
      # TEMPORARY: with lug-wine-bin these made the game die on launch with
      # "[Vulkan] Requested surface formats not found from physical device
      # formats". Restore them if switching back to wine-astral.
      #   export DXVK_HDR=1;
      #   export ENABLE_HDR_WSI=1;
      #   export PROTON_ENABLE_HDR=1;
      export MANGO_HUD=0;

      # wine-astral's wineboot default reports Windows XP 64-bit, which the
      # game's renderer refuses ("Failed to open render library: Newer
      # Windows version needed"). wineprefix-preparer's `wineboot -u` resets
      # this any time nix-citizen's derivation changes, so pin it back to
      # win10 on every launch instead of relying on a one-off manual fix.
      wine winecfg -v win10 >/dev/null 2>&1 || true
    '';
    enforceWaylandDrv = false;
    # Must stay true: with it off, nix-citizen's fallback path evaluates
    # `self.packages.${pkgs.stdenv.hostPlatform}`, which fails to evaluate on
    # current nixpkgs (hostPlatform is no longer coercible to a string).
    includeOverlay = true;
    enableNTsync = true;
  };
}
