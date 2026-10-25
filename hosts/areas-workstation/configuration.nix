{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  imports = [
    ../../modules/bluetooth.nix
    ../../modules/llm.nix
  ];

  # CUDA is unfree, so cache.nixos.org doesn't carry it (incl. ollama-cuda).
  # The NixOS CUDA team's cache replaces the defunct cuda-maintainers.cachix.org.
  nix.settings = {
    substituters = [ "https://cache.nixos-cuda.org" ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Pinned to 7.2, NOT linuxPackages_latest (now 7.3). hardware.nvidia.package
  # below is pinned to 610.57.04 to dodge a 615.x display-freeze regression;
  # 610.57.04 fails to build on kernel 7.3 (gpio_device_get_chip() gained a
  # const qualifier upstream, nv-caps-imex.c doesn't account for it, no
  # nixpkgs patch exists yet). Pinning the kernel here stops it silently
  # outrunning the driver pin again. Revisit both pins together.
  boot.kernelPackages = pkgs.linuxPackages_7_2;

  boot.initrd.luks.devices."luks-07cc5a0f-351f-432c-85d9-8cdde83524d8".device =
    "/dev/disk/by-uuid/07cc5a0f-351f-432c-85d9-8cdde83524d8";
  networking.hostName = "areas-workstation";

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      egl-wayland
      nvidia-vaapi-driver
    ];
  };

  # NVIDIA's libEGL hardcodes /etc/egl + /usr/share/egl as its external-platform
  # search dirs; on NixOS the egl-wayland JSON lives under /run/opengl-driver.
  # Without this var, eglGetDisplay() fails on Wayland and clients silently
  # fall through Mesa → swrast/llvmpipe (16× CPU spin on animated UIs).
  environment.sessionVariables.__EGL_EXTERNAL_PLATFORM_CONFIG_DIRS = "/run/opengl-driver/share/egl/egl_external_platform.d";

  hardware.nvidia = {
    modesetting.enable = true;
    # Saves full VRAM to /tmp/ on suspend to prevent graphical corruption
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;

    # Pinned to 610.57.04, NOT nvidiaPackages.latest (currently 615.78.08).
    # 615.71.09 (and later 615.x) has an open-kernel-module regression where
    # a DisplayPort power-cycle / monitor blank-wake triggers a GSP RPC that
    # never returns (stuck in kgspRecvPoll_IMPL), deadlocking nvidia-modeset
    # and freezing the whole display stack — only a hard power cycle
    # recovers (see github.com/NVIDIA/open-gpu-kernel-modules/issues/1392,
    # also #1371/#1367/#1289; reproduced across many GPUs/compositors,
    # including Hyprland). Every reporter who downgraded to 610.57.04 says
    # it fixed it; no fix has shipped upstream as of 2026-10. Hashes pulled
    # from nixpkgs commit 14e8b3d448 (the last commit to carry this version
    # as new_feature before it was bumped to 615.71.09). Revisit once #1392
    # has a confirmed fix (PR #1359 is a candidate, untested by reporters).
    package =
      (pkgs-unstable.linuxPackagesFor config.boot.kernelPackages.kernel).nvidiaPackages.mkDriver
        {
          version = "610.57.04";
          sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
          sha256_aarch64 = "sha256-QCefrMBCmpOwuOyXv1k5Gj0iB2CYlPgnG3JToUw/j54=";
          openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
          settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
          persistencedSha256 = "sha256-aXmD2VY1RLlgAnlHhOUMWzvMyhI6JTClcFLm4imF/mA=";
        };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # Force GTK apps to use dark theme
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    }
  ];

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
    # 26.11: the niri module also sets a default session, which conflicts with
    # plasma6's. Pin it to what 26.05 resolved to; SDDM remembers the last
    # session actually picked anyway.
    displayManager.defaultSession = "plasma";
  };

  # niri session alongside Hyprland — shows up as its own SDDM entry. The module
  # wires portals (gnome+gtk), gnome-keyring and polkit for the niri session.
  programs.niri.enable = true;
  programs.niri.useNautilus = false; # thunar is the file manager; keep FileChooser on gtk

  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.steam.extraCompatPackages = [ pkgs-unstable.proton-ge-bin ];
  programs.gamemode.enable = true;

  services.pipewire.extraConfig.pipewire."90-highrez" = {
    "context.properties" = {
      "default.clock.rate" = 96000;
      "default.clock.allowed-rates" = [
        44100
        48000
        96000
      ];
    };
  };

  # Star Citizen / RSI Launcher networking requirements per CIG support docs.
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 64090;
      to = 64110;
    }
  ];
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 8000;
      to = 8020;
    }
  ];

  services.netbird.enable = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  system.stateVersion = "25.11";
}
