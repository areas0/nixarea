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
  # Pinned to 6.18 — kernel 7.0 broke NVIDIA EGL on Wayland
  # (eglGetDisplay fails, clients fall back to llvmpipe → 100%+ CPU on animated UIs).
  # Revisit once nvidia-x11 has a 7.x-compatible release.
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

    # Latest driver from the live channel. The EGL-on-Wayland breakage that
    # forced the old version pin was a package/module mismatch from pinning the
    # driver to a separate nixpkgs rev (nixpkgs#525152), not this version — the
    # in-tree module now ships nvidia-egl-external-platforms automatically.
    # nixpkgs stable's nvidiaPackages.latest (595.71.05) doesn't build
    # against Linux 7.2: the kernel dropped the generic strncpy() symbol
    # (deprecated for years, now gone), and nvidia-drm-helper.c also predates
    # 7.2's DRM atomic-commit API changes (see
    # github.com/NVIDIA/open-gpu-kernel-modules/issues/1224, still open with
    # no official fix). nixpkgs-unstable already carries 610.57.04, which
    # builds clean against our kernel with zero patches — pull the driver
    # from there instead of patching around it. Drop this override once
    # nixpkgs stable catches up.
    package = (pkgs-unstable.linuxPackagesFor config.boot.kernelPackages.kernel).nvidiaPackages.latest;
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
