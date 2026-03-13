{
  pkgs,
  pkgs-unstable,
  config,
  extraGamingPackages,
  ...
}:
{
  imports = [ ../modules/xdg-portal.nix ];

  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  services.xserver.updateDbusEnvironment = true;
  security.polkit.enable = true;
  security.pam.services = {
    hyprlock = { };
  };
  programs = {
    hyprland = {
      enable = true;
      portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
      package = pkgs-unstable.hyprland;
    };

    hyprlock = {
      enable = true;
      package = pkgs-unstable.hyprlock;
    };
  };

  services.hypridle.enable = true;
  services.upower.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    material-design-icons
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    terminus_font
    terminus_font_ttf
    termsyn
    font-awesome
    nerd-fonts.hack
    nerd-fonts.noto
    nerd-fonts.iosevka
    nerd-fonts.terminess-ttf
    siji
  ];

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    package = pkgs.nixVersions.latest;

    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };

  services.xserver.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;
  programs.zsh.enable = true;

  users.users.areas = {
    isNormalUser = true;
    description = "areas";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = [ ];
    shell = pkgs.zsh;
  };

  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment = {
    systemPackages =
      with pkgs;
      [
        vim
        wget
        curl
        kitty
      ]
      ++ extraGamingPackages;

    shells = with pkgs; [ zsh ];
  };

  networking.firewall = {
    enable = true;
    allowPing = false;
  };
}
