{ nvchad4nix, config, pkgs, pkgs-unstable, ... }:
{
  imports = [
    nvchad4nix.homeManagerModule
  ];
  programs.nvchad = {
    enable = true;
    neovim = pkgs-unstable.neovim-unwrapped;
    extraPackages = with pkgs; [
      nodePackages.bash-language-server
      docker-compose-language-service
      dockerfile-language-server-nodejs
      emmet-language-server
      nixd
      (python3.withPackages (ps: with ps; [
        python-lsp-server
        flake8
      ]))
    ];
    hm-activation = true;
    backup = true;
  };
}
