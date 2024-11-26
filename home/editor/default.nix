{ pkgs-unstable, ... }:
{
  imports = [
    ./nvchad.nix
  ];

  programs.neovim = {
    enable = false;
    package = pkgs-unstable.neovim-unwrapped;
    viAlias = true;
    vimAlias = true;
    # vimDiffAlias = true;
  };
}
