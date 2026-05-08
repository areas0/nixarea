{
  config,
  pkgs,
  pkgs-unstable,
  pkgs-nvidia,
  ...
}:

{
  imports = [
    ../../modules/bluetooth.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Pinned to 6.18 — kernel 7.0 broke NVIDIA EGL on Wayland
  # (eglGetDisplay fails, clients fall back to llvmpipe → 100%+ CPU on animated UIs).
  # Revisit once nvidia-x11 has a 7.x-compatible release.
  boot.kernelPackages = pkgs.linuxPackages_6_18;

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

    # Pinned to 595.58.03 via pkgs-nvidia (see flake.nix). The May package
    # bump moved nvidiaPackages.beta to 595.71.05 which broke NVIDIA EGL on
    # Wayland for native clients (Zen, noctalia, etc.).
    package =
      let
        fixedKernelPackages = pkgs-nvidia.linuxKernel.packagesFor config.boot.kernelPackages.kernel;
      in
      fixedKernelPackages.nvidiaPackages.beta;
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
  };

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

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  system.stateVersion = "25.11";
}
