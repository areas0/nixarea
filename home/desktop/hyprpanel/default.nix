{ ... }:
{
  programs.hyprpanel = {
    enable = true;
    # Configure and theme almost all options from the GUI.
    # See 'https://hyprpanel.com/configuration/settings.html'.
    # Default: <same as gui>
    settings = {

      # Configure bar layouts for monitors.
      # See 'https://hyprpanel.com/configuration/panel.html'.
      # Default: null
      layout = {
        bar.layouts = {
          "0" = {
            left = [
              "dashboard"
              "workspaces"
            ];
            middle = [ "media" ];
            right = [
              "volume"
              "systray"
              "notifications"
            ];
          };
        };
      };

      bar.launcher.autoDetectIcon = true;
      bar.workspaces.show_icons = false;
      bar.workspaces.show_numbered = true;
      menus.clock = {
        time = {
          military = true;
          hideSeconds = true;
        };
        weather.unit = "metric";
      };

      menus.dashboard.directories.enabled = false;
      menus.dashboard.stats.enable_gpu = true;

      theme.bar.transparent = true;

      theme.font = {
        name = "CaskaydiaCove NF";
        size = "16px";
      };

      theme.bar.menus = {
        background = "#000000";
        text = "#CCCCCC";
        border.color = "#333333";
        tooltip = {
          text = "#FFFFFF";
          background = "#000000";
        };
        dropdownmenu = {
          divider = "#111111";
          text = "#FFFFFF";
          background = "#000000";
        };
        slider = {
          puck = "#CCCCCC";
          backgroundhover = "#444444";
          background = "#CCCCCC";
          primary = "#FFFFFF";
        };
        progressbar = {
          background = "#444444";
          foreground = "#FFFFFF";
        };
        iconbuttons = {
          active = "#FFFFFF";
          passive = "#FFFFFF";
        };
        buttons = {
          text = "#000000";
          disabled = "#CCCCCC";
          active = "#FFFFFF";
          default = "#FFFFFF";
        };
        switch = {
          puck = "#CCCCCC";
          disabled = "#444444";
          enabled = "#FFFFFF";
        };
        icons = {
          active = "#FFFFFF";
          passive = "#CCCCCC";
        };
        listitems = {
          active = "#ffffff";
          passive = "#FFFFFF";
        };
        label = "#FFFFFF";
        feinttext = "#444444";
        dimtext = "#CCCCCC";
        cards = "#111111";
        popover = {
          text = "#FFFFFF";
          background = "#000000";
          border = "#000000";
        };
        check_radio_button = {
          background = "#000000";
          active = "#ffffff";
        };
      };
      theme.bar.background = "#000000";
      theme.bar.buttons = {
        media = {
          icon = "#090909";
          text = "#FFFFFF";
          background = "#090909";
          icon_background = "#ffffff";
          border = "#FFFFFF";
        };
        icon = "#242438";
        text = "#FFFFFF";
        hover = "#333333";
        background = "#1A1A1A";
        notifications = {
          total = "#FFFFFF";
          icon = "#090909";
          background = "#090909";
          icon_background = "#ffffff";
          border = "#FFFFFF";
        };
        clock = {
          icon = "#000000";
          text = "#FFFFFF";
          background = "#090909";
          icon_background = "#ffffff";
          border = "#FFFFFF";
        };
        battery = {
          icon = "#090909";
          text = "#FFFFFF";
          background = "#090909";
          icon_background = "#ffffff";
          border = "#FFFFFF";
        };
        systray = {
          background = "#090909";
          border = "#444444";
          customIcon = "#FFFFFF";
        };
        bluetooth = {
          icon = "#090909";
          text = "#FFFFFF";
          background = "#090909";
          icon_background = "#ffffff";
          border = "#FFFFFF";
        };
        network = {
          icon = "#090909";
          text = "#FFFFFF";
          background = "#090909";
          icon_background = "#ffffff";
          border = "#FFFFFF";
        };
        volume = {
          icon = "#090909";
          text = "#FFFFFF";
          background = "#090909";
          icon_background = "#ffffff";
          border = "#FFFFFF";
        };
        windowtitle = {
          icon = "#090909";
          text = "#FFFFFF";
          background = "#090909";
          icon_background = "#ffffff";
          border = "#FFFFFF";
        };
        workspaces = {
          active = "#FFFFFF";
          occupied = "#FFFFFF";
          available = "#FFFFFF";
          hover = "#444444";
          background = "#090909";
          numbered_active_highlighted_text_color = "#21252b";
          numbered_active_underline_color = "#ffffff";
          border = "#FFFFFF";
        };
        dashboard = {
          icon = "#000000";
          background = "#ffffff";
          border = "#FFFFFF";
        };
        style = "split";
        icon_background = "#FFFFFF";
        borderColor = "#FFFFFF";
        modules = {
          ram = {
            icon = "#21252b";
            icon_background = "#ffffff";
            text = "#ffffff";
            background = "#090909";
            border = "#ffffff";
          };
          storage = {
            icon_background = "#ffffff";
            icon = "#21252b";
            text = "#ffffff";
            background = "#090909";
            border = "#ffffff";
          };
          updates = {
            icon_background = "#FFFFFF";
            text = "#FFFFFF";
            icon = "#21252b";
            background = "#090909";
            border = "#FFFFFF";
          };
          netstat = {
            background = "#090909";
            text = "#ffffff";
            icon = "#21252b";
            icon_background = "#ffffff";
            border = "#ffffff";
          };
          weather = {
            icon = "#090909";
            text = "#FFFFFF";
            icon_background = "#FFFFFF";
            background = "#090909";
            border = "#FFFFFF";
          };
          power = {
            icon = "#21252b";
            icon_background = "#ffffff";
            background = "#090909";
            border = "#ffffff";
          };
          cpu = {
            icon = "#21252b";
            icon_background = "#ffffff";
            text = "#ffffff";
            background = "#090909";
            border = "#ffffff";
          };
          kbLayout = {
            icon_background = "#ffffff";
            icon = "#21252b";
            background = "#090909";
            text = "#ffffff";
            border = "#ffffff";
          };
          submap = {
            background = "#090909";
            text = "#FFFFFF";
            border = "#FFFFFF";
            icon = "#21252b";
            icon_background = "#FFFFFF";
          };
          hyprsunset = {
            icon_background = "#ffffff";
            background = "#090909";
            icon = "#21252b";
            text = "#ffffff";
            border = "#ffffff";
          };
          hypridle = {
            icon = "#21252b";
            background = "#090909";
            icon_background = "#ffffff";
            text = "#ffffff";
            border = "#ffffff";
          };
          cava = {
            text = "#FFFFFF";
            background = "#090909";
            icon = "#21252b";
            icon_background = "#FFFFFF";
            border = "#FFFFFF";
          };
          microphone = {
            border = "#ffffff";
            background = "#090909";
            text = "#ffffff";
            icon = "#090909";
            icon_background = "#ffffff";
          };
          worldclock = {
            text = "#FFFFFF";
            background = "#090909";
            icon = "#000000";
            icon_background = "#ffffff";
            border = "#FFFFFF";
          };
        };
      };
      theme.bar.border.color = "#FFFFFF";
      theme.osd = {
        label = "#FFFFFF";
        icon = "#000000";
        bar_overflow_color = "#FFFFFF";
        bar_empty_color = "#444444";
        bar_color = "#FFFFFF";
        icon_container = "#FFFFFF";
        bar_container = "#000000";
      };
      theme.notification = {
        close_button = {
          label = "#000000";
          background = "#FFFFFF";
        };
        labelicon = "#FFFFFF";
        text = "#FFFFFF";
        time = "#CCCCCC";
        border = "#444444";
        label = "#FFFFFF";
        actions = {
          text = "#000000";
          background = "#FFFFFF";
        };
        background = "#1a1a1a";
      };
    };
  };
}
