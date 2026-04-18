{
  pkgs,
  pkgs-unstable,
  config,
  ...
}:
{
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscode;

    profiles.default.extensions = with pkgs-unstable.vscode-extensions; [
      github.copilot
      pkief.material-icon-theme
      ms-azuretools.vscode-docker
      ms-kubernetes-tools.vscode-kubernetes-tools
      anthropic.claude-code
    ];
  };

  home.file.".cursor/extensions/stylix.stylix".source =
    config.home.file.".vscode/extensions/stylix.stylix".source;
}
