{ pkgs, pkgs-unstable, ... }:
{
  programs.zsh = {
    enable = true;
    autocd = true;
    autosuggestion = {
      enable = true;
    };
    history = {
      # append = true;
      expireDuplicatesFirst = true;
    };
    initContent = ''
      eval "$(${pkgs-unstable.kubectl-cnpg}/bin/kubectl-cnpg completion zsh)"
    '';
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "ssh"
        "ssh-agent"
        "kubectl"
        "kubectx"
        "fzf"
        "argocd"
        "docker-compose"
        "golang"
        "operator-sdk"
      ];
      theme = "robbyrussell";
    };
    shellAliases = {
      kns = "kubens";
      kcx = "${pkgs.kubectx}";
      kneat = "${pkgs.kubectl-neat}";
      kvs = "${pkgs.kubectl-view-secret}";
      cd = "z";
    };
  };
}
