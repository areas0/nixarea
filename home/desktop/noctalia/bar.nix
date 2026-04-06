{
  lib,
  additionalConfig,
  ...
}:
let
  isLaptop = additionalConfig.isLaptop or false;
in
{
  programs.noctalia-shell.settings.bar = {
    position = "top";
    density = "spacious";
    fontScale = 1.2;
    floating = true;
    backgroundOpacity = lib.mkForce 0.6;
    capsuleOpacity = lib.mkForce 0.8;
    showCapsule = true;

    widgets = {
      left = [
        {
          id = "ControlCenter";
          useDistroLogo = true;
        }
        {
          id = "Workspace";
          hideUnoccupied = false;
          labelMode = "number";
        }
        { id = "SystemMonitor"; }
        { id = "plugin:network-indicator"; }
        { id = "AudioVisualizer"; }
        { id = "ActiveWindow"; }
      ];
      center = [
        { id = "MediaMini"; }
      ];
      right = [
        { id = "Volume"; }
      ]
      ++ lib.optionals isLaptop [
        { id = "Brightness"; }
        { id = "Battery"; }
      ]
      ++ [
        { id = "VPN"; }
        { id = "Network"; }
        { id = "Bluetooth"; }
        { id = "plugin:privacy-indicator"; }
        { id = "plugin:openhue"; }
        { id = "Tray"; }
        { id = "NotificationHistory"; }
        {
          id = "Clock";
          formatHorizontal = "HH:mm";
          formatVertical = "HH mm";
          useMonospacedFont = true;
        }
      ];
    };
  };
}
