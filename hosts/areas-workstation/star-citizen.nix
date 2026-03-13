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
    '';
    enforceWaylandDrv = false;
    includeOverlay = true;
    enableNTsync = true;
  };
}
