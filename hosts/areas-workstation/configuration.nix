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
  # Pinned explicitly so a kernel bump can't silently outrun the driver pin in
  # hardware.nvidia.package below; revisit both together. Known-good fallback
  # if 620.70.06 misbehaves: linuxPackages_6_18 + driver 610.57.04 (610 does
  # not build on 7.3: dmem_cgroup_register_region() changed signature).
  boot.kernelPackages = pkgs.linuxPackages_7_3;

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

    # Testing nixpkgs-unstable's latest (615.78.08 as of 2026-11). 615.x has an
    # open-module regression where a DisplayPort power-cycle / blank-wake / S3
    # resume deadlocks nvidia-modeset and freezes the display until a hard
    # reset (NVIDIA internal bug 7029722; github.com/NVIDIA/
    # open-gpu-kernel-modules/issues/1392, #1371, #1289). 615.78.08 fixes the
    # monitor power-cycle path; remaining DPMS hangs go through the DP
    # Adaptive-Sync path, which `options nvidia_modeset conceal_vrr_caps=1`
    # avoids (at the cost of VRR). Known-good fallback: 610.57.04 on 6.18 via
    # mkDriver {
    #   version = "610.57.04";
    #   sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
    #   openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
    #   settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
    #   persistencedSha256 = "sha256-aXmD2VY1RLlgAnlHhOUMWzvMyhI6JTClcFLm4imF/mA=";
    # }
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

  # Fixed 96 kHz graph: Easy Effects keeps the graph busy, so PipeWire can never
  # switch rates and would stay stuck at whatever rate the first stream had.
  services.pipewire.extraConfig.pipewire."90-highrez" = {
    "context.properties" = {
      "default.clock.rate" = 96000;
      "default.clock.allowed-rates" = [ 96000 ];
    };
  };
  # 44.1/48 kHz streams are resampled to 96 kHz; resampling happens client-side,
  # so raise quality for both pulse and native PipeWire clients.
  services.pipewire.extraConfig.pipewire-pulse."90-resample" = {
    "stream.properties"."resample.quality" = 10;
  };
  services.pipewire.extraConfig.client."90-resample" = {
    "stream.properties"."resample.quality" = 10;
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
