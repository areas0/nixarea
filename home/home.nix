{
  pkgs,
  pkgs-unstable,
  claude-code,
  additionalConfig,
  ...
}:

let
  matugen-wrapped = pkgs.writeShellScriptBin "matugen" ''
    args=()
    has_index=false
    for arg in "$@"; do
      [[ "$arg" == "--source-color-index" ]] && has_index=true
      args+=("$arg")
      if [[ "$arg" == "image" ]] && ! $has_index; then
        args+=("--source-color-index" "0")
        has_index=true
      fi
    done
    exec ${pkgs-unstable.matugen}/bin/matugen "''${args[@]}"
  '';
in
{
  home.username = "areas";
  home.homeDirectory = "/home/areas";
  home.stateVersion = "24.05";

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  home.packages = [
    # DevOps / Cloud
    pkgs.git
    pkgs.argocd
    pkgs.argo-workflows
    pkgs.awscli2
    pkgs-unstable.azure-cli
    pkgs.circleci-cli
    pkgs.dig
    pkgs.helm-ls

    # Kubernetes
    pkgs-unstable.kubectl
    pkgs-unstable.kubernetes-helm
    pkgs-unstable.kubectx
    pkgs-unstable.kubectl-neat
    pkgs-unstable.kubectl-node-shell
    pkgs-unstable.kubectl-view-secret
    pkgs-unstable.kube-linter
    pkgs-unstable.kubectl-cnpg
    pkgs.hammer
    pkgs.kubectl-stack
    pkgs.kubectl-ctx
    pkgs.kubectl-client

    # CLI tools
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
    pkgs.pre-commit

    # Nix
    pkgs.nixfmt-rfc-style
    pkgs.nixfmt-tree

    # Node
    pkgs.nodePackages.npm
    pkgs.nodePackages.markdownlint-cli

    # C/C++
    pkgs.gnumake
    pkgs.clang-tools
    pkgs.gcc.out
    pkgs.glib.out

    # JSON/YAML
    pkgs.jq
    pkgs.yq

    # Git/GitHub
    pkgs.gh

    # Hashicorp
    pkgs-unstable.terraform
    pkgs-unstable.vault-bin
    pkgs.terraform-ls

    pkgs.openssl

    # Python
    pkgs.python313

    pkgs.slack

    # Go
    pkgs.go
    pkgs.gopls
    pkgs.golint

    # Rust
    pkgs.cargo
    pkgs.rustc

    # .NET
    pkgs.dotnetCorePackages.dotnet_8.runtime

    # Containers
    pkgs.buildah

    # Media / Sound
    pkgs.vlc
    pkgs.pavucontrol
    pkgs.easyeffects
    pkgs.pwvucontrol
    pkgs-unstable.jellyfin-media-player
    pkgs.fladder

    # Browsers (Zen is managed via programs.zen-browser)

    # File manager
    pkgs.xfce.thunar
    pkgs.xfce.thunar-archive-plugin
    pkgs.kdePackages.ark

    # 1Password
    pkgs._1password-gui
    pkgs._1password-cli

    # Terminals / Editors
    pkgs-unstable.warp-terminal
    pkgs-unstable.code-cursor
    claude-code.packages.x86_64-linux.default

    # Wayland utilities
    pkgs.wlr-randr
    pkgs.grim
    pkgs.slurp
    pkgs.brightnessctl
    pkgs.playerctl
    pkgs.cliphist
    pkgs.wtype

    matugen-wrapped

    # Proton apps
    pkgs-unstable.protonmail-desktop
    pkgs-unstable.protonvpn-gui

    pkgs-unstable.openhue-cli

    pkgs.galaxy-buds-client

    pkgs.fastfetch
  ]
  ++ additionalConfig.additionalPackages;

  home.sessionVariables = {
    EDITOR = "vim";
    SHELL = "zsh";
    BROWSER = "zen-browser";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/about" = "zen-beta.desktop";
      "x-scheme-handler/unknown" = "zen-beta.desktop";
      "text/html" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
    };
  };

  programs.home-manager.enable = true;
}
