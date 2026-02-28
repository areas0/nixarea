{ ... }:
let
  colors = {
    bg = "#000000";
    bg_alt = "#090909";
    bg_surface = "#111111";
    bg_raised = "#1A1A1A";
    icon_fg = "#21252b";
    hover = "#333333";
    muted = "#444444";
    dimmed = "#CCCCCC";
    fg = "#FFFFFF";
  };
in
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
        background = colors.bg;
        text = colors.dimmed;
        border.color = colors.hover;
        tooltip = {
          text = colors.fg;
          background = colors.bg;
        };
        dropdownmenu = {
          divider = colors.bg_surface;
          text = colors.fg;
          background = colors.bg;
        };
        slider = {
          puck = colors.dimmed;
          backgroundhover = colors.muted;
          background = colors.dimmed;
          primary = colors.fg;
        };
        progressbar = {
          background = colors.muted;
          foreground = colors.fg;
        };
        iconbuttons = {
          active = colors.fg;
          passive = colors.fg;
        };
        buttons = {
          text = colors.bg;
          disabled = colors.dimmed;
          active = colors.fg;
          default = colors.fg;
        };
        switch = {
          puck = colors.dimmed;
          disabled = colors.muted;
          enabled = colors.fg;
        };
        icons = {
          active = colors.fg;
          passive = colors.dimmed;
        };
        listitems = {
          active = colors.fg;
          passive = colors.fg;
        };
        label = colors.fg;
        feinttext = colors.muted;
        dimtext = colors.dimmed;
        cards = colors.bg_surface;
        popover = {
          text = colors.fg;
          background = colors.bg;
          border = colors.bg;
        };
        check_radio_button = {
          background = colors.bg;
          active = colors.fg;
        };
      };
      theme.bar.background = colors.bg;
      theme.bar.buttons = {
        media = {
          icon = colors.bg_alt;
          text = colors.fg;
          background = colors.bg_alt;
          icon_background = colors.fg;
          border = colors.fg;
        };
        icon = colors.icon_fg;
        text = colors.fg;
        hover = colors.hover;
        background = colors.bg_raised;
        notifications = {
          total = colors.fg;
          icon = colors.bg_alt;
          background = colors.bg_alt;
          icon_background = colors.fg;
          border = colors.fg;
        };
        clock = {
          icon = colors.bg;
          text = colors.fg;
          background = colors.bg_alt;
          icon_background = colors.fg;
          border = colors.fg;
        };
        battery = {
          icon = colors.bg_alt;
          text = colors.fg;
          background = colors.bg_alt;
          icon_background = colors.fg;
          border = colors.fg;
        };
        systray = {
          background = colors.bg_alt;
          border = colors.muted;
          customIcon = colors.fg;
        };
        bluetooth = {
          icon = colors.bg_alt;
          text = colors.fg;
          background = colors.bg_alt;
          icon_background = colors.fg;
          border = colors.fg;
        };
        network = {
          icon = colors.bg_alt;
          text = colors.fg;
          background = colors.bg_alt;
          icon_background = colors.fg;
          border = colors.fg;
        };
        volume = {
          icon = colors.bg_alt;
          text = colors.fg;
          background = colors.bg_alt;
          icon_background = colors.fg;
          border = colors.fg;
        };
        windowtitle = {
          icon = colors.bg_alt;
          text = colors.fg;
          background = colors.bg_alt;
          icon_background = colors.fg;
          border = colors.fg;
        };
        workspaces = {
          active = colors.fg;
          occupied = colors.fg;
          available = colors.fg;
          hover = colors.muted;
          background = colors.bg_alt;
          numbered_active_highlighted_text_color = colors.icon_fg;
          numbered_active_underline_color = colors.fg;
          border = colors.fg;
        };
        dashboard = {
          icon = colors.bg;
          background = colors.fg;
          border = colors.fg;
        };
        style = "split";
        icon_background = colors.fg;
        borderColor = colors.fg;
        modules = {
          ram = {
            icon = colors.icon_fg;
            icon_background = colors.fg;
            text = colors.fg;
            background = colors.bg_alt;
            border = colors.fg;
          };
          storage = {
            icon_background = colors.fg;
            icon = colors.icon_fg;
            text = colors.fg;
            background = colors.bg_alt;
            border = colors.fg;
          };
          updates = {
            icon_background = colors.fg;
            text = colors.fg;
            icon = colors.icon_fg;
            background = colors.bg_alt;
            border = colors.fg;
          };
          netstat = {
            background = colors.bg_alt;
            text = colors.fg;
            icon = colors.icon_fg;
            icon_background = colors.fg;
            border = colors.fg;
          };
          weather = {
            icon = colors.bg_alt;
            text = colors.fg;
            icon_background = colors.fg;
            background = colors.bg_alt;
            border = colors.fg;
          };
          power = {
            icon = colors.icon_fg;
            icon_background = colors.fg;
            background = colors.bg_alt;
            border = colors.fg;
          };
          cpu = {
            icon = colors.icon_fg;
            icon_background = colors.fg;
            text = colors.fg;
            background = colors.bg_alt;
            border = colors.fg;
          };
          kbLayout = {
            icon_background = colors.fg;
            icon = colors.icon_fg;
            background = colors.bg_alt;
            text = colors.fg;
            border = colors.fg;
          };
          submap = {
            background = colors.bg_alt;
            text = colors.fg;
            border = colors.fg;
            icon = colors.icon_fg;
            icon_background = colors.fg;
          };
          hyprsunset = {
            icon_background = colors.fg;
            background = colors.bg_alt;
            icon = colors.icon_fg;
            text = colors.fg;
            border = colors.fg;
          };
          hypridle = {
            icon = colors.icon_fg;
            background = colors.bg_alt;
            icon_background = colors.fg;
            text = colors.fg;
            border = colors.fg;
          };
          cava = {
            text = colors.fg;
            background = colors.bg_alt;
            icon = colors.icon_fg;
            icon_background = colors.fg;
            border = colors.fg;
          };
          microphone = {
            border = colors.fg;
            background = colors.bg_alt;
            text = colors.fg;
            icon = colors.bg_alt;
            icon_background = colors.fg;
          };
          worldclock = {
            text = colors.fg;
            background = colors.bg_alt;
            icon = colors.bg;
            icon_background = colors.fg;
            border = colors.fg;
          };
        };
      };
      theme.bar.border.color = colors.fg;
      theme.osd = {
        label = colors.fg;
        icon = colors.bg;
        bar_overflow_color = colors.fg;
        bar_empty_color = colors.muted;
        bar_color = colors.fg;
        icon_container = colors.fg;
        bar_container = colors.bg;
      };
      theme.notification = {
        close_button = {
          label = colors.bg;
          background = colors.fg;
        };
        labelicon = colors.fg;
        text = colors.fg;
        time = colors.dimmed;
        border = colors.muted;
        label = colors.fg;
        actions = {
          text = colors.bg;
          background = colors.fg;
        };
        background = colors.bg_raised;
      };
    };
  };
}
