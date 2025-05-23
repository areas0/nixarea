{ pkgs, pkgs-unstable, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscode;

    profiles.default.extensions = with pkgs-unstable.vscode-extensions; [
      github.copilot
      pkief.material-icon-theme
      ms-azuretools.vscode-docker
      ms-kubernetes-tools.vscode-kubernetes-tools
    ];
  };
}
