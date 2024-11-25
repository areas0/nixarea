{ pkgs-unstable, ... }:
{
  programs.neovim = {
    enable = true;
    package = pkgs-unstable.neovim-unwrapped;
    viAlias = true;
    vimAlias = true;
    # vimDiffAlias = true;
  };
}
