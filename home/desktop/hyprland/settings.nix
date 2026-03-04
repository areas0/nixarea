{ pkgs-unstable, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland;
    plugins = [ pkgs-unstable.hyprlandPlugins.hy3 ];
    xwayland.enable = true;
    systemd.enable = true;
    systemd.variables = [ "--all" ];
    systemd.enableXdgAutostart = true;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$fileManager" = "thunar";
      "$menu" = "walker";
      exec-once = [
        "code"
        "hyprpanel"
        "wl-paste --watch cliphist store"
        "sleep 2 && pkill -x swww-daemon; sleep 0.5; systemctl --user restart hyprpaper.service"
      ];
      env = [
        "NIXOS_OZONE_WL,1"
        "MOZ_ENABLE_WAYLAND,1"
        "MOZ_WEBRENDER,1"
        "_JAVA_AWT_WM_NONREPARENTING,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QPA_PLATFORM,wayland"
        "SDL_VIDEODRIVER,wayland"
        "GDK_BACKEND,wayland"
      ];

      general.layout = "hy3";

      plugin.hy3 = {
        no_gaps_when_only = 2;
        node_collapse_policy = 2;
        group_inset = 10;

        tabs = {
          height = 22;
          padding = 6;
          from_top = false;
          radius = 6;
          border_width = 2;
          render_text = true;
          text_center = true;
          text_font = "Sans";
          text_height = 8;
          text_padding = 3;
          "col.active" = "rgba(88c0d0cc)";
          "col.active.border" = "rgba(88c0d0ee)";
          "col.active.text" = "rgba(eceff4ff)";
          "col.focused" = "rgba(434c5ecc)";
          "col.focused.border" = "rgba(4c566aee)";
          "col.focused.text" = "rgba(eceff4ff)";
          "col.inactive" = "rgba(2e344080)";
          "col.inactive.border" = "rgba(3b4252aa)";
          "col.inactive.text" = "rgba(d8dee9ff)";
          "col.urgent" = "rgba(bf616a40)";
          "col.urgent.border" = "rgba(bf616aee)";
          "col.urgent.text" = "rgba(eceff4ff)";
          blur = true;
          opacity = 1.0;
        };

        autotile = {
          enable = true;
          ephemeral_groups = true;
          trigger_width = 0;
          trigger_height = 0;
        };
      };
    };
  };
}
