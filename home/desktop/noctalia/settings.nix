{ lib, ... }:
{
  programs.noctalia-shell.settings = {
    general = {
      enableBlurBehind = true;
      lockScreenBlur = 0.6;
      lockScreenTint = 0.3;
      lockOnSuspend = true;
    };

    ui = {
      translucentWidgets = true;
      panelBackgroundOpacity = lib.mkForce 0.7;
    };

    wallpaper = {
      enabled = true;
      setWallpaperOnAllMonitors = true;
    };

    appLauncher = {
      enableClipboardHistory = true;
      enableWindowsSearch = true;
      enableSessionSearch = true;
      enableSettingsSearch = true;
      sortByMostUsed = true;
      terminalCommand = "kitty -e";
      viewMode = "list";
    };

    notifications = {
      enabled = true;
      location = "top_right";
      backgroundOpacity = lib.mkForce 0.8;
    };

    osd = {
      enabled = true;
      location = "top_right";
      backgroundOpacity = lib.mkForce 0.8;
    };

    location = {
      name = "Paris";
      useFahrenheit = false;
      use12hourFormat = false;
    };

    colorSchemes.useWallpaperColors = false;
    nightLight.enabled = false;

    idle = {
      enabled = true;
      lockTimeout = 180;
      screenOffTimeout = 360;
      suspendTimeout = 0;
      resumeScreenOffCommand = "hyprctl dispatch dpms on";
    };
  };
}
