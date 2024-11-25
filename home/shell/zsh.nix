{ ... }:
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
      ];
      theme = "robbyrussell";
    };
  };
}
