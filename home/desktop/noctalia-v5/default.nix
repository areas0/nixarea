{
  pkgs,
  noctalia-v5,
  additionalConfig,
  ...
}:
let
  toml = pkgs.formats.toml { };

  # V5 picks/cycles wallpapers from a directory (single-file paths land in their
  # own store path, so dirOf would just return /nix/store). Point at the repo
  # assets dir so the whole tree gets copied as one store path.
  wallpaperDir = "${../../../assets}";

  config = {
    # v5.0.0-beta.3 moved ui_scale out of [shell] into a dedicated [accessibility]
    # block; the old shell.ui_scale key is no longer read.
    accessibility.ui_scale = 1.0;

    shell = {
      polkit_agent = true;
      # v5 replaced the old attach_*/background_blur panel booleans with a
      # transparency mode + per-panel placement. "glass" is the translucent
      # (formerly background_blur) look; "attached" docks the panels to the bar.
      panel = {
        transparency_mode = "glass";
        control_center_placement = "attached";
        wallpaper_placement = "attached";
      };
    };

    theme = {
      mode = "dark";
      source = "wallpaper";
      wallpaper_scheme = "m3-tonal-spot";
    };

    wallpaper = {
      enabled = true;
      directory = wallpaperDir;
      fill_mode = "crop";
    };

    # v5 backdrop: dim + blur the desktop behind open panels.
    backdrop = {
      enabled = true;
      blur_intensity = 0.5;
      tint_intensity = 0.3;
    };

    notification = {
      enable_daemon = true;
      layer = "top";
      background_opacity = 0.8;
    };

    osd.position = "top_right";

    weather = {
      enabled = false;
      unit = "celsius";
      refresh_minutes = 30;
    };

    # v5 split "where am I" out of weather into a shared [location] block that
    # also feeds night light and theme auto mode.
    location.address = "Paris";

    nightlight.enabled = false;

    system.monitor.enabled = true;

    # v5 added a dedicated lock screen with a blurred desktop snapshot as the
    # background — paired with the idle lock below.
    lockscreen = {
      enabled = true;
      blurred_desktop = true;
      blur_intensity = 0.5;
      tint_intensity = 0.3;
    };

    idle.behavior = {
      lock = {
        timeout = 180;
        # v5.0.0-beta.3 replaced the idle IPC command strings with an `action` enum
        # (lock | screen_off | suspend | lock_and_suspend | command). The old
        # command/resume_command fields are read only when action = "command".
        action = "lock";
        enabled = true;
      };
      screen-off = {
        timeout = 360;
        # `screen_off` handles dpms-off plus resume-on-activity; no resume command.
        action = "screen_off";
      };
    };

    bar.main = {
      position = "top";
      thickness = 34;
      radius = 12;
      # v5 renamed the bar margins: margin_h -> margin_ends (inset from each end),
      # margin_v -> margin_edge (distance from the screen edge).
      margin_ends = 180;
      margin_edge = 10;
      padding = 14;
      widget_spacing = 6;
      scale = 1.2;
      shadow = true;
      reserve_space = true;
      background_opacity = 0.6;
      capsule = true;
      capsule_opacity = 0.8;

      start = [
        "control-center"
        "workspaces"
        "media"
      ];
      center = [
        "clock"
      ];
      end = [
        "tray"
        "notifications"
        "network"
        "bluetooth"
        "volume"
        "session"
      ];
    };
  };
in
{
  programs.noctalia-shell.enable = false;

  home.packages = [
    noctalia-v5.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.configFile."noctalia/config.toml".source = toml.generate "noctalia-config.toml" config;
}
