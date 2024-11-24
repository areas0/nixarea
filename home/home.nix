{ config, pkgs, pkgs-unstable, ... }:

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
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    pkgs.git
    pkgs.argocd
    pkgs.argo
    pkgs.awscli2
    pkgs.azure-cli
    pkgs.circleci-cli
    pkgs.dig
    pkgs.firefox
    pkgs.helm-ls
    pkgs.krdc
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.kubectx
    pkgs.kubectl-neat
    pkgs.kubectl-node-shell
    pkgs.kubectl-view-secret
    pkgs.kube-linter
    pkgs.postgresql
    pkgs.terraform-docs
    # pkgs-unstable.pritunl-client
    pkgs.yarn
    pkgs.tree
    pkgs.bat
    pkgs.file
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.ranger
    pkgs.unzip
    pkgs.xclip
    pkgs.bc

    pkgs.pre-commit

    # VLC
    pkgs.vlc

    # Node
    pkgs.nodejs

    # Nix formatter
    pkgs.nixpkgs-fmt

    # Npm
    pkgs.nodePackages.npm
    pkgs.nodePackages.pnpm

    # yaml formatter
    pkgs.nodePackages.markdownlint-cli

    # C/C++
    pkgs.gnumake
    pkgs.clang-tools_14
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
    pkgs-unstable.poetry
    pkgs.python310
    pkgs.ruff-lsp

    pkgs.slack

    # Zip
    pkgs.ark

    # Go
    pkgs.go
    pkgs.gopls
    pkgs.golint

    # Rust
    pkgs.cargo
    pkgs.rustc

    # Postgres
    pkgs.postgresql

  ];

  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = false;
        no_fade_in = true;
      };

      background = [
        {
          monitor = "";
          color = "rgba(17, 17, 17, 1.0)";
        }
      ];

      input-field = [
        {
          # monitor = "eDP-1";

          size = "300, 50";

          outline_thickness = 1;

          outer_color = "rgb(b6c4ff)";
          inner_color = "rgb(dce1ff)";
          font_color = "rgb(354479)";

          fade_on_empty = false;
          placeholder_text = ''<span foreground="##354479">Password...</span>'';

          dots_spacing = 0.2;
          dots_center = true;
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          font_size = 50;
          color = "rgb(b6c4ff)";

          position = "0, 150";

          valign = "center";
          halign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:3600000] date +'%a %b %d'";
          font_size = 20;
          color = "rgb(b6c4ff)";

          position = "0, 50";

          valign = "center";
          halign = "center";
        }
      ];
    };
  };

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
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
