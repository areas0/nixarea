{ ... }:
{
  programs.noctalia-shell.settings.desktopWidgets = {
    enabled = true;
    overviewEnabled = true;

    monitorWidgets = [
      {
        name = "DP-2";
        widgets = [
          {
            id = "Clock";
            x = 80;
            y = 1100;
            scale = 1.5;
            showBackground = false;
          }
          {
            id = "Weather";
            x = 80;
            y = 1260;
            scale = 1.0;
            showBackground = true;
            roundedCorners = true;
          }
          {
            id = "SystemStat";
            x = 500;
            y = 1100;
            scale = 1.0;
            statType = "CPU";
            layout = "bottom";
            showBackground = true;
            roundedCorners = true;
          }
          {
            id = "MediaPlayer";
            x = 500;
            y = 1260;
            scale = 1.0;
            showBackground = true;
            roundedCorners = true;
            hideMode = "visible";
          }
        ];
      }
      {
        name = "eDP-1";
        widgets = [
          {
            id = "Clock";
            x = 60;
            y = 900;
            scale = 1.2;
            showBackground = false;
          }
        ];
      }
    ];
  };
}
