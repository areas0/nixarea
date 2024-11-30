{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;

    extensions = with pkgs.vscode-extensions; [
      github.copilot
      pkief.material-icon-theme
      ms-azuretools.vscode-docker
      ms-kubernetes-tools.vscode-kubernetes-tools
    ];
  };
}
