{
  config,
  pkgs,
  pkgs-unstable,
  zen,
  additionalConfig,
  ...
}:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "areas";
  home.homeDirectory = "/home/areas";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.git
    pkgs.argocd
    pkgs.argo-workflows
    pkgs.awscli2
    pkgs.azure-cli
    pkgs.circleci-cli
    pkgs.dig
    pkgs.firefox
    pkgs.helm-ls

    pkgs-unstable.kubectl
    pkgs-unstable.kubernetes-helm
    pkgs-unstable.kubectx
    pkgs-unstable.kubectl-neat
    pkgs-unstable.kubectl-node-shell
    pkgs-unstable.kubectl-view-secret
    pkgs-unstable.kube-linter

    pkgs.postgresql
    pkgs.terraform-docs
    pkgs-unstable.pritunl-client
    pkgs.yarn
    pkgs.tree
    pkgs.bat
    pkgs.file
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.ranger
    pkgs.unzip
    pkgs.wl-clipboard
    pkgs.bc

    pkgs.teleport_15
    pkgs-unstable.kubectl-cnpg

    pkgs.pre-commit

    # VLC
    pkgs.vlc

    # Node
    # pkgs.nodejs

    # Nix formatter
    pkgs.nixfmt-rfc-style
    pkgs.nixfmt-tree

    # Npm
    pkgs.nodePackages.npm
    # pkgs.nodePackages.pnpm

    # yaml formatter
    pkgs.nodePackages.markdownlint-cli

    # C/C++
    pkgs.gnumake
    pkgs.clang-tools
    pkgs.gcc.out
    pkgs.glib.out

    # Json
    pkgs.jq
    pkgs.yq

    # Git/github
    pkgs.gh # github cli

    # Hashicorp stuff
    pkgs-unstable.terraform
    pkgs-unstable.vault-bin
    pkgs.terraform-ls

    # Openssl
    pkgs.openssl

    # Python
    # pkgs-unstable.poetry
    pkgs.python313
    # pkgs.ruff-lsp

    pkgs.slack

    # Zip
    pkgs.kdePackages.ark

    # Go
    pkgs.go
    pkgs.gopls
    pkgs.golint

    # Rust
    pkgs.cargo
    pkgs.rustc

    # Media players and sound tools
    pkgs.pavucontrol
    pkgs.easyeffects
    pkgs.pwvucontrol

    pkgs-unstable.jellyfin-media-player

    zen.packages."x86_64-linux".default
    pkgs.fladder

    # thunar file manager
    pkgs.xfce.thunar
    pkgs.xfce.thunar-archive-plugin

    #1password
    pkgs._1password-gui
    pkgs._1password-cli

    # dotnet
    pkgs.dotnetCorePackages.dotnet_8.runtime

    pkgs.buildah
    pkgs-unstable.warp-terminal

    pkgs.wlr-randr
    pkgs-unstable.code-cursor

    # screenshot tools
    pkgs.grim
    pkgs.slurp

    # media/brightness controls
    pkgs.brightnessctl
    pkgs.playerctl

    # clipboard history
    pkgs.cliphist
    pkgs.wtype

    # proton apps
    pkgs-unstable.protonmail-desktop
    pkgs-unstable.protonvpn-gui

  ]
  ++ additionalConfig.additionalPackages;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/areas/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "vim";
    SHELL = "zsh";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
