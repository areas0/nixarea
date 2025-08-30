{ hyprshell, ... } : {
  imports = [
    hyprshell.homeModules.hyprshell
  ];
  programs.hyprshell = {
    enable = true;

    # Optional: override systemd service behavior
    systemd = {
      enable = true;
      # If you use Wayland + HM's wayland.systemd, you can omit this and keep the default.
      # Otherwise, explicitly target a session target that's present on your system:
      target = "graphical-session.target";
      args = "-vv";
    };

    # Optional: inline CSS overrides (or provide a path instead)
    styleFile = ''
      /* Hyprshell CSS overrides */
      :root {
        --hs-bg: rgba(24, 24, 27, 0.92);
        --hs-fg: #e5e7eb;
        --hs-accent: #84cc16;
      }
      .window {
        border-radius: 10px;
      }
    '';

    # If you set configFile, it must be JSON (string or path).
    # Leaving it unset lets the module generate config.json from `settings`.
    # configFile = ''
    #   { "version": 1 }
    # '';

    settings = {
      version = 1;
      layerrules = true;
      kill_bind = "ctrl+shift+alt, h";

      windows = {
        enable = true;
        scale = 8.5;            # 0..15
        items_per_row = 6;

        overview = {
          enable = true;
          strip_html_from_workspace_title = true;
          key = "super_l";
          modifier = "super";

          # Choose any of: "same_class" "current_monitor" "current_workspace"
          filter_by = [ "current_monitor" ];
          hide_filtered = false;

          launcher = {
            enable = true;
            width = 700;
            launch_modifier = "ctrl";
            max_items = 8;
            animate_launch_ms = 250;
            default_terminal = "kitty";   # or "alacritty", "kitty", etc.
            show_when_empty = true;

            plugins = {
              applications = {
                enable = true;
                run_cache_weeks = 6;
                show_execs = true;
                show_actions_submenu = true;
              };
              calc = { enable = true; };
              shell = { enable = true; };
              terminal = { enable = true; };
              websearch = {
                enable = false;
              };
            };
          };
        };

        switch = {
          enable = true;
          modifier = "alt";
          # Choose any of: "same_class" "current_monitor" "current_workspace"
          filter_by = [ "current_monitor" ];
          show_workspaces = true;
        };
      };
    };
  };
}
